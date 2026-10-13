# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

### 特定のDomain？ **関係ありません。**
### Claude CodeかCodexか？ **関係ありません。**
### どのAgentか？ **関係ありません。**

**DHAA — Domain, Harness & Agent-Agnostic**

> **🚧 Experiment Stage（実験段階）**  
> DHAAは、domain、harness、agentから **agentic software engineering workflowとcontext ownershipをどこまで分離できるか** を検証する実験プロジェクトです。インターフェース、ディレクトリ構成、対応harness、agent構成は実験結果に応じて変更される可能性があります。

特定のアプリケーションdomain、AI coding harness、agent実装に強く依存しない **agentic engineering control plane / workspace architecture** を目指します。

現在のreference implementationは **Claude Code + MoAI-ADK** から始まりましたが、この組み合わせを標準として固定することが目的ではありません。Claude Code、Codex、OpenCodeなどのcoding harnessだけでなく、MoAI-ADKのようなorchestration frameworkも **交換可能な実装** として扱い、その上位にworkflow、policy、memory、execution stateを配置することを目指します。

## なぜ必要か？

Agentic development workflowが特定vendorやharness sessionに強く結合すると、外部障害がそのまま開発停止へ波及します。

LLM APIで`529`、`429`、timeoutなどが発生した際、active goal、task state、session memory、`CLAUDE.md`や`AGENTS.md`などのgoverning instructions、agent role、engineering lifecycleまでsession側に所有されていると、単なるAPI障害がworkflow全体の障害になります。

DHAAはprovider outageそのものをなくすプロジェクトではありません。**外部障害のblast radiusを縮小し、provider outageがそのままworkflow outageになることを防ぐ**ことを目指します。

> **DHAA does not prevent provider outages; it aims to prevent provider outages from becoming workflow outages.**

## 目標

- **Domain-agnostic** — 特定の製品、SaaS、XR、backendなど一つの問題領域に依存しない
- **Harness-agnostic** — Claude Code、Codex、OpenCodeなど特定のcoding harnessに固定しない
- **Agent-agnostic** — planner、reviewer、workerなど特定agentやmodel implementationからroleとruleを分離する
- **Orchestration-agnostic** — MoAI-ADKを含む特定orchestration frameworkやlifecycle implementationに固定しない
- **Context-portable** — constitution、durable memory、execution state、handoff stateを特定session/harnessの外で保存し、別のexecution pathへ移動可能にする

現在はまだClaude CodeとMoAI-ADKへの結合が残っているため、本repositoryは完成したframeworkではなく **reference experiment** です。

## Core Idea：WorkflowとContextの所有権を分離する

```text
Vendor / Harness Session
        ↓
   transient executor
        ↓
DHAA-owned workflow state
```

Claude CodeやCodexなどのharnessはdevelopment sessionの所有者ではなく、現在のworkflowを実行するexecutorとして扱います。

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

`CLAUDE.md`や`AGENTS.md`自体をcanonical formatにせず、上位のconstitutionを各harness adapterが投影する方式を検証します。

```text
DHAA Constitution
    ├── Claude adapter → CLAUDE.md
    ├── Codex adapter  → AGENTS.md
    └── Other adapter  → harness-specific instructions
```

harnessが変わっても **Task continuity、Memory continuity、Policy continuity** を維持することが目標です。

## 障害耐性の実験

```text
529 / 429 / timeout
        ↓
transient failureを判定
        ↓
exponential backoff + jitter
        ↓
retry budget超過
        ↓
current stateをcheckpoint
        ↓
failover decision
        ↓
alternate provider or harness
        ↓
contextをrehydrateしてresume
```

> **Retry transient failures, isolate persistent failures, preserve state, then fail over.**

## Branch Strategy

DHAAのGit branchも同じabstraction原則に従います。Git branch自体に実際の親子階層はないため、`/`を使ったnaming conventionで論理的な分類を表現します。

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

