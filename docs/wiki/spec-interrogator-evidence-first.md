# SPEC Interrogator의 Evidence-first 판정 모델

> 상태: Design Note / Proposed
> 목적: SPEC 검토 과정에서 실기기 측정·테스트로 이미 답할 수 있는 질문이 founder에게 반복적으로 escalation되는 병목을 제거한다.

## 1. 문제 정의

현재 `spec-interrogator`의 핵심 구분은 다음과 같다.

- 문서 내부에서 객관적으로 답을 찾을 수 있는 문제 → mechanical defect
- 문서 바깥의 제품 의도·우선순위·trade-off가 필요한 문제 → founder judgment point

이 구분 자체는 유효하다. 문제는 **"문서 바깥"을 곧바로 "founder만 답할 수 있음"으로 해석할 때** 발생한다.

실제 개발에서는 문서 바깥에 다음과 같은 제3의 authority가 존재한다.

- 실기기 probe
- 자동/수동 테스트 결과
- 로그와 telemetry
- OS / SDK / API의 실제 동작
- 재현 가능한 benchmark

이러한 evidence가 이미 답을 제공했는데도 SPEC contract가 해당 값을 명시적으로 고정하지 않았다는 이유로 founder에게 다시 질문하면, 인간은 제품 판단이 아니라 **측정 결과를 재승인하는 승인 봇**이 된다.

핵심 병목은 다음과 같다.

```text
SPEC에 명시 없음
    ↓
"문서 밖의 답"으로 분류
    ↓
Founder Interview 생성
```

원하는 흐름은 다음과 같다.

```text
SPEC에 명시 없음
    ↓
이 질문의 authority는 누구인가?
    ├─ empirical fact → Probe / Test / Platform Evidence
    ├─ product intent → PRD
    ├─ implementation detail → Engineering convention / architecture
    └─ 위 셋으로 해결 불가한 제품 판단 → Founder
```

## 2. 핵심 원칙

> **Evidence가 답할 수 있는 질문을 Founder에게 묻지 않는다.**

Founder Interview는 정보 수집의 기본 루프가 아니라, **증거와 기존 문서만으로 해결할 수 없는 제품 정책 결정의 escalation path**여야 한다.

이를 한 문장으로 정리하면 다음과 같다.

> **인터뷰는 정보 수집 루프가 아니라 정책 결정 루프다.**

## 3. Authority 분리

| Authority | 책임 |
|---|---|
| PRD | 제품 의도, UX 정책, acceptance target |
| Probe / Test / Platform Evidence | 실제 동작과 경험적 사실 |
| SPEC | 구현해야 할 observable contract |
| Engineering conventions / architecture | 제품 의미를 바꾸지 않는 구현 선택 |
| Founder | 위 authority들로 해결되지 않는 제품 trade-off와 정책 판단 |

여기서 중요한 점은 `Measured Reality > PRD`가 아니라는 것이다.

예를 들어 PRD가 60 FPS를 요구하지만 실기기 probe가 52 FPS를 측정했다면:

```text
52 FPS를 새 SPEC으로 채택  ❌
현재 구현이 60 FPS requirement를 만족하지 못했다는 evidence  ✅
```

즉 **normative requirement**와 **empirical observation**을 분리해야 한다.

## 4. Decision Class

SPEC review 단계에서 uncertainty를 최소한 다음 class로 구분한다.

### `AUTO-RESOLVE`

실기기 probe, 테스트, 로그, 플랫폼 동작 등으로 객관적으로 답할 수 있고 evidence의 scope와 confidence가 충분한 경우.

예:

- 실제 좌표/거리
- component의 실제 크기
- frame drop 발생 여부
- fallback 발생 여부
- latency
- OS/API의 실제 동작
- 두 알고리즘 정의가 실제 데이터에서 결과 차이를 만드는지 여부

Founder 질문을 생성하지 않는다.

### `PRD-RESOLVE`

제품/UX 정책 문제이지만 PRD에 이미 명시된 경우.

Founder에게 같은 결정을 다시 묻지 않는다.

### `ENGINEERING-RESOLVE`

사용자 경험이나 제품 정책을 바꾸지 않는 순수 구현 선택.

기존 architecture, convention, engineering evidence를 사용해 처리한다.

### `VERIFY-MORE`

질문은 empirical이지만 evidence가 없거나 scope/confidence가 부족한 경우.

Founder에게 묻는 대신 추가 probe/test를 수행한다.

### `CONFLICT / IMPLEMENTATION-GAP`

Probe/Test 결과가 normative requirement와 충돌하는 경우.

관측값으로 requirement를 덮어쓰지 않고 구현 결함 또는 미충족 상태로 기록한다.

### `FOUNDER-DECISION`

PRD, evidence, engineering authority로도 답할 수 없고 실제 제품 trade-off가 남아 있는 경우에만 사용한다.

Founder Interview queue에는 이 class만 들어간다.

## 5. 판정 순서

```text
Uncertainty
  ↓
1. 이것은 empirical fact인가?
  ├─ YES
  │   ├─ 충분한 evidence 있음 → AUTO-RESOLVE
  │   └─ evidence 부족 → VERIFY-MORE
  │
  └─ NO
      ↓
2. Product / UX policy인가?
  ├─ PRD에 결정되어 있음 → PRD-RESOLVE
  └─ PRD에 없음
      ├─ material product decision → FOUNDER-DECISION
      └─ product 의미에 영향 없음 → ENGINEERING-RESOLVE

별도 규칙:
Evidence ↔ normative requirement 충돌
  → CONFLICT / IMPLEMENTATION-GAP
  → requirement 자동 변경 금지
  → engineering investigation
  → requirement 자체를 바꿔야 할 때만 founder escalation
```

