# Approach: Custom Log Parser Without Regex Spaghetti

## Problem Analysis

The log format has three main challenges:
1. **Irregular timestamps** — no fixed format, possibly missing or malformed
2. **Indented blocks** — hierarchical/nested structure indicated by whitespace
3. **Broken lines** — log entries can be truncated mid-way, requiring recovery

## Core Strategy: State Machine + Parser Combinators

**No regex spaghetti.** Instead, use a **line-oriented streaming parser** with explicit state tracking.

### Why This Works

- Each line is classified by its **shape** (indentation level, presence of timestamp, etc.)
- State transitions are explicit and testable in isolation
- Broken lines are handled by a **recovery state**, not by complex regex backtracking
- Parser combinators compose small parsers into larger ones without nested conditionals

## Architecture

```
Raw Lines → Line Classifier → State Machine → Parsed Records
                                    ↓
                              Recovery Handler (for broken lines)
```

### Phase 1: Line Classifier

Every line gets tagged with a **line type** before any parsing logic:

```
LineType enum:
  - TIMESTAMP_START    (begins with something that looks like a timestamp)
  - INDENTED_CHILD     (starts with whitespace, belongs to parent)
  - CONTINUATION       (no timestamp, no indent — continuation of previous)
  - BROKEN_TRUNCATED   (detectable mid-break: missing closing delimiter, etc.)
  - BLANK_SEPARATOR    (empty line, potential record boundary)
  - UNKNOWN            (fallback, logged for investigation)
```

Classification rules are simple predicates, not regex:
- `line[0].is_whitespace()` → INDENTED_CHILD
- `looks_like_timestamp(line)` → TIMESTAMP_START (use a lenient heuristic, not a strict pattern)
- `line.is_empty()` → BLANK_SEPARATOR

### Phase 2: State Machine

The parser maintains a **current record** and transitions between states:

```
States:
  - IDLE           (waiting for next record)
  - IN_RECORD      (accumulating lines into current record)
  - IN_BLOCK       (inside an indented child block)
  - RECOVERING     (detected broken line, looking for resync point)

Transitions:
  IDLE + TIMESTAMP_START    → IN_RECORD (start new record)
  IN_RECORD + INDENTED_CHILD → IN_BLOCK (enter child block)
  IN_BLOCK + INDENTED_CHILD  → IN_BLOCK (stay in block)
  IN_BLOCK + TIMESTAMP_START → IDLE (close block, emit record, start new)
  ANY + BROKEN_TRUNCATED     → RECOVERING
  RECOVERING + TIMESTAMP_START → IDLE (resync found, emit partial)
```

### Phase 3: Recovery Strategy for Broken Lines

When a line is detected as broken:

1. **Buffer what we have** — don't discard partial data
2. **Enter RECOVERING state** — accumulate subsequent lines
3. **Resync on next TIMESTAMP_START** — treat everything between break and next timestamp as part of the broken record
4. **Emit with a `broken: true` flag** — downstream consumers can decide what to do

## Implementation (JavaScript/Node.js)

