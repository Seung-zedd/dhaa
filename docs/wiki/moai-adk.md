# MoAI-ADK — 비교 기준

> 이 문서는 MoAI-ADK 사용 설명서가 아니라, **외부 프레임워크와 비교할 때 쓰는 기준선** 정리입니다.
> 상세 규칙의 정본은 `projects/CLAUDE.md`와 `.claude/rules/moai/`입니다.

작성일: 2026-07-29 · 2026-09 최신 교차검증: MoAI-ADK v3.x, `secure-file-upload`, DHAA `feature/spec-review-authority-chain`, PillWriter `main`

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
| Stage 2 | spec-interrogator | 적대적 심문 — 판단 지점을 flag하되 답을 대신 내리지 않음 |
| Stage 3 | 오케스트레이터 | founder 확정 항목만 반영 (confirmed-only) |

게이트 규칙:
- founder 판정이 필요한 항목은 founder verdict 없이 Stage 3에서 손대지 않는다.
- Stage 2 flag 0건은 "통과"가 아니라 "이 모델이 놓쳤을 수 있음"으로 취급한다.
- 최신 PillWriter `main`에서는 Stage 2의 불확실성을 다시 **empirical / normative / engineering / mixed**로 분류하고, 측정으로 답할 수 있는 사실 질문은 founder interview가 아니라 evidence route로 보낸다.

### 최신 PillWriter `main`의 SPEC review 확장 — evidence-first class gate

PillWriter의 현재 `main`은 DHAA `feature/spec-review-authority-chain`에 보존된 초기 domain-agnostic authority 설계보다 한 단계 더 발전했습니다. 2026-09-06 기준 커밋 `e5c077d`에서 `spec-review-authority` §5.6, `review-index-lint`, `spec-interrogator` class hint가 추가되어 **"문서 밖의 답"을 founder 판단과 empirical fact로 다시 분리**합니다.

핵심 추가점:

| 최신 PillWriter `main` | 의미 |
|---|---|
| `EMPIRICAL / NORMATIVE / ENGINEERING / MIXED` class hint | Stage 2가 발견한 불확실성의 성질을 먼저 분류 |
| `EVIDENCE-RESOLVED` | 실제 데이터·probe·test가 empirical question을 이미 답하면 founder에게 묻지 않음 |
| `ENGINEERING-RESOLVED` | product/UX/contract semantics 영향이 없는 순수 구현 선택을 기존 architecture·convention·engineering evidence로 해소 |
| `IMPLEMENTATION-GAP` | evidence가 normative requirement와 충돌하면 requirement를 자동 변경하지 않고 engineering investigation으로 라우팅 |
| `class-gate` | evidence가 답할 문제를 founder decision으로 잘못 승격시키는 것을 방지 |
| `review-index-lint.js` | resolved class가 interview queue로 회귀하지 않는지 review artifact를 기계적으로 검증 |

여기서 중요한 경계는 **"Evidence has authority over facts, never over requirements"**입니다. 측정은 현실이 무엇인지 닫을 수 있지만 제품이 무엇을 해야 하는지는 정하지 않습니다. 즉 evidence-first routing은 AI에게 제품 결정권을 주는 자동판정이 아니라, **사실 문제를 evidence로 닫아 founder의 판단 예산을 normative decision에만 쓰도록 하는 authority-preserving gate**입니다.

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

### 3.2 세 저장소가 현재 흡수한 레이어

현재 비교에서는 세 구현을 같은 것으로 보지 않고 **서로 다른 레이어의 증거**로 사용합니다.

| Source | 현재 역할 | 이미 흡수된 것 |
|---|---|---|
| `secure-file-upload` | MoAI v3.x **execution topology baseline** | `direct / serial / fanout / sweep`, dynamic workflow, deterministic agentless path, mandatory human gate |
| DHAA `feature/spec-review-authority-chain` | **domain-agnostic decision-authority baseline** | `DECIDED / POLICY-COVERED / EVIDENCE-NEEDED / FOUNDER`, Impact/Reversibility, conservative escalation, founder verdict persistence |
| PillWriter `main` | **latest evolved SPEC-review implementation** | empirical-vs-normative separation, `EVIDENCE-RESOLVED`, `ENGINEERING-RESOLVED`, `IMPLEMENTATION-GAP`, `class-gate`, review-index lint |

이 구분 때문에 PillWriter를 단순히 "v2.x legacy baseline"이라고만 부르는 것은 이제 부정확합니다. **MoAI template topology 관점에서는 legacy baseline**이 맞지만, **local SPEC-review governance 관점에서는 오히려 가장 최신 구현**입니다.

DHAA authority-chain이 이미 `Impact`와 `Reversibility`를 기록하고, `EASY_REVERSIBLE / COSTLY_REVERSIBLE / HARD_TO_REVERSE / UNKNOWN`으로 되돌림 비용을 분류하며, destructive/irreversible·costly-reversible·data migration·persistence/public API contract 같은 항목을 `FOUNDER` 또는 `EVIDENCE-NEEDED`에서 시작시키므로, 외부 글의 risk/blast-radius 아이디어 중 **decision governance 층**은 이미 상당 부분 흡수되어 있습니다. 불확실한 경우에는 `When uncertain, escalate. Never downgrade.` 원칙으로 인간 판정으로 올립니다.

