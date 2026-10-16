---
name: dhaa
description: "Run the DHAA/MoAI engineering workflow from Codex CLI with a no-subagent adapter and progressive context loading."
---

# DHAA Codex Dispatcher

Use this skill when the user asks to plan, implement, review, fix, test, synchronize, or otherwise run the DHAA/MoAI workflow from Codex CLI.

## Input

Treat the text after `$dhaa` as the request.

## Routing

If the first token is an explicit subcommand, route directly:

| Subcommand | Workflow file |
|---|---|
| `plan`, `spec` | `.claude/skills/moai/workflows/plan.md` |
| `run`, `impl` | `.claude/skills/moai/workflows/run.md` |
| `sync`, `docs`, `pr` | `.claude/skills/moai/workflows/sync.md` |
| `project`, `init` | `.claude/skills/moai/workflows/project.md` |
| `fix` | `.claude/skills/moai/workflows/fix.md` |
| `loop` | `.claude/skills/moai/workflows/loop.md` |
| `review`, `code-review` | `.claude/skills/moai/workflows/review.md` |
| `gate`, `check`, `pre-commit` | `.claude/skills/moai/workflows/gate.md` |
| `e2e`, `e2e-test` | `.claude/skills/moai/workflows/e2e.md` |
| `clean`, `dead-code` | `.claude/skills/moai/workflows/clean.md` |
| `codemaps` | `.claude/skills/moai/workflows/codemaps.md` |
| `mx` | `.claude/skills/moai/workflows/mx.md` |
| `feedback`, `fb` | `.claude/skills/moai/workflows/feedback.md` |
| `harness`, `hrn` | `.claude/skills/moai/workflows/harness.md` |
| `goal` | `.claude/skills/moai/workflows/goal.md` |
| `todo`, `backlog` | `.claude/skills/moai/workflows/todo.md` |

For natural-language input, classify the whole request semantically. Prefer the narrowest matching workflow. If it is a clear development request with no narrower intent, execute the lifecycle as `plan -> run -> sync`, preserving any approval gates defined by the selected workflow.

A literal `SPEC-...` target with implementation intent routes to `run`.

## Progressive disclosure

1. Read root `AGENTS.md`.
2. Read `.dhaa/constitution/core.md` only when workflow/policy/verification/Git continuity is relevant.
3. Read **only** the selected workflow file from the table above.
4. Resolve references from that workflow lazily:
   - `${CLAUDE_SKILL_DIR}` means `.claude/skills/moai`.
   - `Skill("X")` means read `.claude/skills/X/SKILL.md` only when the workflow actually reaches that capability.
   - Read specific `.claude/rules/**` files only when the selected workflow points to them and their rule is needed.
5. Never preload the entire `CLAUDE.md` or the entire `.claude/` tree as a compatibility step.

## Capability translation: no subagent spawn

This adapter intentionally does not depend on Codex subagent spawning.

When the selected workflow says to spawn `Agent(...)`:

- For bounded planner/worker/docs tasks, execute the described role sequentially in the current Codex session while preserving its scope and acceptance criteria.
- For a truly independent audit, first use a MoAI-provided Codex audit/role surface if it is exposed by the configured MoAI MCP/CLI integration.
- If no independent surface is available, run a self-review as a fallback and label the result `independence: degraded`.
- Do not recursively invoke arbitrary `codex exec` children to pretend that independence exists.
- Convert parallel fan-out to sequential execution unless a MoAI-owned top-level orchestration primitive explicitly performs the fan-out.

When the workflow says `AskUserQuestion`, use Codex's available interactive question/approval path. If no structured question mechanism exists, stop at that gate and state the minimum decision required.

## State and verification

Use repository artifacts as continuity state:

- `.moai/specs/**`
- current Git branch/status/diff
- project requirements/docs
- existing reports and handoff artifacts

Do not claim a test, build, audit, or completion that was not observed. Preserve the selected workflow's mechanical gates and record capability degradation instead of silently skipping it.

## Finish

Report:

- workflow/subcommand executed
- repository artifacts changed
- verification actually observed
- any capability degradation, especially independent-review degradation
- remaining blocker or next approved lifecycle step
