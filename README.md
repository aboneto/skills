# skills

List of skills developed by [aboneto](https://github.com/aboneto) for the community.

## Install a Skill

```bash
npx skills add aboneto/skills --skill <skill_name>
```

Example:

```bash
npx skills add aboneto/skills --skill consult-claude
```

## Available Skills

### consult-claude

The idea behind this skill is to use the `claude` CLI as an "expert colleague" you can consult when facing something complex. It's a thinking tool, not a delegation tool: your main LLM remains responsible for the solution, but you gain external perspective. Very useful when you're using Opencode and want to escalate to a more capable model for a difficult problem without changing the entire session or costing more tokens than necessary. It's a thinking tool, not delegation: you remain responsible for the solution, but you gain external perspective.

**Use when:**

- You've made 3 or more attempts without resolving a bug and suspect you're stuck in an incorrect mental model.
- You need to make a design decision where there are multiple defensible paths and the choice isn't obvious.
- You're about to implement a non-trivial algorithm (complex parsing, concurrency, non-standard data structures) and want to validate the approach before writing a lot of code.
- The user has asked you for something where a mistake has a high cost (data migration, security-related code, large refactor).
- You have a solution that "works" but you're not sure if it's the right one.

**When NOT to use** (important to avoid burning through the user's subscription):

- Simple tasks: file reads, trivial edits, questions with a clear answer.
- When you already have high confidence in your approach.
- For repetitive tasks where you've already validated the pattern earlier in the same session.

**Tests:** `tests/consult-claude-workspace`