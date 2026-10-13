# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

### 特定 Domain？**无所谓。**
### Claude Code 还是 Codex？**无所谓。**
### 哪个 Agent？**无所谓。**

**DHAA — Domain, Harness & Agent-Agnostic**

> **🚧 Experiment Stage（实验阶段）**  
> DHAA 是一个实验项目，用于验证能在多大程度上将 **agentic software engineering workflow 与 context ownership** 从 domain、harness 和 agent 中分离出来。接口、目录结构、支持的 harness 和 agent 组成可能随实验结果变化。

DHAA 旨在构建一种不与特定应用 domain、AI coding harness 或 agent 实现强绑定的 **agentic engineering control plane / workspace architecture**。

当前 reference implementation 从 **Claude Code + MoAI-ADK** 开始，但 DHAA 并不打算把这一组合固定为标准。Claude Code、Codex、OpenCode 等 coding harness，以及 MoAI-ADK 等 orchestration framework，都被视为位于更高层 workflow、policy、memory 和 execution state 之下的 **可替换实现**。

## 为什么需要 DHAA？

当 agentic development workflow 与特定 vendor 或 harness session 强耦合时，外部故障可能直接演变为整个开发流程的中断。

当 LLM API 返回 `529`、`429` 或 timeout 时，如果 active goal、task state、session memory、`CLAUDE.md`/`AGENTS.md` 等 governing instructions、agent role 以及 engineering lifecycle 也由该 session 持有，那么一次 API 故障就可能成为完整的 workflow outage。

DHAA 并不试图消除 provider outage，而是希望 **缩小外部故障的 blast radius，避免 provider outage 自动变成 workflow outage**。

> **DHAA does not prevent provider outages; it aims to prevent provider outages from becoming workflow outages.**

## 目标

- **Domain-agnostic** — 不依赖某个特定产品、SaaS、XR、backend 或其他问题领域
- **Harness-agnostic** — 不固定于 Claude Code、Codex、OpenCode 或其他 coding harness
- **Agent-agnostic** — 将 planner、reviewer、worker 等角色和规则与特定 agent/model implementation 分离
- **Orchestration-agnostic** — 不固定于 MoAI-ADK 或其他 orchestration framework/lifecycle implementation
- **Context-portable** — constitution、durable memory、execution state 和 handoff state 可以在特定 session/harness 之外保存，并移动到其他 execution path

当前实现仍然存在 Claude Code 和 MoAI-ADK 耦合，因此本仓库是 **reference experiment**，而不是已经完成的 agnostic framework。

## Core Idea：分离 Workflow 与 Context 的所有权

```text
Vendor / Harness Session
        ↓
   transient executor
        ↓
DHAA-owned workflow state
```

Claude Code、Codex 或其他 harness 被视为当前 workflow 的 executor，而不是 development session 的所有者。

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

DHAA 不把 `CLAUDE.md` 或 `AGENTS.md` 本身固定为 canonical format，而是探索由更高层 constitution 通过不同 harness adapter 投影到各自格式。

```text
DHAA Constitution
    ├── Claude adapter → CLAUDE.md
    ├── Codex adapter  → AGENTS.md
    └── Other adapter  → harness-specific instructions
```

目标是在 harness 切换后仍保持 **Task continuity、Memory continuity 和 Policy continuity**。

## 故障韧性实验

```text
529 / 429 / timeout
        ↓
判断 transient failure
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

> **Retry transient failures, isolate persistent failures, preserve state, then fail over.**

## Branch Strategy

DHAA 的 Git branch 也遵循相同的 abstraction 原则。Git branch 本身没有真正的父子层级，因此使用基于 `/` 的 naming convention 表达逻辑分类。

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

- `main` 保存与 harness/vendor 无关的 canonical contract、architecture 和 invariant。
- `feature/core/*` 用于实验 continuity bundle、lifecycle contract 等 DHAA 自身的 portable abstraction。
- `feature/claude-specific/*`、`feature/codex-specific/*` 等用于实验针对各 harness 优化的 adapter 和 integration。
- Claude-specific 与 Codex-specific 的实现不需要相同。**实现方式可以不同，只要满足相同的 DHAA-level contract 和 continuity invariant。**
- 不应把某个 harness 中成功的实现机械复制到另一个 harness；每个 adapter 应尽可能利用对应 harness 的 native capability。

```text
                 DHAA Contract
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Claude-native adapter    Codex-native adapter
          │                       │
          └──── same contract ────┘
```

现有 feature branch 中的 Claude-specific 实现暂时保留，未来在 PR 阶段按照这些原则拆分 portable core 与 harness-specific adapter。

## 当前 Reference Implementation

当前环境仍然使用 **Claude Code + MoAI-ADK**，但这只是用于发现 abstraction boundary 的第一个 reference implementation，而不是 DHAA 的最终 architecture。

| Layer | 是否继承 | 内容 |
|---|---|---|
| **Claude Code layer** | ✅ 子目录继承 | `CLAUDE.md`、`.claude/` agents/skills/rules/hooks/commands、`/moai` commands |
| **`moai` binary layer** | ❌ 仅 local `.moai/` | status/loop/fix/quality gates；每个 app 需要 local `.moai/` |

这个 two-layer model 本身也计划被隔离为 DHAA-level contract 与 adapter 背后的 implementation detail。

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

未来可能演进为如下 DHAA-owned 区域：

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

这只是 **design direction**，并非稳定 public API。

## Setup

当前 reference implementation 使用 Git、Git Bash、Node.js、pnpm、gh CLI、moai binary 和 Claude Code CLI。

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

随着 abstraction 推进，Claude Code/MoAI-ADK 专用设置将逐步移动到 implementation-specific 文档中。

## 添加新的 Domain Application

> 以下仅适用于当前 Claude Code + MoAI-ADK reference implementation。

```bash
moai init my-new-app
cd my-new-app
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles
moai cc
```

当前 MoAI workflow 为 `/moai project → plan → run → loop/fix → sync`，它只是一个 **orchestration reference**，不是稳定的 DHAA API。

## Experiment Roadmap

1. Domain-specific context 能否与 DHAA control plane 清晰分离？
2. 能否在 `CLAUDE.md`、`AGENTS.md` 等 harness-specific format 之上定义 portable constitution？
3. Durable memory 和 session handoff 能否移动到 vendor session 之外？
4. Planner、reviewer、worker role 能否与特定 model/agent implementation 分离？
5. 不依赖 MoAI-ADK，能否将 SPEC、plan、run、test、review、sync 定义为独立 contract？
6. Provider 故障时能否使用 exponential backoff/retry budget，并在持续故障时保存 state 后切换 provider/harness？
7. Harness 切换后能否继续保持 task、memory、policy continuity？
8. 这些 abstraction 是否能实际降低 context bloat、orchestration complexity 和 human intervention wall-clock time？

```text
P0  Portable constitution / memory / execution state
P0  Harness adapter boundary
P0  Failure detection + retry/backoff + failover
P1  Harness-independent engineering lifecycle
P1  Dynamic workflow orchestration
P1  Human intervention wall-clock time measurement
```

## 注意事项

- DHAA 当前处于 **Experiment Stage**，因此可能发生 breaking changes。
- Claude Code 和 MoAI-ADK 是当前的 **reference implementation**，并非 DHAA 的强制组件。
- 包括 MoAI-ADK 在内的 orchestration framework 也计划作为可替换的 implementation/adapter layer 处理。
- Application folder 预计继续作为独立 Git repository 管理。

---

**DHAA is an experiment in making agentic software engineering workflows, memory, policy, and execution state portable across domains, harnesses, agents, and orchestration implementations.**