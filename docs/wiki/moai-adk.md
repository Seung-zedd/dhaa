# MoAI-ADK — 비교 기준

> 이 문서는 MoAI-ADK 사용 설명서가 아니라, **외부 프레임워크와 비교할 때 쓰는 기준선** 정리입니다.
> 상세 규칙의 정본은 `projects/CLAUDE.md`와 `.claude/rules/moai/`입니다.

작성일: 2026-07-29 · 근거: 세션에 로드된 CLAUDE.md, `.claude/rules/moai/**`, `development_pipeline_guideline.md`

---

## 1. 레이어 — 프로세스 / 거버넌스

MoAI-ADK가 최적화하는 대상은 **작업 방식의 정확성과 추적 가능성**입니다.
"무슨 도구를 쓰는가"(카탈로그)나 "도구가 어떻게 동작하는가"(런타임)는 Claude Code에 위임하고,
그 위에서 **일하는 순서와 증거 요구 수준**을 규칙으로 고정합니다.

한 문장 요약: **계약을 강제하는 시스템.**

---

## 2. 핵심 자산 — 다른 두 프레임워크에 없는 것

### SPEC 문서 생명주기

`spec.md` / `plan.md` / `acceptance.md` 3종 세트 + `spec-compact.md`.
EARS 형식 요구사항, REQ ID, HISTORY 기반 버전 범프.

`/moai plan` → `/moai run SPEC-XXX` → `/moai sync SPEC-XXX` 파이프라인이
문서 → 코드 → 문서 역동기화까지 한 바퀴를 닫습니다.

### 3단계 SPEC 리뷰 파이프라인

기계 검증과 판단 질문을 **절대 한 단계로 합치지 않는다**는 것이 설계 원칙입니다.

| 단계 | 담당 | 성격 |
|---|---|---|
| Stage 1 | plan-auditor | 기계 검증 — 답이 문서 안에 있음. 완전 자동화 |
| Stage 2 | spec-interrogator | 적대적 심문 — 판단 지점을 flag만 하고 **절대 답하지 않음** |
| Stage 3 | 오케스트레이터 | founder 확정 항목만 반영 (confirmed-only) |

게이트 규칙:
- founder 판정이 없는 항목은 Stage 3에서 손대지 않는다.
- Stage 2 flag 0건은 "통과"가 아니라 "이 모델이 놓쳤을 수 있음"으로 취급한다.

### 추적성 계층

- `@MX` 태그 — NOTE / WARN / ANCHOR / TODO. fan_in 3 이상 함수는 ANCHOR 필수.
- REQ ↔ 시나리오 커버리지 맵.
- codemaps 자동 생성.

### TRUST 5 + LSP 위상별 게이트

Tested(85%+) / Readable / Unified / Secured / Trackable.
위상별 LSP 임계치: run은 에러 0, sync는 경고 10 이하.

### 헌법 구조 (FROZEN / EVOLVABLE)

자기 수정 가능 영역과 불변 영역을 분리하고 5계층(Frozen Guard, Canary, 모순 탐지, 레이트 리미터, 인간 승인)으로 보호.
디자인 파이프라인의 GAN 루프에는 **평가자 관대화 방지 5종**(루브릭 앵커링, 회귀 베이스라인, must-pass 방화벽, 독립 재평가, 안티패턴 교차검증)이 별도로 걸려 있습니다.

### 상호작용 규율

- 사용자 질문은 전부 AskUserQuestion 경유 (자유 서술형 질문 금지).
- 서브에이전트는 사용자에게 질문할 수 없음 — 컨텍스트 부족 시 blocker 리포트 반환.
- Agent Core Behaviors 6종: 가정 표면화 / 혼란 능동 관리 / 근거 있는 반박 / 단순성 강제 / 스코프 규율 / 검증 후 보고.

---

## 3. 구조적 특징

| 항목 | 내용 |
|---|---|
| 배포 | Go 바이너리 `moai` + 템플릿 스캐폴딩 (`moai init`이 로컬 `.moai/`만 확보) |
| 상속 모델 | `CLAUDE.md`·`.claude/` 엔진은 상위 워크스페이스에서 상속, `.moai/`만 앱 로컬 |
| 커맨드 | Thin Command Pattern — 20 LOC 미만, 전부 `Skill("moai")`로 라우팅 |
| 컨텍스트 | Progressive Disclosure 3단계 (메타데이터 ~100토큰 / 본문 ~5K / 번들 온디맨드) |
| 병렬 | Agent Teams + worktree isolation. 역할별 HARD 룰로 강제 |
| 다중 모델 | CG 모드 — tmux 세션 env 격리로 리더는 Claude, 팀원은 GLM |

