# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

### 특정 Domain? **다** 상관없음.
### Claude Code냐 Codex냐? **다** 상관없음.
### 어떤 Agent냐? **다** 상관없음.

**DHAA — Domain, Harness & Agent-Agnostic**

> **🚧 Experiment Stage**  
> DHAA는 현재 domain, harness, agent로부터 **agentic software engineering workflow와 context ownership을 얼마나 분리할 수 있는지** 검증하는 실험 프로젝트입니다. 인터페이스, 디렉토리 구조, 지원 harness 및 agent 구성은 실험 결과에 따라 변경될 수 있습니다.

특정 애플리케이션 도메인, 특정 AI coding harness, 특정 agent 구현에 종속되지 않는 **agentic engineering control plane / workspace architecture**를 지향합니다.

현재 레퍼런스 구현은 **Claude Code + MoAI-ADK** 조합에서 출발했지만, DHAA의 목표는 이 조합 자체를 표준으로 고정하는 것이 아닙니다. Claude Code, Codex, OpenCode 같은 coding harness뿐 아니라 MoAI-ADK 같은 orchestration framework 역시 **교체 가능한 구현체**로 취급하고, 개발 워크플로우와 운영 규칙, 메모리, 실행 상태를 그보다 상위 레이어로 끌어올리는 것을 목표로 합니다.

## 왜 필요한가?

Agentic development workflow가 특정 벤더나 특정 harness의 세션에 강하게 결합되어 있으면, 외부 장애가 그대로 개발 중단으로 전파됩니다.

예를 들어 특정 LLM API에서 `529`, `429`, timeout 같은 일시적 또는 지속적 장애가 발생했을 때, 단순히 모델 호출만 실패하는 것이 아니라 다음 항목까지 함께 묶여 있다면 개발자는 해당 벤더가 복구될 때까지 작업을 이어가기 어렵습니다.

- 현재 목표와 실행 중인 task
- 완료/미완료 작업 상태
- session memory
- `CLAUDE.md`, `AGENTS.md` 같은 governing instructions
- planner/reviewer/worker 역할 정의
- SPEC, test, review, sync 같은 engineering lifecycle

DHAA는 provider outage 자체를 제거하려는 프로젝트가 아닙니다. 대신 **외부 장애가 workflow outage로 확장되는 범위를 줄이는 것**을 목표로 합니다.

> **DHAA does not prevent provider outages; it aims to prevent provider outages from becoming workflow outages.**

## 목표

DHAA는 다음 결합을 느슨하게 만드는 것을 목표로 합니다.

- **Domain-agnostic** — 특정 제품이나 SaaS, XR, backend 등 하나의 문제 도메인에 종속되지 않음
- **Harness-agnostic** — Claude Code, Codex, OpenCode 등 특정 coding harness에 고정되지 않음
- **Agent-agnostic** — 특정 planner, reviewer, worker agent나 특정 모델 구현에 종속되지 않음
- **Orchestration-agnostic** — MoAI-ADK를 포함한 특정 orchestration framework나 lifecycle implementation에 고정되지 않음
- **Context-portable** — constitution, durable memory, execution state, handoff state를 특정 세션이나 harness 밖에서 보존하고 다른 실행 경로로 전달 가능하게 함

현재 구현에서는 아직 Claude Code와 MoAI-ADK에 대한 결합이 존재합니다. 따라서 이 저장소는 완성된 agnostic framework가 아니라, 그 방향으로 구조를 일반화하고 결합도를 낮추는 과정을 검증하기 위한 **reference experiment**입니다.

## 핵심 아이디어: Workflow와 Context의 소유권을 분리하기

DHAA가 지향하는 방향에서는 특정 벤더 세션이 작업 상태의 원본이 되어서는 안 됩니다.

```text
Vendor / Harness Session
        ↓
   transient executor
        ↓
DHAA-owned workflow state
```

즉, Claude Code나 Codex 같은 harness는 개발 세션의 주인이 아니라 **현재 workflow를 실행하는 executor**에 가깝게 취급합니다.

### Portable Context / Continuity Bundle

```text
DHAA Continuity Bundle
├── Constitution
│   ├── governing rules
│   ├── engineering principles
│   └── harness-specific projection (e.g. CLAUDE.md, AGENTS.md)
│
├── Durable Memory
│   ├── project decisions
│   ├── learned constraints
│   └── long-lived context
│
├── Execution State
│   ├── active goal
│   ├── current lifecycle phase
│   ├── completed / pending tasks
│   ├── observations
│   └── test / git state
│
└── Session Handoff
    ├── latest summary
    ├── unresolved questions
    ├── important tool outputs
    └── continuation instructions
```

`CLAUDE.md`나 `AGENTS.md` 자체를 canonical format으로 고정하는 대신, 더 상위의 constitution을 두고 각 harness adapter가 자신의 형식으로 투영하는 방식을 실험합니다.

```text
DHAA Constitution
    ├── Claude adapter → CLAUDE.md
    ├── Codex adapter  → AGENTS.md
    └── Other adapter  → harness-specific instructions
```

이를 통해 harness가 바뀌더라도 다음 세 가지 continuity를 유지하는 것을 목표로 합니다.

1. **Task continuity** — 무엇을 하다가 끊겼는가?
2. **Memory continuity** — 무엇을 이미 학습하고 결정했는가?
3. **Policy continuity** — 어떤 규칙과 원칙으로 작업해야 하는가?

## 장애 대응 실험

```text
529 / 429 / timeout
        ↓
transient failure 판단
        ↓
exponential backoff + jitter
        ↓
retry budget 초과
        ↓
checkpoint current state
        ↓
failover decision
        ↓
alternate provider or harness
        ↓
rehydrate context and resume
```

