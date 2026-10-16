# DHAA Codex CLI Adapter (experimental)

This adapter lets a self-contained DHAA snapshot run its existing MoAI engineering lifecycle from Codex CLI without making Claude Code's `CLAUDE.md` the Codex source of truth.

The design goal is **portable workflow with a smaller always-loaded surface**, not byte-for-byte emulation of Claude Code.

## Design

```text
                    DHAA durable state
          PRD / .moai specs / config / evidence
                          |
             .dhaa/constitution/core.md
                          |
             +------------+------------+
             |                         |
       Claude adapter              Codex adapter
       CLAUDE.md + .claude         AGENTS.md + $dhaa
             |                         |
        Claude Code                 Codex CLI
```

Codex automatically receives the small root `AGENTS.md`. Detailed MoAI workflow files under `.claude/skills/moai/workflows/` are treated as reference implementation assets and are opened **only when a routed workflow needs them**.

This follows the DHAA principle that a harness is a transient executor and keeps large Claude-specific context out of Codex's always-loaded path.

## Important capability boundary: no subagent spawn

The current DHAA Codex adapter assumes Codex CLI does **not** provide the subagent-spawn behavior used by the Claude reference path.

This is an explicit adapter boundary, not something to fake.

- Bounded planner/worker/docs roles run sequentially in the current Codex session.
- Parallel fan-out is serialized unless a MoAI-owned top-level orchestration surface performs it.
- Independent review uses an available MoAI Codex audit/role surface when one is exposed through the MoAI MCP/CLI integration.
- If no independent surface is available, the fallback is a self-review labelled `independence: degraded`.
- The adapter never recursively launches arbitrary `codex exec` children just to imitate `Agent(...)`.

This means Codex and Claude can satisfy the same DHAA-level lifecycle without pretending their execution graphs are identical.

## Setup

Prerequisites:

- Codex CLI installed and authenticated under the company-approved account/policy
- `moai` on PATH
- a MoAI version that exposes the additive `moai tool enable codex` command
- Git Bash (the bootstrap scripts are Bash)

From the application/DHAA snapshot root:

```bash
# 1. Preview only — no writes
bash .dhaa/adapters/codex/bootstrap.sh

# 2. Apply Codex wiring + install the local $dhaa skill
bash .dhaa/adapters/codex/bootstrap.sh --apply

# 3. Diagnose
bash .dhaa/adapters/codex/doctor.sh
```

The bootstrap intentionally refuses to fall back to `moai init --force` or a broad `moai update`. DHAA snapshots can carry local template changes, so a missing additive Codex command must be resolved in the DHAA engine's normal update branch/review process.

The apply step does two things:

1. Runs MoAI's additive Codex wiring so MoAI owns the relevant `.codex/hooks.json` / `.codex/config.toml` sections.
2. Copies `.dhaa/adapters/codex/SKILL.md` to the local deployment path `.agents/skills/dhaa/SKILL.md`.

`.agents/` remains ignored by Git in DHAA; it is a local harness deployment surface.

## Start Codex

Prefer the MoAI launcher when available:

```bash
moai codex
```

Then use the adapter skill:

```text
$dhaa plan "implement crawling source registration"
$dhaa run SPEC-XXX
$dhaa sync SPEC-XXX
$dhaa resume
```

Natural-language requests are also supported by the dispatcher, but explicit subcommands are useful while validating parity.

## Context strategy

The adapter intentionally does **not** import all of `CLAUDE.md`.

Always-loaded:

- root `AGENTS.md`

Loaded only when relevant:

- `.dhaa/constitution/core.md`
- one selected workflow under `.claude/skills/moai/workflows/`
- individual referenced skills/rules
- code and project docs needed by the current task

This is meant to reduce avoidable context bloat. It is not a claim that Codex will always consume fewer tokens than Claude Code; compare the same real work in both harnesses and measure completion quality, context/usage, and wall-clock time.

## Crash / quota failover

DHAA adds a model-free local checkpoint at `.moai/state/dhaa-recovery.md`. It records branch/HEAD, working-tree summaries, and the tail of the newest `progress.md` candidate without asking a model to summarize the session.

The Claude reference path refreshes that checkpoint on normal `Stop` and on `StopFailure`, including `overloaded` (the error class used for provider-overload/529-style failures), rate limits, server errors, and output-limit failures. Because the checkpoint is produced by a shell script, it does not require a successful final model response.

Manual checkpoint:

```bash
bash .dhaa/runtime/checkpoint.sh --reason manual
```

Recovery bundle:

```bash
bash .dhaa/runtime/recover.sh
```

Or from Codex:

```text
$dhaa resume
```

Recovery order is: current MoAI handoff (verify preconditions) -> exact SPEC `progress.md` -> live Git state -> local checkpoint -> project requirement entry points. The newest `progress.md` by mtime is only a candidate. An interrupted model/tool turn is considered incomplete unless repository/tool evidence proves completion.

The checkpoint is under `.moai/state/`, so it is intentionally machine-local and ignored by Git. Cross-machine continuity should rely on durable SPEC/progress/project artifacts plus any explicitly shared/committed state.

## Switching harnesses

Do not depend on chat memory when moving between Claude Code and Codex.

Before switching, make the repository state sufficient to resume:

- current SPEC/plan/progress under `.moai/`
- current Git branch/status/diff
- durable project decisions/docs
- actual verification evidence and unresolved blockers

The receiving harness should be able to continue by reading those artifacts, not by reconstructing the previous vendor session.

## Generated wiring and trust

Normal setup should not hand-edit MoAI-owned Codex wiring. After a wiring change, inspect the generated diff and use Codex's `/hooks` surface to verify/re-trust project hooks when the Codex runtime requires it.

Company security policy wins over this adapter. If an organization-managed setting blocks a hook, MCP server, CLI login, or project trust action, do not bypass it.
