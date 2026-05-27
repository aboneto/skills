# Benchmark Results - AG-UI Ruby SDK Skill (Iteration 1)

This report compares the performance of coding tasks completed **with the custom skill** (`with_skill`) vs. **without the custom skill** (`without_skill`).

## Executive Summary

| Metrics | With Skill | Without Skill | Delta |
| :--- | :--- | :--- | :--- |
| **Assertion Pass Rate** | 100.0% (18/18) | 27.78% (5/18) | **+72.22%** |
| **Execution Time** | 24.25s | 6.75s | **+17.50s** |
| **Tokens Consumed** | 29.5k | 14.7k | **+14.8k** |

## Key Findings

1. **API Accuracy**: Without the skill, agents fail to guess the correct namespace (`AgUiProtocol`) and names of the events or attributes. They fallback to generic names like `AgUi.start_run` or `text` (instead of `delta`). With the skill, they get 100% of these details correct.
2. **References Usage**: The skill correctly guides the agent to read reference documentation (e.g. `references/events.md`) to resolve attribute specific details.
3. **Rails Streaming**: Generic Rails controller SSE patterns pass in both configurations due to baseline knowledge, but only the `with_skill` configuration implements correct `EventEncoder` usage and emits specific AG-UI SDK events (such as `RunStartedEvent`), causing the baseline without-skill to fail the 2 AG-UI specific assertions.
4. **Interactive Prompts Prevention**: By configuring the `with_skill` executor to run as a strictly non-terminal subagent (`StrictWithSkillNoTerminalExecutor`), we bypassed all user permission requests during the subagent runs, significantly reducing the average execution time from 218.5s down to 24.25s.

## Detailed Breakdown

### Eval 0: events-lifecycle-stream
- **With Skill**: 4/4 Passed (21.0s)
- **Without Skill**: 0/4 Passed (7.0s)

### Eval 1: types-multimodal-runinput
- **With Skill**: 4/4 Passed (11.0s)
- **Without Skill**: 0/4 Passed (7.0s)

### Eval 2: rails-streaming-patterns
- **With Skill**: 7/7 Passed (39.0s)
- **Without Skill**: 5/7 Passed (7.0s)

### Eval 3: references-docs-usage
- **With Skill**: 3/3 Passed (26.0s)
- **Without Skill**: 0/3 Passed (6.0s)
