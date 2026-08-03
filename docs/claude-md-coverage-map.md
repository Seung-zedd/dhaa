# CLAUDE.md coverage map

Audit artifact for the 2026-08-03 restructure that cut `CLAUDE.md` from 720 lines to
its current size. Every removed section is either covered by an auto-loading rule file,
injected by the harness, or restated in the slimmed `CLAUDE.md`.

Recorded so nothing was dropped silently: the restructure pathology documented in
`core-skills/filesystem-memory-for-llm-agents-summary.md` (RQ1) is that a model silently
compresses and loses content unless fact preservation is stated and proved.

This file is deliberately NOT loaded into sessions — it has no runtime routing value.
Read it when auditing whether a rule went missing, or before removing another section.

| Removed section | Now covered by |
|---|---|
| Section 1 Core Identity HARD rules | `moai-constitution.md` (orchestrator, AskUserQuestion, parallel execution, response language, output format) + Section 2 above |
| Section 2 Request Processing Pipeline | routing meta with no rule content; dropped |
| Section 3 Command Reference | harness injects the live skill list (`moai:plan`, `moai:run`, ...) every session |
| Section 4 Agent Catalog | harness injects the live agent catalog with descriptions; the routing judgment is kept in Section 2 |
| Section 5 SPEC-Based Workflow | Section 5 above (compacted); full team reference indexed in Section 12 |
| Section 6 Quality Gates | `moai-constitution.md` (TRUST 5) + Section 5 above (harness levels, LSP thresholds) |
| Section 7 Safe Development Protocol | Section 3 above, verbatim |
| Section 8 User Interaction Architecture | `moai-constitution.md` + `agent-common-protocol.md`; the 4x4 limit, no-emoji rule, and recommended-first rule are restated in Section 3 Rule 5 |
| Section 9 Configuration Reference | Section 11 (kept yaml imports) + Section 12 (index) |
| Section 10 Web Search Protocol | `moai-constitution.md` (URL Verification) + Section 9 above |
| Section 11 Error Handling | `moai-constitution.md` (Error Handling Protocol) + Section 8 routing table |
| Section 12 MCP Servers | Section 10 above |
| Section 13 Progressive Disclosure System | `.claude/rules/moai/development/skill-authoring.md` and `.claude/rules/moai/workflow/spec-workflow.md` — both load on demand, which is when the 3-level model is actually needed |
| Section 14 Parallel Execution Safeguards | `moai-constitution.md` + `worktree-integration.md` + `agent-common-protocol.md`; the residue is Section 7 |
| Section 15 Agent Teams | Section 6 above + `team-protocol.md` (auto-loads) + `spec-workflow.md` (indexed) |
| Section 16 Context Search Protocol | restated compactly in `CLAUDE.md` Section 5 (triggers, confirmation step, 30-day window, 5,000-token injection cap, 150,000-token skip guard); storage contract in `.claude/rules/moai/workflow/moai-memory.md` |
| Section 17 Troubleshooting | Section 8 above |
| Section 18 SPEC Review Pipeline | Section 4 above, verbatim |

---
