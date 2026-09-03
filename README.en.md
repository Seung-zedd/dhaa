# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

### Any Domain? **Doesn't matter.**
### Claude Code or Codex? **Doesn't matter.**
### Which Agent? **Doesn't matter.**

**DHAA — Domain, Harness & Agent-Agnostic**

> **🚧 Experiment Stage**  
> DHAA is an experimental project exploring how far **agentic software engineering workflows and context ownership** can be separated from domains, harnesses, and agents. Interfaces, directory layouts, supported harnesses, and agent composition may change as the experiments evolve.

DHAA aims to become an **agentic engineering control plane / workspace architecture** that is not tightly coupled to a particular application domain, AI coding harness, or agent implementation.

The reference implementation started with **Claude Code + MoAI-ADK**, but DHAA does not intend to standardize on that combination. Coding harnesses such as Claude Code, Codex, and OpenCode, as well as orchestration frameworks such as MoAI-ADK, are treated as **replaceable implementations** beneath higher-level workflow, policy, memory, and execution-state abstractions.

## Why?

When an agentic development workflow is tightly coupled to a vendor or harness session, an external outage can become a complete development outage.

If an LLM API returns `529`, `429`, or timeout failures, the problem becomes much larger when the session also owns the active goal, task state, memory, governing instructions such as `CLAUDE.md` or `AGENTS.md`, agent roles, and the engineering lifecycle.

DHAA does not attempt to eliminate provider outages. It aims to **reduce their blast radius so that an external failure does not automatically become a workflow failure**.

> **DHAA does not prevent provider outages; it aims to prevent provider outages from becoming workflow outages.**

## Goals

- **Domain-agnostic** — not tied to a specific product, SaaS, XR system, backend, or other problem domain
- **Harness-agnostic** — not permanently tied to Claude Code, Codex, OpenCode, or another coding harness
- **Agent-agnostic** — roles and rules are separated from specific planner, reviewer, worker agents or model implementations
- **Orchestration-agnostic** — not tied to MoAI-ADK or another orchestration framework or lifecycle implementation
- **Context-portable** — constitution, durable memory, execution state, and handoff state can survive outside a particular session or harness and move to another execution path

The current implementation still contains Claude Code and MoAI-ADK coupling. This repository is therefore a **reference experiment**, not a finished agnostic framework.

## Core Idea: Separate Workflow and Context Ownership

A vendor session should not be the canonical owner of engineering state.

```text
Vendor / Harness Session
        ↓
   transient executor
        ↓
DHAA-owned workflow state
```

Claude Code, Codex, or another harness is treated as an executor of the current workflow rather than the owner of the development session.

### Portable Context / Continuity Bundle

```text
DHAA Continuity Bundle
├── Constitution
│   ├── governing rules
│   ├── engineering principles
│   └── harness-specific projection (e.g. CLAUDE.md, AGENTS.md)
├── Durable Memory
│   ├── project decisions
│   ├── learned constraints
│   └── long-lived context
├── Execution State
│   ├── active goal
│   ├── current lifecycle phase
│   ├── completed / pending tasks
│   ├── observations
│   └── test / git state
└── Session Handoff
    ├── latest summary
    ├── unresolved questions
    ├── important tool outputs
    └── continuation instructions
```

Instead of making `CLAUDE.md` or `AGENTS.md` the canonical format, DHAA explores a higher-level constitution projected by harness adapters.

```text
DHAA Constitution
    ├── Claude adapter → CLAUDE.md
    ├── Codex adapter  → AGENTS.md
    └── Other adapter  → harness-specific instructions
```

The goal is to preserve three forms of continuity across harness changes: **task continuity, memory continuity, and policy continuity**.

## Failure-Resilience Experiment

```text
529 / 429 / timeout
        ↓
classify transient failure
        ↓
exponential backoff + jitter
        ↓
retry budget exceeded
        ↓
checkpoint current state
        ↓
failover decision
        ↓
alternate provider or harness
        ↓
rehydrate context and resume
```

Exponential backoff is the first defense against transient overload. Persistent failures should not cause infinite retries; DHAA instead explores retry budgets and failover policies.

> **Retry transient failures, isolate persistent failures, preserve state, then fail over.**

## Branch Strategy

DHAA's Git branches follow the same abstraction principle. Git branches do not have a real parent-child hierarchy, so `/`-based naming expresses a logical hierarchy.

