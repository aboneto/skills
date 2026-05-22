---
name: consult-claude
description: Consult Claude via the `claude -p` CLI as a "second opinion" when you hit a tough technical problem — a tangled bug you've been stuck on for a while, a non-obvious architecture decision, a complex algorithm, or any moment where you doubt your own approach. Use it proactively as soon as you notice you're going in circles, making repeated attempts without progress, or making an important decision with low certainty. Don't wait for the user to ask — if the situation warrants it, consult. Better to ask for a second opinion than deliver a mediocre solution. Use this skill when the user says things like "second opinion", "don't know which path to take", "this isn't working", "been at this for hours", "help with tough decision", "am I approaching this right?", or when you notice you're stuck, doubting, or facing a design choice with multiple valid options.
license: MIT
metadata:
  author: aboneto
  version: "1.0.0"
---

# consult-claude

The idea behind this skill is to use the `claude` CLI as an "expert colleague" you can consult when facing something complex. It's a thinking tool, not a delegation tool: your main LLM remains responsible for the solution, but you gain external perspective. Very useful when you're using Opencode and want to escalate to a more capable model for a difficult problem without changing the entire session or costing more tokens than necessary. It's a thinking tool, not delegation: you remain responsible for the solution, but you gain external perspective.

## When to use

Consider consulting when **any** of these apply:

- You've made 3 or more attempts without resolving a bug and suspect you're stuck in an incorrect mental model.
- You need to make a design decision where there are multiple defensible paths and the choice isn't obvious.
- You're about to implement a non-trivial algorithm (complex parsing, concurrency, non-standard data structures) and want to validate the approach before writing a lot of code.
- The user has asked you for something where a mistake has a high cost (data migration, security-related code, large refactor).
- You have a solution that "works" but you're not sure if it's the right one.

**When NOT to consult** (important to avoid burning through the user's subscription):

- Simple tasks: file reads, trivial edits, questions with a clear answer.
- When you already have high confidence in your approach.
- For repetitive tasks where you've already validated the pattern earlier in the same session.

## Instructions

## Prompt structure

A good consultation has three parts:

1. **Minimum necessary context**: what you're building, in what language/stack, what the relevant constraint is.
2. **The specific problem**: not "help me with this", but "I'm trying to X, tried Y, it fails with Z".
3. **What type of response you need**: "am I approaching this right?", "give me 2-3 alternatives with tradeoffs", "review this code for X".

### Running the consultation

**Always use `--model opus`.** The point of this skill is to scale up to more capability when you need it, so even if the main session is Sonnet (or any other model), the consultation should go to Opus. Don't omit the flag.

Base command:

```bash
claude -p "your question here" --model opus
```

To pass code or files as context, use stdin instead of embedding them in the prompt (cleaner and allows large files):

```bash
cat src/parser.ts | claude -p "This parser fails with nested inputs of more than 3 levels. Do you see the bug? How would you approach it?" --model opus
```

To compare approaches or validate design, add `--output-format json` only if you're going to parse the response programmatically. For normal use, leave the output as text.

### Concrete example

Imagine you've been spending 20 minutes trying to fix a concurrency bug in Go. Instead of blindly keep trying:

```bash
cat worker.go | claude -p "This worker pool has an intermittent race condition — tests fail ~1 in 10 runs in CI but never locally. I've tried: adding mutex on updateState (no change), increasing channel buffer (no change), running with -race (detects nothing locally). What known race patterns could cause this symptom profile? What would you inspect first?" --model opus
```

You receive a response. Read it critically — don't assume it's correct — and use it as input for your next step.

## After consulting

1. **Read the response critically.** Claude can be wrong, especially if it lacked context. Don't copy-paste solutions without understanding them.
2. **Briefly summarize to the user** that you consulted and what you got out of it: "Consulted to validate the refactor approach — confirmed X and suggested considering Y, which I'll incorporate."
3. **You decide.** The consultation is input, not verdict. If the response doesn't fit what you know about the project, say why and follow your judgment.
4. **If the response is very long**, extract only the actionable parts and summarize them. Don't paste the full response in the chat — the user already has their own session and what they need is your synthesis, not a copy-paste.

## Important constraints

- **Always `--model opus`.** Don't use the default flag or Sonnet. If you're scaling up, scale to maximum capacity.
- **Each consultation is a new session.** It has no memory of your previous work. That's why context in the prompt matters.
- **Counts against the user's subscription.** Don't abuse it: one well-framed consultation is worth more than five poorly done ones.
- **Don't automate blindly.** This skill is for targeted escalation, not for having every step go through a consultation.
- **If the `claude` CLI is unavailable** or fails, it's not blocking: keep working with your own capabilities and mention it to the user.
