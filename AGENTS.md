# DHAA Codex Adapter Contract

This repository can be driven by Codex CLI through the DHAA Codex adapter. Codex is an executor of the same durable workflow/state used by the Claude reference path; it is not a second source of truth.

## Context budget

Keep the always-loaded surface small.

- Do **not** read `CLAUDE.md` wholesale just to imitate Claude Code.
- Do **not** recursively preload `.claude/`, `.moai/`, `core-skills/`, or documentation.
- Read `.dhaa/constitution/core.md` when the task touches workflow, policy, verification, Git, or cross-harness continuity. A trivial local edit does not require loading the whole contract stack.
- Read only the exact workflow/skill/reference files required by the current task.
- Treat `.claude/**` as the existing reference implementation, not as automatically loaded Codex context.

## Codex capability adapter

The current DHAA Codex path assumes **no subagent-spawn capability**.

- Never emulate `Agent(...)` by recursively launching ad-hoc Codex children.
- Planner/implementer/documentation roles that are bounded can be executed sequentially in the current Codex session.
- When a workflow requires a genuinely independent audit, prefer MoAI's Codex audit/role surface exposed through the configured MoAI MCP/CLI integration when available.
- If an independent audit surface is unavailable, perform an explicit self-review only as a fallback and report `independence: degraded`. Never present that fallback as an independent review.
- If a workflow requires parallel agent fan-out, serialize the work unless a MoAI-provided top-level orchestration surface owns that fan-out.

Other Claude-specific primitives adapt as follows:

| Claude-oriented primitive | Codex adapter behavior |
|---|---|
| `/moai ...` slash command | Use the installed `$dhaa` skill with the same subcommand, or describe the task naturally |
| `Skill("name")` | Read the matching `.claude/skills/<name>/SKILL.md` lazily only when required |
| `Agent(...)` | Execute bounded work inline/sequentially; use MoAI audit/role tooling for independent audit when available |
| `AskUserQuestion` | Use Codex's available interactive question/approval surface; otherwise stop with a concise blocker that names the missing decision |
| `${CLAUDE_SKILL_DIR}` | Resolve to `.claude/skills/moai` for the current repository |
| Claude output styles | Follow this contract and the selected workflow directly |

## Workflow entry

The local Codex adapter skill is installed at:

`.agents/skills/dhaa/SKILL.md`

It is generated/copied locally by `.dhaa/adapters/codex/bootstrap.sh`; `.agents/` remains a local deployment surface and is intentionally not tracked.

Typical usage inside Codex CLI:

```text
$dhaa plan <request>
$dhaa run SPEC-XXX
$dhaa sync SPEC-XXX
```

The dispatcher loads only the selected workflow and its necessary references.

## MoAI wiring

Codex hooks and MoAI MCP configuration are owned by MoAI's Codex wiring command. Prefer:

```bash
moai tool enable codex
```

The DHAA bootstrap script previews that operation by default and applies it only with `--apply`.

Do not hand-edit generated `.codex/hooks.json` or the MoAI-owned portions of `.codex/config.toml` during normal setup. Project-owned Codex configuration may coexist with those generated sections.

## Continuity

Before switching from Claude Code to Codex, rely on repository state rather than chat memory:

- current `.moai/specs/` documents and progress
- current Git branch/status/diff
- project requirements and decisions
- latest durable reports/handoff artifacts that actually exist

When switching back, leave the same durable artifacts in a state another harness can inspect without needing the previous chat transcript.