```text
main
│
├── feature/core/continuity-bundle
├── feature/core/lifecycle-contract
│
├── feature/claude-specific/context-adapter
├── feature/claude-specific/memory-handoff
├── feature/claude-specific/moai-bridge
│
├── feature/codex-specific/context-adapter
├── feature/codex-specific/memory-handoff
│
└── feature/<harness>-specific/...
```

> **main = agnostic truth, `*-specific` branches = implementation experiments.**

- `main` contains canonical contracts, architecture, and invariants that are independent of a harness or vendor.
- `feature/core/*` experiments with portable DHAA abstractions such as the continuity bundle and lifecycle contract.
- `feature/claude-specific/*`, `feature/codex-specific/*`, and similar branches explore adapters and integrations optimized for each harness.
- Claude-specific and Codex-specific implementations do not need to look alike. **They only need to satisfy the same DHAA-level contracts and continuity invariants.**
- A successful implementation for one harness should not be mechanically copied to another; each adapter should exploit the native capabilities of its harness.

```text
                 DHAA Contract
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Claude-native adapter    Codex-native adapter
          │                       │
          └──── same contract ────┘
```

Existing Claude-specific work in feature branches can remain until PR time, when portable core logic and harness-specific adapter logic can be separated under these rules.

## Current Reference Implementation

The current environment still uses **Claude Code + MoAI-ADK**. This is the first reference implementation for discovering abstraction boundaries, not DHAA's final architecture.

| Layer | Inherited? | Description |
|---|---|---|
| **Claude Code layer** | ✅ inherited by child directories | `CLAUDE.md`, `.claude/` agents/skills/rules/hooks/commands, `/moai` slash commands |
| **`moai` binary layer** | ❌ only local `.moai/` is recognized | status/loop/fix/quality gates; each app requires a local `.moai/` |

This two-layer model is itself expected to become an implementation detail behind DHAA-level contracts and adapters.

## Repository Layout

```text
projects/
├── CLAUDE.md
├── development_pipeline_guideline.md
├── core-skills/
├── .claude/
├── .moai/
├── .mcp.json
├── pkg-supply-chain-check.sh
├── skills-lock.json
└── (app folders)
```

A future DHAA-owned area may evolve toward:

```text
.dhaa/
├── constitution/
├── memory/
├── state/
├── handoff/
└── adapters/
    ├── claude/
    ├── codex/
    └── ...
```

This is a **design direction**, not a stable public API.

## Setup

Current reference implementation requirements:

- Git + Git Bash
- Node.js (LTS)
- pnpm
- gh CLI
- moai binary
- Claude Code CLI

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

Claude Code and MoAI-ADK-specific setup is currently part of the reference environment and is expected to move into implementation-specific documentation as abstraction progresses.

## Adding a Domain Application

> Current Claude Code + MoAI-ADK reference implementation only.

```bash
moai init my-new-app
cd my-new-app
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles
moai cc
```

Current MoAI workflow example:

```text
/moai project <name>
    ↓
/moai plan
    ↓
/moai run SPEC-XXX
    ↓
/moai loop / fix
    ↓
/moai sync
```

This is one **orchestration reference**, not a stable DHAA API.

## Experiment Roadmap

1. How clearly can domain-specific context be separated from the DHAA control plane?
2. Can a portable constitution exist above harness-specific formats such as `CLAUDE.md` and `AGENTS.md`?
3. Can durable memory and session handoff move outside vendor sessions?
4. Can planner, reviewer, and worker roles be separated from particular models and agent implementations?
5. Can SPEC, plan, run, test, review, and sync be defined as independent contracts without requiring MoAI-ADK?
6. Can provider failures use exponential backoff and retry budgets, then preserve state and switch provider or harness when failures persist?
7. Can task, memory, and policy continuity survive a harness switch?
8. Does this abstraction measurably reduce context bloat, orchestration complexity, and human intervention wall-clock time?

```text
P0  Portable constitution / memory / execution state
P0  Harness adapter boundary
P0  Failure detection + retry/backoff + failover
P1  Harness-independent engineering lifecycle
P1  Dynamic workflow orchestration
P1  Human intervention wall-clock time measurement
```

## Notes

- DHAA is in **Experiment Stage**, so breaking changes are expected.
- Claude Code and MoAI-ADK are the **current reference implementation**, not mandatory DHAA components.
- Orchestration frameworks, including MoAI-ADK, are intended to become replaceable implementation or adapter-layer concerns.
- Application folders are expected to remain independent Git repositories.

---

**DHAA is an experiment in making agentic software engineering workflows, memory, policy, and execution state portable across domains, harnesses, agents, and orchestration implementations.**