### 3.1 v3.x orchestration topology — loop보다 위의 graph 레이어

2026-09 교차 검증 기준으로, **현재 v3.x 템플릿에는 이미 "개별 에이전트 루프"보다 상위의 orchestration graph 개념이 실질적으로 들어와 있습니다.** 다만 외부 글에서 쓰는 `Splitter / Worker / Code node / Gate`, `correction edge / learning edge`라는 용어로 하나의 범용 graph protocol이 정식 모델링되어 있지는 않습니다.

핵심은 다음 두 축의 분리입니다.

- **Node 내부 loop**: 한 단위의 작업을 수행하고 검증하며 필요 시 다시 실행하는 수렴 루프.
- **Node 사이 graph**: 어떤 작업을 직렬/병렬/대규모 fan-out으로 배치할지, 어느 지점에서 human gate를 둘지, 어떤 검증 결과가 다음 단계 진입을 막을지 결정하는 orchestration topology.

현재 v3.x 템플릿의 직접 대응 요소:

| Graph 관점 | MoAI-ADK v3.x 대응 |
|---|---|
| 작업 분할 / 실행 shape 선택 | Phase 4 `direct / serial / fanout / sweep` mode-selection decision tree |
| 병렬 worker fan-out | `fanout`: multi-domain research/review에서 여러 `Agent()`를 한 턴에 병렬 spawn |
| 대규모 mechanical graph | `sweep`: uniform transform + no inter-file dependency 조건에서 workflow fan-out |
| deterministic code path | `/moai fix`, `/moai mx`, `/moai codemaps`, `/moai clean`의 agentless pipeline — LLM이 phase order를 결정하지 않음 |
| gate / verdict | plan-auditor, sync-auditor, audit gate, must-pass firewall, FAIL/INCONCLUSIVE 처리 |
| human gate | Implementation Kickoff Approval은 score와 무관하게 mandatory이며 fan-out/sweep가 우회할 수 없음 |
| scope preservation | out-of-scope untouched acceptance, bounded retry 및 SPEC scope 규율 |

특히 v3.x에서는 **"good loop on the wrong shape" 문제를 줄이기 위해 실행 shape를 먼저 분류**합니다. trivial은 `direct`, coding-heavy는 보수적으로 `serial`, multi-domain research-heavy는 `fanout`, 대규모 uniform mechanical transform만 `sweep`로 보내며, 경계에서는 더 단순한 모드를 우선합니다. 즉 병렬성 자체가 목적이 아니라 **dependency와 작업 성질에 맞는 graph shape 선택**이 목적입니다.

또한 agentless pipeline은 graph 안의 모든 node를 모델로 만들 필요가 없다는 원칙과 대응합니다. localize → repair → validate처럼 순서가 deterministic한 경우 LLM dispatcher를 쓰지 않고, Agent 호출이 있더라도 phase 내부 executor로만 제한합니다.

추가로 DHAA의 `feature/spec-review-authority-chain` 브랜치에는 **AI 판단의 authority / risk gate가 이미 별도 계층으로 설계되어 있습니다.** `decision-index`가 `Impact`와 `Reversibility`를 기록하고, `EASY_REVERSIBLE / COSTLY_REVERSIBLE / HARD_TO_REVERSE / UNKNOWN`으로 되돌림 비용을 분류하며, destructive/irreversible·costly-reversible·data migration·persistence/public API contract 같은 항목은 `FOUNDER` 또는 `EVIDENCE-NEEDED`에서 시작합니다. 불확실한 경우에는 `When uncertain, escalate. Never downgrade.` 원칙으로 보수적으로 인간 판정으로 올립니다.

또한 이전 founder verdict를 `DECIDED`, 명시적 PRD/ADR/engineering policy를 `POLICY-COVERED`로 재사용하므로, **governance-level learning / persistent authority reuse** 역시 이미 이 설계에 포함되어 있습니다. 따라서 외부 글의 `blast-radius gate`와 "확정된 판단을 다음 판단의 constraint로 재사용"하는 아이디어는 DHAA의 신규 공백으로 보지 않습니다.

