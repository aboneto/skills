# Summary & Decision — Custom Log Parser Approach

## Consultation Details
- **Date:** 2026-05-22
- **Model:** Claude Opus (via `claude -p --model opus`)
- **Topic:** Parser for custom log format with irregular timestamps, indented blocks, and broken lines

## What Claude Recommended

### Architecture: Lexer + State Machine (3 phases)

1. **Phase 1 — Line Classifier (Lexer):** Each line classified into a token type (`entry-start`, `indented`, `continuation`, `blank`). Small regex per type, not one mega-regex. `tryParseTimestamp` tries N known formats in order.

2. **Phase 2 — State Machine (Parser):** Accumulator `current: Entry | null`. Rules:
   - `entry-start` → flush current, open new
   - `indented` → append to `current.children`
   - `continuation` → append to `current.message`
   - `blank` → conditional flush

3. **Phase 3 — Tree Builder (optional):** Convert flat children to tree using depth as nesting signal (like YAML/Markdown parsers).

### Key Design Decisions
- **Continuation heuristic:** no-indent + no-parseable-timestamp = continuation. Start simple, measure false positives before adding scoring.
- **Output structure:** `LogEntry` with `timestamp`, `level`, `message`, `context[]`, `raw`, `lineRange` — includes raw text for debugging.
- **Testing strategy:** Golden files (input → expected JSON), snapshot per fixture, each new bug = new fixture.

### Alternatives Evaluated
| Approach | Verdict |
|----------|---------|
| Lexer + SM | **Recommended** — testable, maintainable, debuggable |
| Mega-regex | Rejected — unmaintainable, edge cases kill you |
| PEG (peggy/nearley) | Rejected — irregular timestamps break formal grammar |
| Streaming with callbacks | Deferred — only needed for files >100MB |

### Libraries Mentioned
- **Chevrotain** — parser toolkit (overkill but viable if grammar grows)
- **nearley/peggy** — PEG parsers (problematic with multi-format timestamps)
- Reference patterns: Python `logging` multiline, Logstash multiline codec, Vector `parse_logfmt`

## Decision

**Adopt the Lexer + State Machine approach.** It directly addresses the core concerns:
- No regex spaghetti (small, isolated regexes per line type)
- Indentation handled naturally as a token type with depth
- Continuation detection via absence of timestamp + absence of indent
- Each phase independently testable

**Implementation plan:**
1. Start synchronous on array of lines (no premature streaming optimization)
2. Build `classify()` with isolated unit tests first
3. Build state machine with integration tests using golden fixtures
4. Add tree builder only if nested context is actually needed
5. Migrate to Node `readline` stream only if files exceed ~100MB