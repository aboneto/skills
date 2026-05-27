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

### jekyll

A compact reference for working productively with Jekyll. Covers Liquid templates, kramdown Markdown, `_config.yml`, collections, themes, plugins, GitHub Pages/Actions deployment, and custom plugins/filters.

**Use when:**

- Setting up a new Jekyll site or migrating an existing one.
- Working with Liquid templates, kramdown Markdown, or YAML front matter.
- Configuring `_config.yml`, collections, data files, or permalinks.
- Installing or troubleshooting plugins and themes.
- Deploying to GitHub Pages, GitHub Actions, or Netlify.
- Debugging build errors, future-dated posts, or Liquid syntax errors.
- Adding responsive images, comments, or custom plugins/filters.

**Tests:** `evals/jekyll-workspace`

**Benchmark results (4 iterations):**

| Iteration | Model | With Skill | Without Skill | Delta |
|---|---|---|---|---|
| [1](evals/jekyll-workspace/iteration-1) | Claude Opus 4.7 | 100% | 80.4% | +19.6% |
| [2](evals/jekyll-workspace/iteration-2) | DeepSeek V4 Flash Free | 100% | 80.4% | +19.6% |
| [3](evals/jekyll-workspace/iteration-3) | Gemini 2.5 Flash Lite | 77.8% | 46.5% | +31.3% |
| [4](evals/jekyll-workspace/iteration-4) | MiMo v2.5 Pro | 100% | 69.5% | +30.5% |

The skill consistently improves output quality across all tested models and evaluations (4 evals covering GitHub Pages deployment, Liquid/kramdown features, docs site scaffolding, and responsive images).

### ag-ui-ruby-sdk

Complete agent skill for the AG-UI Ruby SDK ([ag-ui-protocol](https://rubygems.org/gems/ag-ui-protocol) gem). Use when working with Ruby/Rails applications that implement the Agent-User Interaction Protocol — streaming text responses, tool calls, lifecycle events, state management, `ActionController::Live`, `with_stream` pattern, `EventEncoder`, `RunAgentInput`, or any event type from the SDK.

**Use when:**

- Working with Ruby applications using `ag-ui-protocol`.
- Implementing Rails applications with AG-UI streaming endpoints.
- Setting up event streaming, lifecycle management, or serialization for agent-user communication in Ruby.

**Tests:** `evals/ag-ui-ruby-sdk-workspace`

**Benchmark results (6 iterations):**

| Iteration | Model | With Skill | Without Skill | Delta |
|---|---|---|---|---|
| [1](evals/ag-ui-ruby-sdk-workspace/iteration-1) | Gemini 3.5 Flash | 100% | 27.78% | +72.22% |
| [2](evals/ag-ui-ruby-sdk-workspace/iteration-2) | DeepSeek V4 Flash Free | 92% | 11% | +81% |
| [3](evals/ag-ui-ruby-sdk-workspace/iteration-3) | MiniMax M2.7 | 96.4% | 32.1% | +64.3% |
| [4](evals/ag-ui-ruby-sdk-workspace/iteration-4) | MiniMax M2.7 | 100% | 17% | +83% |
| [5](evals/ag-ui-ruby-sdk-workspace/iteration-5) | Kimi K2.6 | 100% | 58% | +42% |
| [6](evals/ag-ui-ruby-sdk-workspace/iteration-6) | DeepSeek V4 Flash Free | 100% | 15% | +85% |

The skill guarantees correct type usage, event sequences, and reference document consultation, whereas runs without the skill fail to use the correct `AgUiProtocol` namespace and guess SDK methods/attributes incorrectly.

#### Updates

- **Iteration 4 fix:** Iteration 3 had incorrect `ActionController::Live` include and undefined `stream` variable issue. Iteration 4 skill now correctly instructs to include `ActionController::Live` and use `response.stream` properly, achieving 100% pass rate.
- **Iteration 6:** Expanded skill with reference docs (`0.2.0` gem version) and patterns for reasoning events, interrupt/resume types (HITL), agent capabilities declaration, and multimodal content types. Added 5 new evals (reasoning-events-stream, reasoning-message-type, interrupt-resume-types, agent-capabilities-declaration, multimodal-content-types) for a total of 9 evals. Subagents ran in strict isolation: `without_skill` prompts contained zero SDK class names or module paths, and `with_skill` subagents read the skill files themselves to discover the correct API. `with_skill` scored 100% across all 9 evals (45/45 assertions).
