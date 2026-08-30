# DHAA

> **Experiment Stage**  
> DHAA는 현재 개념과 구조를 검증하는 실험 단계입니다. 인터페이스, 디렉토리 구조, 지원 harness 및 agent 구성은 실험 결과에 따라 변경될 수 있습니다.

**DHAA = Domain, Harness & Agent-Agnostic**

특정 애플리케이션 도메인, 특정 AI coding harness, 특정 agent 구현에 종속되지 않는 **agentic engineering workspace architecture**를 지향합니다.

현재 레퍼런스 구현은 **Claude Code + MoAI-ADK** 조합을 사용하지만, DHAA의 목표는 이 구현 자체를 표준으로 고정하는 것이 아니라 개발 워크플로우와 운영 규칙을 상위 레이어로 분리해 다른 domain, harness, agent 조합으로도 재사용할 수 있게 만드는 것입니다.

## 목표

DHAA는 다음 세 가지 결합을 느슨하게 만드는 것을 목표로 합니다.

- **Domain-agnostic** — PillWriter 같은 특정 제품이나 SaaS, XR, backend 등 하나의 문제 도메인에 종속되지 않음
- **Harness-agnostic** — Claude Code에 고정되지 않고 다른 coding-agent harness로 교체 가능하도록 구조화
- **Agent-agnostic** — 특정 planner, reviewer, worker agent나 특정 모델 구현에 종속되지 않도록 역할과 규칙을 분리

현재 구현에서는 아직 Claude Code와 MoAI-ADK에 대한 결합이 존재합니다. 따라서 이 저장소는 완성된 agnostic framework가 아니라, 그 방향으로 구조를 일반화하고 결합도를 낮추는 과정을 검증하기 위한 **reference experiment**에 가깝습니다.

## 현재 구현: 2-레이어 상속 모델

현재 실험 환경에서는 Claude Code와 MoAI-ADK를 이용해 다음과 같은 2-layer workspace 모델을 사용합니다.

| 레이어 | 상속 여부 | 내용 |
|--------|-----------|------|
| **Claude Code 레이어** | ✅ 하위 폴더로 자동 상속 | `CLAUDE.md`, `.claude/`(agents/skills/rules/hooks/commands), `/moai` 슬래시 명령 |
| **`moai` 바이너리 레이어** | ❌ 로컬 `.moai/`만 인식 | `moai status`/`loop`/`fix`/quality gate — 앱마다 로컬 `.moai/` 필요 |

- Claude Code는 디렉토리 트리를 **위로 탐색**하므로, 앱 하위 폴더에서 세션을 열면 이 workspace의 agentic engine 구성을 상속받습니다.
- `moai` 바이너리는 상위 `.moai/`를 상속하지 않으므로 앱마다 `moai init`으로 로컬 `.moai/`를 확보합니다.
- 이 구조를 이용해 앱마다 동일한 `CLAUDE.md`, agents, skills, rules를 중복 보유하면서 발생하는 context bloat을 줄이는 것을 실험하고 있습니다.

## 레포 구성

```text
projects/                        ← DHAA workspace
├── CLAUDE.md                    # 현재 reference orchestrator instructions
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

도메인 앱과 로컬 runtime state(`.moai/reports|state|plans`, `.claude/tmp` 등)는 이 workspace repository에서 분리합니다.

## 클론 후 셋업

### 0. 사전 요구사항

현재 reference implementation 기준 요구사항입니다.

- **Git** + **Git Bash** (Windows — hook scripts)
- **Node.js** (LTS)
- **pnpm**
- **gh CLI**
- **moai binary** (MoAI-ADK)
- **Claude Code CLI**

향후 harness abstraction이 진행되면 이 요구사항은 implementation-specific 문서로 분리할 예정입니다.

### 1. 클론

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

### 2. MCP 서버 설정

현재 reference environment에서 사용하는 MCP 구성입니다.

| 서버 | 스코프 | 전송 | 용도 | 설치 / 인증 |
|------|--------|------|------|-------------|
| **github** | project (`.mcp.json`) | HTTP (readonly) | repo/issue/PR read | `${GITHUB_PERSONAL_ACCESS_TOKEN}` 환경변수 |
| **context7** | user | HTTP | 최신 라이브러리 문서 조회 | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` |
| **serena** | user | stdio | LSP symbol search/edit | `uvx` 기반 설치 |
| **headroom** | user | stdio | context compression | `headroom mcp serve` |
| **pencil** | user | stdio | UI design(.pen) editing | local desktop executable |
| **vercel** | plugin | HTTP | deployment/docs | Claude Code plugin |
| **claude.ai connectors** | account | HTTP | Google/Linear integration | `/mcp` authentication |

stdio 서버의 실행 경로는 머신마다 다를 수 있습니다.

### 3. `.claude/settings.json`의 `env.PATH` 수정

현재 reference implementation에는 머신 종속 경로가 포함될 수 있습니다. 클론한 환경에 맞게 다음 경로를 수정해야 합니다.

- Node.js installation path
- npm global path
- moai installation path

설정 후 세션을 재시작합니다.

### 4. 동작 확인

```bash
claude   # 또는 moai cc
```

현재 구현에서는 다음을 확인합니다.

- ccstatusline 정상 표시
- `/moai` slash command 인식
- workspace-level instructions/skills/rules 상속 여부

## 새 도메인 앱 추가

> 현재 Claude Code + MoAI-ADK reference implementation 기준입니다.

```bash
# 1) local .moai/ 확보
moai init my-new-app
cd my-new-app

# 2) 상위 workspace에서 상속되는 중복 구성 제거
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles

# 현재 구현에서는 hooks/settings 등 local runtime-dependent files는 유지

# 3) session start
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

이 workflow 역시 DHAA의 불변 API가 아니라 **현재 실험 중인 reference workflow**입니다.

## Experiment Roadmap

현재 DHAA에서 검증하려는 핵심 질문은 다음과 같습니다.

1. Domain-specific context를 workspace engine과 얼마나 명확하게 분리할 수 있는가?
2. Claude Code-specific instructions를 다른 harness에서도 재사용 가능한 형태로 추상화할 수 있는가?
3. Planner, reviewer, worker 같은 agent role을 특정 모델이나 agent implementation과 분리할 수 있는가?
4. SPEC, test, review, sync와 같은 engineering lifecycle을 harness-independent contract로 정의할 수 있는가?
5. 이러한 추상화가 context bloat이나 orchestration complexity를 실제로 줄이는가?

이 질문들이 충분히 검증되기 전까지 DHAA의 구조와 명칭은 안정된 public API로 간주하지 않습니다.

## 주의사항

- 현재는 **Experiment Stage**이므로 breaking changes가 발생할 수 있습니다.
- Claude Code와 MoAI-ADK는 현재의 **reference implementation**이며 DHAA의 필수 구성요소로 확정된 것이 아닙니다.
- `moai update` 등 implementation-specific 명령은 현재 reference environment의 동작 방식에 따릅니다.
- 앱 폴더는 각자 독립 Git repository로 관리하는 것을 전제로 합니다.
- 패키지 설치 전 `pkg-supply-chain-check.sh`를 이용해 공급망 검사를 수행할 수 있습니다.

---

**DHAA is an experiment in separating agentic engineering workflows from the domain, harness, and agent implementations that execute them.**
