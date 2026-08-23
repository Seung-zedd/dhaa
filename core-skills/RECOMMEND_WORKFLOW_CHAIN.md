# You can choose certain chaining workflow based on project progress.

## 1. new feature development:
`/moai plan → /moai run SPEC-XXX → /moai sync SPEC-XXX`

## 2. bug fix:
`/moai fix (또는 /moai loop) → /moai review → /moai sync`

## 3. refactoring:
`/moai plan → /moai clean → /moai run SPEC-XXX → /moai review → /moai coverage → /moai codemaps`

## 4. update docs:
`/moai codemaps → /moai sync`

## 5. security audit:
`/moai security → (fix: /moai run SPEC-XXX if structural, direct edit if a one-liner) → /moai review --security → /moai sync`

Run before a release, and after touching auth, payment, user-data boundaries, or dependencies.

**`/moai security` cannot be typed as a slash command.** moai-adk 3.1.2 ships no
`commands/moai/security.md` — verified against the binary's embedded command templates — so
the `/moai` menu never offers it, and typing it does nothing. The workflow itself is intact
(`.claude/skills/moai/workflows/security.md`); invoke it in natural language and the moai
skill routes security / audit / owasp / vulnerability / injection / xss / csrf to it.
Aliases: `audit`, `sec`.

Do not substitute one for the other:
- `/moai review --security` — one lens inside a general code review, scoped to the diff
- `/moai security` — dedicated pass: OWASP Top 10, dependency scan, secrets detection, data isolation (expert-security)