지수 백오프는 일시적인 overload를 흡수하기 위한 첫 번째 방어선이며, 지속적인 장애까지 무한 재시도하는 대신 retry budget과 failover policy를 함께 두는 방향을 실험합니다.

> **Retry transient failures, isolate persistent failures, preserve state, then fail over.**

## Branch Strategy

DHAA의 Git branch도 같은 abstraction 원칙을 따릅니다.

Git branch 자체에는 실제 부모-자식 계층이 없으므로 `/` 기반 naming convention을 이용해 논리적인 분류를 표현합니다.

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

핵심 원칙은 다음과 같습니다.

> **main = agnostic truth, `*-specific` branches = implementation experiments.**

- `main`에는 harness/vendor에 종속되지 않는 canonical contract, architecture, invariant를 둡니다.
- `feature/core/*`에서는 continuity bundle, lifecycle contract처럼 DHAA 자체의 portable abstraction을 실험합니다.
- `feature/claude-specific/*`, `feature/codex-specific/*` 등에서는 각 harness에 최적화된 adapter와 integration을 실험합니다.
- Claude-specific 구현과 Codex-specific 구현은 서로 동일할 필요가 없습니다. **구현 방식은 달라도 DHAA-level contract와 continuity invariant를 만족하면 됩니다.**
- 특정 harness에서 검증된 구현을 다른 harness에 기계적으로 복제하지 않고, 각 harness의 native capability를 최대한 활용합니다.

```text
                 DHAA Contract
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Claude-native adapter    Codex-native adapter
          │                       │
          └──── same contract ────┘
```

기존 feature branch에 남아 있는 Claude-specific 구현은 바로 제거하지 않고, 향후 PR 시점에 이 기준으로 portable core와 harness-specific adapter를 분리합니다.

## 현재 reference implementation

현재 실험 환경은 여전히 **Claude Code + MoAI-ADK**를 사용합니다. 다만 이 조합은 DHAA의 최종 architecture가 아니라, abstraction boundary를 검증하기 위한 첫 번째 reference implementation입니다.

### 현재 2-layer workspace 모델

| 레이어 | 상속 여부 | 내용 |
|--------|-----------|------|
| **Claude Code 레이어** | ✅ 하위 폴더로 자동 상속 | `CLAUDE.md`, `.claude/`(agents/skills/rules/hooks/commands), `/moai` 슬래시 명령 |
| **`moai` 바이너리 레이어** | ❌ 로컬 `.moai/`만 인식 | `moai status`/`loop`/`fix`/quality gate — 앱마다 로컬 `.moai/` 필요 |

이 구조 자체도 향후 Claude Code / MoAI-ADK implementation detail로 격리하고, DHAA-level contract와 adapter layer를 별도로 정의할 예정입니다.

## 레포 구성

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

향후에는 다음과 같은 DHAA-owned 영역을 분리하는 방향을 실험할 예정입니다.

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

위 구조와 파일명은 아직 확정된 public API가 아니라 **design direction**입니다.

## 클론 후 셋업

현재 reference implementation 기준 요구사항입니다.

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

현재 reference environment에는 Claude Code와 MoAI-ADK 전용 설정이 포함되어 있으며, 향후 abstraction이 진행되면 implementation-specific 문서로 분리할 예정입니다.

## 새 도메인 앱 추가

> 현재 Claude Code + MoAI-ADK reference implementation 기준입니다.

```bash
moai init my-new-app
cd my-new-app
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles
moai cc
```

현재 MoAI workflow 예시:

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

이 workflow는 DHAA의 불변 API가 아니라 **현재 실험 중인 하나의 orchestration reference**입니다.

## Experiment Roadmap

1. Domain-specific context를 workspace/control-plane과 얼마나 명확하게 분리할 수 있는가?
2. `CLAUDE.md`, `AGENTS.md` 같은 harness-specific instruction format 위에 portable constitution을 정의할 수 있는가?
3. Durable memory와 session handoff를 특정 vendor session 밖으로 옮길 수 있는가?
4. Planner, reviewer, worker 같은 agent role을 특정 모델이나 agent implementation과 분리할 수 있는가?
5. MoAI-ADK 같은 orchestration framework 없이도 SPEC, plan, run, test, review, sync lifecycle을 독립 contract로 정의할 수 있는가?
6. Provider 장애 시 exponential backoff와 retry budget을 적용하고, 지속적인 장애에서는 state를 보존한 채 다른 provider 또는 harness로 전환할 수 있는가?
7. Harness 전환 후에도 task, memory, policy continuity를 유지할 수 있는가?
8. 이러한 추상화가 context bloat, orchestration complexity, human intervention wall-clock time을 실제로 줄이는가?

```text
P0  Portable constitution / memory / execution state
P0  Harness adapter boundary
P0  Failure detection + retry/backoff + failover
P1  Harness-independent engineering lifecycle
P1  Dynamic workflow orchestration
P1  Human intervention wall-clock time measurement
```

## 주의사항

- 현재는 **Experiment Stage**이므로 breaking changes가 발생할 수 있습니다.
- Claude Code와 MoAI-ADK는 현재의 **reference implementation**이며 DHAA의 필수 구성요소가 아닙니다.
- MoAI-ADK를 포함한 orchestration framework 역시 향후 adapter 또는 implementation layer로 격리하는 것을 목표로 합니다.
- 앱 폴더는 각자 독립 Git repository로 관리하는 것을 전제로 합니다.

---

**DHAA is an experiment in making agentic software engineering workflows, memory, policy, and execution state portable across domains, harnesses, agents, and orchestration implementations.**