## 6. 실제 병목 사례

실기기 검증에서 다음과 같은 상황이 발생했다.

- 실제 그래프 여러 개와 다수 삭제 케이스를 probe함
- 정상 데이터에서는 fallback이 발생하지 않음
- 두 후보 정의가 정상 실데이터에서 동일한 결과를 냄
- 반지름을 인위적으로 크게 만든 synthetic case에서만 차이가 발생함

그럼에도 SPEC contract가 정의를 완전히 고정하지 않았다는 이유로 다음과 같은 질문이 founder에게 올라왔다.

> "가장 먼 인접 대상을 어떤 정의로 고정할까요?"

여기서 중요한 것은 실기기 데이터가 **제품 정책을 새로 결정하는 것**이 아니라, 이미 존재하는 후보 정의들이 현재 정상 데이터에서 관측상 동일하게 동작한다는 **empirical fact를 제공한다는 점**이다.

따라서 review flow는 먼저 다음을 판단해야 한다.

1. 기존 PRD 또는 이전 founder decision이 의미론을 이미 결정했는가?
2. probe evidence로 구현상 ambiguity를 안전하게 해소할 수 있는가?
3. 실제로 남은 제품 trade-off가 있는가?

3번이 없다면 founder에게 재질문하지 않는다.

## 7. 현재 `spec-interrogator` 모델의 한계

구버전 agent는 다음 원칙을 사용한다.

> mechanical defect는 답이 문서 내부에 있고, judgment point는 답이 문서 바깥에 있다.

이 모델은 **외부 empirical evidence**를 별도 authority로 다루지 않는다.

그 결과 실제로는 아래 세 가지가 모두 "문서 바깥"으로 뭉쳐질 수 있다.

```text
문서 바깥
├─ 제품 의도 / business trade-off       → Founder가 맞음
├─ 실기기 / test evidence              → Founder가 아님
└─ platform / engineering fact         → Founder가 아님
```

따라서 다음 단계의 개선에서는 `inside documents vs outside documents`라는 2분법을 **authority-based classification**으로 확장하는 것이 핵심이다.

## 8. 신버전 템플릿과의 관계

MoAI-ADK 3.1.x 계열 템플릿에는 이미 일부 유사한 철학이 있다.

예를 들어 AskUserQuestion protocol은:

- outcome이 거의 확실하면 질문을 생략하고 auto-resolve
- 조사 결과 기반 질문은 먼저 evidence report를 제시
- Unknown-Knowns는 repository reconnaissance로 먼저 해소

하는 방향을 갖고 있다.

하지만 이는 주로 **interaction / recommendation / clarification protocol**에 관한 규칙이며, SPEC interrogation에서 `Probe/Test evidence`를 독립 authority로 분류해 founder escalation을 차단하는 contract는 아니다.

따라서 이 문서는 신버전 템플릿을 대체하려는 제안이 아니라, **구버전 SPEC interrogation pipeline에서 관측된 human-intervention 병목과 그 개선 방향을 기록하는 design note**다.

## 9. 향후 구현 시 최소 변경 원칙

이 문제를 해결하기 위해 새로운 대형 framework를 만들 필요는 없다.

최소 변경은 다음 수준이면 충분하다.

1. `spec-interrogator`가 flag를 만들기 전에 authority를 분류한다.
2. empirical candidate라면 기존 probe/test artifact를 먼저 탐색한다.
3. evidence가 충분하면 flag를 founder 질문으로 만들지 않는다.
4. 부족하면 `VERIFY-MORE`로 넘긴다.
5. 최종 `FOUNDER-DECISION`만 interrogation draft에 포함한다.
6. evidence가 requirement와 충돌하면 `CONFLICT / IMPLEMENTATION-GAP`으로 보내고 requirement를 자동 변경하지 않는다.

## 10. Regression 조건

향후 개선이 완료되었다고 보기 위한 최소 regression 조건:

```text
Given
  SPEC 문구에는 구현 세부 정의가 완전히 고정되지 않았지만
  실기기 probe/test가 해당 ambiguity의 실제 동작을 충분히 검증했고
  기존 PRD/founder decision과 의미론적 충돌이 없을 때

When
  spec-interrogator가 SPEC review를 수행하면

Then
  해당 항목은 Founder Interview queue에 들어가면 안 된다.

And
  evidence provenance와 판정 근거가 review artifact에 남아야 한다.
```

반대로:

```text
Given
  empirical evidence가 normative PRD/SPEC target과 충돌할 때

Then
  measured value로 requirement를 덮어쓰면 안 된다.

And
  CONFLICT / IMPLEMENTATION-GAP으로 기록해야 한다.
```

---

## 결론

기존 모델:

> 문서 안에서 답할 수 없으면 founder에게 묻는다.

개선 모델:

> **질문의 authority를 먼저 찾고, founder만이 답할 수 있는 질문만 founder에게 묻는다.**

이 차이가 SPEC review 단계에서 발생하는 불필요한 human intervention wall-clock time을 줄이는 핵심이다.
