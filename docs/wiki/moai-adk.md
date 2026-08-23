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

---

## 4. 외부 조사로 드러난 공백

세 프레임워크를 비교한 결과, MoAI-ADK에 **구조적으로 비어 있는 축**은 다음과 같습니다.

| 공백 | 설명 | 참고 출처 |
|---|---|---|
| 에이전트 설정 보안 | `expert-security`는 앱 코드를 본다. `.claude/settings.json`·훅·MCP 설정 자체를 감사하는 축이 없음 | [ECC — AgentShield](ecc.md) |
| 모델 선택 자동화 | 서브에이전트 스폰 시 모델 지정이 오케스트레이터 수동 판단에 의존 | [OmO — 카테고리 라우팅](oh-my-openagent.md) |
| 학습 메모리의 신뢰도 | Lessons Protocol은 키워드 매칭 + 최근성. 신뢰도 임계치·주입 개수 상한 없음 | [ECC — Instinct](ecc.md) |
| 프롬프트 인젝션 방어 | CLAUDE.md에 방어 베이스라인 블록이 없음 | [ECC](ecc.md) |
| 컨텍스트 계층화 | 단일 CLAUDE.md 로드. 디렉토리별 컨텍스트 분할 개념 없음 | [OmO — `/init-deep`](oh-my-openagent.md) |
| MCP 수명 관리 | `.mcp.json` 상시 등록 → 컨텍스트 비용 항상 지불 | [OmO — 스킬 임베디드 MCP](oh-my-openagent.md) |
| 단일 하네스 종속 | Claude Code 전용 (+ GLM CG 모드) | [ECC](ecc.md), [OmO](oh-my-openagent.md) |

---

## 5. 판단

공백은 있지만 **교체 사유는 아닙니다.**

ECC와 OmO 어느 쪽으로 가도 SPEC 문서 생명주기·추적성·리뷰 파이프라인을 통째로 잃습니다.
PillWriter는 SPEC 문서 세트가 자산인 프로젝트이므로 그 손실이 이득보다 큽니다.

올바른 방향은 **레이어별 부분 이식**입니다. 우선순위는 [README.md](README.md)의 이식 후보 표를 참조하십시오.