`secure-file-upload`의 v3.x orchestration layer와 `feature/spec-review-authority-chain`의 AI 판정 layer를 제외하고 남는 공백은 **execution graph 자체의 feedback-edge protocol**입니다.

1. **Execution-level correction edge** — 실패한 `UNIT` 하나만 `{VERDICT, REASON, EVIDENCE, SCOPE}` 같은 구조화된 failure context와 함께 producer node로 반환하고, 전체 batch가 아니라 해당 unit만 scoped retry하는 공통 계약.
2. **Execution-level learning edge** — accepted runtime result에서 확인된 원인/constraint를 다음 실행의 splitter/planner로 되돌려 graph shape 또는 작업 분해에 반영하는 공통 계약. 이는 founder verdict를 영속화하는 governance-level learning과 다른 runtime orchestration 문제입니다.

즉 **graph topology / fan-out / deterministic node / mandatory human gate는 v3.x가 이미 흡수했고, reversibility 기반 AI 판정 / persistent decision authority는 `feature/spec-review-authority-chain`이 이미 흡수했습니다. 현재 비교에서 남는 신규 축은 runtime execution feedback edge의 일반화**입니다.

참고로 `secure-file-upload`는 v3.x 템플릿의 `orchestration-mode-selection.md`와 dynamic workflow 계층을 실제 스캐폴딩 결과로 보존하고 있습니다. 반면 `pillwriter`는 바이너리는 v3.x 계열이지만 템플릿이 v2.x 계열이라 동일한 `orchestration-mode-selection.md` 파일이 존재하지 않아, 현재 구조 차이를 확인하는 legacy baseline 역할을 합니다. PillWriter에서 발전시킨 AI 판단 설계의 domain-agnostic 형태는 DHAA `feature/spec-review-authority-chain` 브랜치에 보존되어 있습니다.

---

## 4. 외부 조사로 드러난 공백

세 프레임워크와 위의 DHAA 실험 브랜치를 비교한 결과, **아직 별도 검토 가치가 있는 축**은 다음과 같습니다.

| 공백 | 설명 | 참고 출처 |
|---|---|---|
| 에이전트 설정 보안 | `expert-security`는 앱 코드를 본다. `.claude/settings.json`·훅·MCP 설정 자체를 감사하는 축이 없음 | [ECC — AgentShield](ecc.md) |
| 모델 선택 자동화 | 서브에이전트 스폰 시 모델 지정이 오케스트레이터 수동 판단에 의존 | [OmO — 카테고리 라우팅](oh-my-openagent.md) |
| 학습 메모리의 신뢰도 | Lessons Protocol은 키워드 매칭 + 최근성. 신뢰도 임계치·주입 개수 상한 없음 | [ECC — Instinct](ecc.md) |
| 프롬프트 인젝션 방어 | CLAUDE.md에 방어 베이스라인 블록이 없음 | [ECC](ecc.md) |
| 컨텍스트 계층화 | 단일 CLAUDE.md 로드. 디렉토리별 컨텍스트 분할 개념 없음 | [OmO — `/init-deep`](oh-my-openagent.md) |
| MCP 수명 관리 | `.mcp.json` 상시 등록 → 컨텍스트 비용 항상 지불 | [OmO — 스킬 임베디드 MCP](oh-my-openagent.md) |
| 단일 하네스 종속 | Claude Code 전용 (+ GLM CG 모드) | [ECC](ecc.md), [OmO](oh-my-openagent.md) |
| execution feedback-edge protocol | failed unit scoped retry와 accepted runtime result → upstream execution constraint를 공통 graph contract로 정형화한 SSOT는 확인되지 않음. authority/reversibility 판단과 persistent founder decision reuse는 `feature/spec-review-authority-chain`에서 별도 해결됨 | 외부 agent graph pattern 교차 검증 |

---

## 5. 판단

공백은 있지만 **교체 사유는 아닙니다.**

ECC와 OmO 어느 쪽으로 가도 SPEC 문서 생명주기·추적성·리뷰 파이프라인을 통째로 잃습니다.
PillWriter는 SPEC 문서 세트가 자산인 프로젝트이므로 그 손실이 이득보다 큽니다.

올바른 방향은 **레이어별 부분 이식**입니다. 우선순위는 [README.md](README.md)의 이식 후보 표를 참조하십시오.