또한 이전 founder verdict를 `DECIDED`, 명시적 PRD/ADR/engineering policy를 `POLICY-COVERED`로 재사용하므로 **governance-level learning / persistent authority reuse**도 이미 해결되어 있습니다. 여기에 최신 PillWriter `main`은 empirical fact를 evidence로 닫고 engineering-only question을 founder interview에서 제거하는 class gate까지 추가했습니다.

따라서 이제 제외해야 할 영역은 세 묶음입니다.

1. `secure-file-upload` / MoAI v3.x가 이미 가진 **execution graph topology**
2. DHAA authority-chain이 이미 가진 **reversibility / authority / persistent founder-decision governance**
3. PillWriter `main`이 이미 가진 **evidence-first SPEC triage / engineering resolution / implementation-gap routing**

이 셋을 제외하고 남는 공백은 **execution graph 자체의 feedback-edge protocol**입니다.

1. **Execution-level correction edge** — 실패한 `UNIT` 하나만 `{VERDICT, REASON, EVIDENCE, SCOPE}` 같은 구조화된 failure context와 함께 producer node로 반환하고, 전체 batch가 아니라 해당 unit만 scoped retry하는 공통 계약.
2. **Execution-level learning edge** — accepted runtime result에서 확인된 원인/constraint를 다음 실행의 splitter/planner로 되돌려 graph shape 또는 작업 분해에 반영하는 공통 계약.

두 번째는 특히 PillWriter의 evidence-first class gate와 구분해야 합니다. PillWriter는 **"이 질문을 누가/무엇이 답할 권한이 있는가"**를 정교하게 라우팅하지만, 확인된 runtime evidence를 **다음 run의 splitter/planner constraint로 자동 승격하여 execution topology 자체를 바꾸는 공통 protocol**까지 정의한 것은 아닙니다. 마찬가지로 `IMPLEMENTATION-GAP`은 engineering investigation으로 보내는 governance route이지, failed execution unit을 producer node로 되돌리는 graph edge contract 자체는 아닙니다.

즉 현재 최신 교차검증 기준으로 **graph topology + human gate는 MoAI v3/secure-file-upload, decision authority + reversibility는 DHAA authority-chain, evidence-first SPEC resolution은 PillWriter main이 이미 흡수**했습니다. 남는 신규 축은 runtime execution feedback edge의 일반화입니다.

---

## 4. 외부 조사로 드러난 공백

MoAI v3.x, `secure-file-upload`, DHAA authority-chain, 최신 PillWriter `main`까지 교차 검증한 결과, **아직 별도 검토 가치가 있는 축**은 다음과 같습니다.

| 공백 | 설명 | 참고 출처 |
|---|---|---|
| 에이전트 설정 보안 | `expert-security`는 앱 코드를 본다. `.claude/settings.json`·훅·MCP 설정 자체를 감사하는 축이 없음 | [ECC — AgentShield](ecc.md) |
| 모델 선택 자동화 | 서브에이전트 스폰 시 모델 지정이 오케스트레이터 수동 판단에 의존 | [OmO — 카테고리 라우팅](oh-my-openagent.md) |
| 학습 메모리의 신뢰도 | Lessons Protocol은 키워드 매칭 + 최근성. 신뢰도 임계치·주입 개수 상한 없음 | [ECC — Instinct](ecc.md) |
| 프롬프트 인젝션 방어 | CLAUDE.md에 방어 베이스라인 블록이 없음 | [ECC](ecc.md) |
| 컨텍스트 계층화 | 단일 CLAUDE.md 로드. 디렉토리별 컨텍스트 분할 개념 없음 | [OmO — `/init-deep`](oh-my-openagent.md) |
| MCP 수명 관리 | `.mcp.json` 상시 등록 → 컨텍스트 비용 항상 지불 | [OmO — 스킬 임베디드 MCP](oh-my-openagent.md) |
| 단일 하네스 종속 | Claude Code 전용 (+ GLM CG 모드) | [ECC](ecc.md), [OmO](oh-my-openagent.md) |
| execution feedback-edge protocol | failed `UNIT` scoped retry와 accepted runtime result → reusable splitter/planner constraint를 공통 graph contract로 정형화한 SSOT는 확인되지 않음. authority/reversibility는 DHAA authority-chain, evidence/engineering resolution은 PillWriter `main`에서 별도 해결됨 | 외부 agent graph pattern 교차 검증 |

---

## 5. 판단

공백은 있지만 **교체 사유는 아닙니다.**

ECC와 OmO 어느 쪽으로 가도 SPEC 문서 생명주기·추적성·리뷰 파이프라인을 통째로 잃습니다.
PillWriter는 SPEC 문서 세트와 그 위에 발전시킨 evidence-first review governance가 자산인 프로젝트이므로 그 손실이 이득보다 큽니다.

올바른 방향은 **레이어별 부분 이식**입니다. 현재 agent-graph 관점의 신규 검토 대상은 이미 흡수된 topology/authority/class-gate를 재구현하는 것이 아니라, **execution-level correction edge와 learning edge를 공통 protocol로 만들 가치가 있는지** 검증하는 것입니다. 우선순위는 [README.md](README.md)의 이식 후보 표를 참조하십시오.