```javascript
class LogParser {
  constructor() {
    this.state = 'IDLE';
    this.currentRecord = null;
    this.records = [];
  }

  classifyLine(line) {
    if (line.trim().length === 0) return 'BLANK';
    if (/^\s+/.test(line)) return 'INDENTED';
    if (this.isTimestampLike(line)) return 'TIMESTAMP';
    if (this.isBroken(line)) return 'BROKEN';
    return 'CONTINUATION';
  }

  isTimestampLike(line) {
    // Lenient heuristic: starts with digits, brackets, or common date chars
    const trimmed = line.trim();
    return /^\d/.test(trimmed) || 
           trimmed.startsWith('[') || 
           trimmed.startsWith('(');
  }

  isBroken(line) {
    // Heuristics: unclosed brackets, missing expected delimiters
    const opens = (line.match(/[\[\(]/g) || []).length;
    const closes = (line.match(/[\]\)]/g) || []).length;
    return opens > closes && line.length > 50; // likely truncated
  }

  parse(lines) {
    for (const line of lines) {
      const type = this.classifyLine(line);
      this.transition(type, line);
    }
    this.flush(); // emit any remaining record
    return this.records;
  }

  transition(type, line) {
    switch (this.state) {
      case 'IDLE':
        if (type === 'TIMESTAMP') {
          this.currentRecord = { timestamp: this.extractTimestamp(line), body: line, children: [], broken: false };
          this.state = 'IN_RECORD';
        }
        break;

      case 'IN_RECORD':
        if (type === 'INDENTED') {
          this.currentRecord.children.push({ content: line.trim(), children: [] });
          this.state = 'IN_BLOCK';
        } else if (type === 'TIMESTAMP') {
          this.flush();
          this.currentRecord = { timestamp: this.extractTimestamp(line), body: line, children: [], broken: false };
        } else {
          this.currentRecord.body += '\n' + line;
        }
        break;

      case 'IN_BLOCK':
        if (type === 'INDENTED') {
          // Add to last child or create nested
          this.appendToCurrentBlock(line);
        } else if (type === 'TIMESTAMP') {
          this.flush();
          this.currentRecord = { timestamp: this.extractTimestamp(line), body: line, children: [], broken: false };
          this.state = 'IN_RECORD';
        } else {
          this.state = 'IN_RECORD';
          this.currentRecord.body += '\n' + line;
        }
        break;

      case 'RECOVERING':
        if (type === 'TIMESTAMP') {
          this.currentRecord.broken = true;
          this.flush();
          this.currentRecord = { timestamp: this.extractTimestamp(line), body: line, children: [], broken: false };
          this.state = 'IN_RECORD';
        } else {
          this.currentRecord.body += '\n' + line; // accumulate broken content
        }
        break;
    }
  }

  flush() {
    if (this.currentRecord) {
      this.records.push(this.currentRecord);
      this.currentRecord = null;
    }
    this.state = 'IDLE';
  }
}
```

## Testing Strategy

**Test each piece in isolation:**

1. **Classifier tests** — feed individual lines, verify correct type
2. **State transition tests** — feed sequences of types, verify state changes
3. **Recovery tests** — inject broken lines, verify resync behavior
4. **Integration tests** — full log files, verify output structure

```javascript
// Example: classifier test
test('classifies indented line as INDENTED', () => {
  expect(parser.classifyLine('    at someFunction (file.js:42)')).toBe('INDENTED');
});

// Example: recovery test
test('resyncs after broken line on next timestamp', () => {
  const input = [
    '2024-01-01 INFO start',
    '  nested block here [unclosed',  // broken
    'more broken stuff...',
    '2024-01-01 INFO next entry',     // resync point
  ];
  const result = parser.parse(input);
  expect(result[0].broken).toBe(true);
  expect(result[1].broken).toBe(false);
});
```

## Why This Beats Regex Spaghetti

| Aspect | Regex Approach | State Machine Approach |
|--------|---------------|----------------------|
| Readability | Nested, hard to follow | Explicit states and transitions |
| Testability | Must test full pattern | Test each classifier/transition |
| Recovery | Regex backtracking, fragile | Dedicated RECOVERING state |
| Extensibility | Add more regex branches | Add new state or transition |
| Debugging | "Why didn't this match?" | Log state transitions |
| Performance | Backtracking on complex patterns | O(n) single pass |

## When to Use Parser Combinator Libraries

If the format grows more complex, consider:

- **JavaScript**: `parsimmon` or `nearley` — parser combinators that compose cleanly
- **Rust**: `nom` — zero-copy parser combinators, excellent for log parsing
- **Python**: `parsy` — composable parser functions

These let you write:
```
record = timestamp.then(content).many().map(buildRecord)
logFile = record.sepBy(blankLine).eof()
```

Instead of regex soup.

## Summary

1. **Classify first, parse second** — separate line shape detection from record assembly
2. **Explicit state machine** — IDLE → IN_RECORD → IN_BLOCK → RECOVERING
3. **Recovery by resync** — don't try to fix broken lines, detect and recover gracefully
4. **Test in layers** — classifier, transitions, recovery, integration
5. **Parser combinators if it grows** — compose small parsers instead of growing one big regex
