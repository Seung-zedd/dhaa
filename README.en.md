# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

> **Experiment Stage**  
> DHAA is currently in an experimental stage focused on validating its concepts and structure. Interfaces, directory layout, supported harnesses, and agent composition may change as the experiment evolves.

**DHAA = Domain, Harness & Agent-Agnostic**

DHAA aims to provide an **agentic engineering workspace architecture** that is not tightly coupled to a specific application domain, AI coding harness, or agent implementation.

The current reference implementation uses **Claude Code + MoAI-ADK**, but the goal of DHAA is not to standardize on that implementation. Instead, it explores how development workflows and operational rules can be separated into higher-level layers so they can be reused across different combinations of domains, harnesses, and agents.

## Goals

DHAA aims to loosen three types of coupling:

- **Domain-agnostic** — not tied to a specific product or problem domain such as PillWriter, SaaS, XR, or backend systems
- **Harness-agnostic** — structured so that the execution harness is not permanently tied to Claude Code and can potentially be replaced by another coding-agent harness
- **Agent-agnostic** — separates roles and rules from specific planner, reviewer, worker agents, or model implementations

The current implementation still contains coupling to Claude Code and MoAI-ADK. Therefore, this repository should be viewed not as a finished agnostic framework, but as a **reference experiment** for validating how far those dependencies can be generalized and reduced.

## Current Implementation: Two-Layer Inheritance Model

The current experiment uses Claude Code and MoAI-ADK in a two-layer workspace model.

| Layer | Inherited? | Description |
|---|---|---|
| **Claude Code layer** | ✅ inherited by child directories | `CLAUDE.md`, `.claude/` (agents/skills/rules/hooks/commands), `/moai` slash commands |
| **`moai` binary layer** | ❌ only local `.moai/` is recognized | `moai status`/`loop`/`fix`/quality gates — each app requires its own local `.moai/` |

- Claude Code traverses the directory tree upward, so sessions opened inside child app folders inherit the workspace-level agentic engine configuration.
- The `moai` binary does not inherit the parent `.moai/`, so each application obtains its own local `.moai/` through `moai init`.
- This structure experiments with reducing context bloat caused by duplicating the same `CLAUDE.md`, agents, skills, and rules in every application repository.

## Repository Layout

```text
projects/                        ← DHAA workspace
├── CLAUDE.md                    # current reference orchestrator instructions
├── development_pipeline_guideline.md
├── core-skills/                 # reusable engineering rules
├── .claude/                     # current harness implementation
│   └── settings.json
├── .moai/                       # current MoAI-ADK reference configuration
├── .mcp.json                    # project-scoped MCP definitions
├── pkg-supply-chain-check.sh    # npm package supply-chain pre-check
├── skills-lock.json             # installed skill versions
└── (app folders)                # independent domain repositories
```

Domain applications and local runtime state such as `.moai/reports|state|plans` and `.claude/tmp` are separated from this workspace repository.

## Setup After Cloning

### 0. Prerequisites

These requirements apply to the current reference implementation.

- **Git** + **Git Bash** (Windows — for hook scripts)
- **Node.js** (LTS)
- **pnpm**
- **gh CLI**
- **moai binary** (MoAI-ADK)
- **Claude Code CLI**

As harness abstraction progresses, these requirements are expected to move into implementation-specific documentation.

### 1. Clone

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

### 2. MCP Server Configuration

The current reference environment uses the following MCP setup.

| Server | Scope | Transport | Purpose | Setup / Auth |
|---|---|---|---|---|
| **github** | project (`.mcp.json`) | HTTP (readonly) | repo/issue/PR read | `${GITHUB_PERSONAL_ACCESS_TOKEN}` environment variable |
| **context7** | user | HTTP | latest library docs | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` |
| **serena** | user | stdio | LSP symbol search/edit | installed via `uvx` |
| **headroom** | user | stdio | context compression | `headroom mcp serve` |
| **pencil** | user | stdio | UI design (.pen) editing | local desktop executable |
| **vercel** | plugin | HTTP | deployment/docs | Claude Code plugin |
| **claude.ai connectors** | account | HTTP | Google/Linear integration | `/mcp` authentication |

Paths for stdio servers may differ by machine.

### 3. Update `env.PATH` in `.claude/settings.json`

The current reference implementation may contain machine-specific paths. Update them for your environment, including:

- Node.js installation path
- npm global path
- moai installation path

Restart the session after changing the settings.

### 4. Verify the Environment

```bash
claude   # or moai cc
```

In the current implementation, verify that:

- ccstatusline renders correctly
- `/moai` slash commands are recognized
- workspace-level instructions, skills, and rules are inherited

## Adding a New Domain Application

> The following procedure applies to the current Claude Code + MoAI-ADK reference implementation.

```bash
# 1) obtain a local .moai/
moai init my-new-app
cd my-new-app

# 2) remove duplicated configuration inherited from the parent workspace
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles

# keep local runtime-dependent files such as hooks/settings in the current implementation

# 3) start a session
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

This workflow is not a stable DHAA API. It is part of the **current reference experiment**.

## Experiment Roadmap

DHAA is currently exploring the following questions:

1. How clearly can domain-specific context be separated from the workspace engine?
2. Can Claude Code-specific instructions be abstracted into a form reusable by other harnesses?
3. Can agent roles such as planner, reviewer, and worker be separated from specific models or agent implementations?
4. Can engineering lifecycle stages such as SPEC, test, review, and sync be expressed as harness-independent contracts?
5. Does this abstraction actually reduce context bloat and orchestration complexity?

Until these questions are sufficiently validated, DHAA's structure and naming should not be considered a stable public API.

## Notes

- DHAA is currently in **Experiment Stage**, so breaking changes are expected.
- Claude Code and MoAI-ADK are the **current reference implementation**, not confirmed mandatory dependencies of DHAA.
- Implementation-specific commands such as `moai update` currently follow the behavior of the reference environment.
- Application folders are expected to be maintained as independent Git repositories.
- `pkg-supply-chain-check.sh` can be used for package supply-chain checks before installation.

---

**DHAA is an experiment in separating agentic engineering workflows from the domain, harness, and agent implementations that execute them.**
