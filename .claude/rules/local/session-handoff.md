# Session Handoff — ultrathink Resume Block

Ported 2026-10-11 from the PillWriter app repo's
`.claude/rules/local/session-handoff.md`, which was itself ported 2026-09-02
from the moai-adk v3.1.2 session-handoff doctrine.
Slim adaptation — the v3 zone registry, output-style render surface, and
`handoff.yaml` auto-inject flow are NOT ported. This repo keeps no
session-state file: git state is the source of truth, and the block below is a
paste surface only.

This file lives in `.claude/rules/local/` on purpose: `.claude/rules/moai/` is
a managed path that `moai update` replaces (see the `moai update` warning in
`development_pipeline_guideline.md`).

## When

On the session-end routine (the user says "세션을 마무리할게", "오늘은 여기까지",
asks for a "재개블록", or equivalent), emit a paste-ready resume message in a
fenced text block.

## Why `ultrathink.` leads the block

`ultrathink` is a Claude Code harness keyword: pasting the block as the next
session's first message makes that turn run at max reasoning effort — exactly
the turn that must reconstruct context from cold. Treat `ultrathink.` as a
command token, never translated.

## Format (cut-line bounded)

```text
✂──── 여기부터 복사 ────✂

ultrathink. <SPEC-ID or task> <phase> 진입.
applied lessons: <relevant memory files, if any>
source_session_id: <UUID from `moai session current`; omit if unavailable>

전제 조건:
1) <verifiable check> → <expected outcome>   (max 4)

실행:
<single work-starting command or first action>

후속:
<exactly one queued next action; omit block if nothing queued>

✂──── 여기까지 복사 ────✂
```

- Labels and phase verbs render in `conversation_language`; `ultrathink.`,
  SPEC ids, file paths, and command literals stay verbatim.
- Each precondition must be independently verifiable (a command or file check).
- `실행` carries ONE primary work-starting action — never a bare status note.

## Proactive trigger — context threshold

Also emit the block WITHOUT waiting for the session-end phrase when the
`ccstatusline` gauge reaches the compaction threshold defined in
`development_pipeline_guideline.md` Section 3, BEFORE running `/clear` or
`/compact`.

When in doubt, hand off early: a wide window is a reason to fold sooner and keep
cache headroom, not to run to the ceiling.

## Persistence (fail-open) [HARD]

After emitting, optionally `moai handoff save` (record:
`.moai/state/handoff/pending.json`). If the CLI is absent or exits non-zero,
emit the block unchanged and move on — the save never gates the handoff.
Without `handoff.mode: auto` in project config the record is inert; paste is
the activation path.

## Output order

fenced block → memory/save note (one line) → one-sentence next-session summary.
