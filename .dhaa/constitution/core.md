# DHAA Core Contract

DHAA treats a coding harness as a transient executor. Durable workflow state, policy, evidence, and handoff state belong to repository artifacts rather than to one vendor session.

## Ownership

- Product requirements and project-specific decisions belong to project documents such as `PRD.md` and the application's own docs.
- Engineering lifecycle state belongs under `.moai/` (SPECs, plans, progress, reports, configuration, and runtime state as applicable).
- Harness-specific files such as `CLAUDE.md`, `AGENTS.md`, `.claude/`, and `.codex/` are projections/adapters. They are not the canonical owner of durable project state.
- Preserve task continuity, memory continuity, and policy continuity when switching harnesses.

## Evidence

- Do not claim a test, build, review, defect, or completion that was not actually observed.
- When reporting verification, name the command or tool used and the observed result.
- Missing evidence is a gap, not a pass.
- Separate facts from hypotheses when diagnosing failures.

## Development lifecycle

Use the existing DHAA/MoAI lifecycle unless the user explicitly chooses a narrower path:

`plan -> run -> verify/review -> sync`

- Planning defines scope and acceptance criteria.
- Implementation changes the smallest justified surface.
- Verification runs the relevant mechanical checks.
- Sync updates durable documentation/state only after implementation evidence exists.

Do not manufacture ceremony for trivial changes. Progressive disclosure is preferred over loading the whole control plane for every task.

## Safety and Git

- Do not expose or read secrets unless the task explicitly requires an approved secret-handling path.
- Avoid destructive Git operations by default.
- Before commit or push, re-read branch/HEAD/status so the action is based on current repository state.
- Never treat another session's uncommitted work as disposable.
- Company policy, repository policy, and configured permission boundaries override convenience.

## Context discipline

Context is a costed resource.

- Load only the instructions, skills, code, and evidence required for the current task.
- Do not recursively preload `.claude/`, `.moai/`, `core-skills/`, or project docs.
- Prefer short entry contracts that point to detailed references loaded on demand.
- Harness adapters may implement the same DHAA contract differently when their native capabilities differ.

## Capability degradation

A missing harness capability must be represented explicitly, not silently simulated.

- If an independent reviewer cannot be created, report that independence is degraded.
- If a structured user-question channel is unavailable, stop at the decision boundary and ask for the missing input through the harness's available interaction surface.
- If a workflow feature cannot be reproduced safely, preserve state and report the unsupported capability rather than bypassing a guardrail.