- `main`にはharness/vendor非依存のcanonical contract、architecture、invariantを置きます。
- `feature/core/*`ではcontinuity bundleやlifecycle contractなどDHAA固有のportable abstractionを検証します。
- `feature/claude-specific/*`、`feature/codex-specific/*`などでは各harnessに最適化したadapter/integrationを検証します。
- Claude-specificとCodex-specificの実装は同じである必要はありません。**実装が異なっても、同じDHAA-level contractとcontinuity invariantを満たせばよい**という考え方です。
- 一つのharnessで成功した実装を別のharnessへ機械的にコピーせず、それぞれのnative capabilityを活用します。

```text
                 DHAA Contract
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Claude-native adapter    Codex-native adapter
          │                       │
          └──── same contract ────┘
```

既存feature branchに残っているClaude-specific実装は直ちに削除せず、将来のPR時にportable coreとharness-specific adapterへ分離します。

## 現在のReference Implementation

現在の環境では引き続き **Claude Code + MoAI-ADK** を使用しています。ただし、これは最終architectureではなく、abstraction boundaryを見つけるための最初のreference implementationです。

| Layer | 継承 | 内容 |
|---|---|---|
| **Claude Code layer** | ✅ 子directoryへ継承 | `CLAUDE.md`、`.claude/` agents/skills/rules/hooks/commands、`/moai` commands |
| **`moai` binary layer** | ❌ local `.moai/`のみ | status/loop/fix/quality gates。各appにlocal `.moai/`が必要 |

この2-layer model自体も、将来的にはDHAA-level contractとadapterの背後にあるimplementation detailとして分離する予定です。

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

将来的には次のようなDHAA-owned領域を検証します。

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

これは安定したpublic APIではなく **design direction** です。

## Setup

現在のreference implementationではGit、Git Bash、Node.js、pnpm、gh CLI、moai binary、Claude Code CLIを使用します。

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

Claude Code/MoAI-ADK固有の設定は、abstractionの進展に伴いimplementation-specific documentへ分離する予定です。

## 新しいDomain Applicationの追加

> 現在のClaude Code + MoAI-ADK reference implementation向けです。

```bash
moai init my-new-app
cd my-new-app
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles
moai cc
```

現在のMoAI workflowは `/moai project → plan → run → loop/fix → sync` ですが、これは安定したDHAA APIではなく一つの **orchestration reference** です。

## Experiment Roadmap

1. Domain-specific contextをDHAA control planeから明確に分離できるか？
2. `CLAUDE.md`、`AGENTS.md`などの上位にportable constitutionを定義できるか？
3. Durable memoryとsession handoffをvendor session外へ移せるか？
4. Planner、reviewer、worker roleを特定model/agent implementationから分離できるか？
5. MoAI-ADKなしでもSPEC、plan、run、test、review、syncを独立contractとして定義できるか？
6. Provider障害時にexponential backoff/retry budgetを適用し、持続障害ではstateを保存したままprovider/harnessを切り替えられるか？
7. Harness切替後もtask、memory、policy continuityを維持できるか？
8. このabstractionがcontext bloat、orchestration complexity、human intervention wall-clock timeを実際に削減できるか？

```text
P0  Portable constitution / memory / execution state
P0  Harness adapter boundary
P0  Failure detection + retry/backoff + failover
P1  Harness-independent engineering lifecycle
P1  Dynamic workflow orchestration
P1  Human intervention wall-clock time measurement
```

## 注意事項

- 現在は **Experiment Stage** のためbreaking changesが発生する可能性があります。
- Claude CodeとMoAI-ADKは現在の **reference implementation** であり、DHAAの必須構成要素ではありません。
- MoAI-ADKを含むorchestration frameworkも交換可能なimplementation/adapter layerとして扱うことを目指します。
- Application folderは独立したGit repositoryとして管理することを前提とします。

---

**DHAA is an experiment in making agentic software engineering workflows, memory, policy, and execution state portable across domains, harnesses, agents, and orchestration implementations.**