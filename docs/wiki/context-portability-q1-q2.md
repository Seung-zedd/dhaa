# Context 이식성 조사 — 이슈 #4의 Q1·Q2 현황

작성일: 2026-10-13
상태: 현황 조사. 구현과 포맷 확정은 하지 않았습니다.

이슈 #4는 "context는 모델이나 harness가 아니라 프로젝트가 가져야 한다"는 가설을 작은 실험으로 검증하자는 제안입니다. 이 문서는 8개 질문 중 앞의 둘만 다룹니다.

- Q1. 현재 session에만 있는 정보와 repository에 꺼내 둔 정보를 구분할 수 있는가
- Q2. 다른 agent가 작업을 재개하는 데 필요한 최소 상태는 무엇인가

Q3~Q8(자동 증류, harness·model 교체, 동적 workflow, guardrail 효과)은 다루지 않았습니다. 이슈가 경로와 format을 표준으로 고정하지 말라고 했으므로 이 문서도 저장 위치나 스키마를 제안하지 않고 관찰한 사실과 검증할 가설만 적습니다.

사용 환경의 전제: 지금은 Claude Code와 moai-adk만 쓰고 다른 harness는 쓰지 않습니다. 그래서 harness·model 교체(Q4·Q5)는 당장 필요하지 않고 이 문서에서 실제로 의미가 있는 질문은 같은 harness 안에서 session, `/clear`, 기계를 넘나들 때 context가 이어지는가입니다.

---

## 1. 조사 방법과 한계

읽기 전용으로 다음만 실행했습니다.

- `gh issue view 4`, `gh issue list --state open`
- `git ls-files`(경로별), `git check-ignore -v`
- 직접 열람: `.moai/state/handoff/pending.json`, `.moai/state/active-sessions.json`, `.gitignore`, `.worktreeinclude`, `.claude/settings.json`, `.claude/rules/local/session-handoff.md`, `.moai/decisions/lsp-client-choice.md`
- auto-memory 디렉터리 목록
- §6의 회고 분석에 한해 session transcript(`~/.config/.../projects/<project>/*.jsonl`)를 스크립트로 추출해 읽었습니다. 추출 대상은 사용자 발화, AskUserQuestion과 그 답, 조사 도구 호출, 보고문입니다.

한계는 세 가지입니다. 이 repo 한 곳, HEAD `483a203` 한 시점의 스냅샷입니다. Codex CLI나 OpenCode에서 실제로 읽어 본 적은 없습니다. `.moai/config`의 47개 파일처럼 추적 파일은 개수만 세었고 내용은 열람하지 않았습니다.

---

## 2. Q1 — 상태가 어디에 있는가

이 repo의 상태는 네 층으로 나뉩니다.

| 층 | 위치 | git 추적 | 새 clone·다른 harness에서 |
|---|---|---|---|
| A. 추적되는 repository 상태 | `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`, `.claude/hooks/`, `.moai/config`(47), `.moai/project`(14), `.moai/design`(6), `.moai/evolution`(5), `.moai/decisions`(2), `docs/wiki`(6) | 추적됨 | 파일은 따라오지만 로드 방식은 harness마다 다름 |
| B. repo 안의 untracked 상태 | `.moai/state/`(handoff, active-sessions 등), `.moai/lessons-inbox.jsonl`, `.moai/reports/`, `.moai/branches/`, `logs/` | `.gitignore` 대상 | 따라오지 않음 |
| C. repo 밖 harness 저장소 | Claude Code auto-memory, session transcript | repo 밖 | Claude Code 전용 |
| D. session 안에만 있는 상태 | 대화, 암묵적 결정, 기각한 대안, 현재 의도 | 어디에도 없음 | 전달 불가 |

B층의 ignore 여부는 `git check-ignore -v`로 `.moai/state/`, `.moai/lessons-inbox.jsonl`, `.moai/reports/`, `.moai/branches/`, `logs/`에서 확인했습니다. `.moai/memory/`는 `.gitignore`에 적혀 있을 뿐 이 repo에는 디렉터리가 없습니다.

### 관찰

**관찰 1. 결정을 담는 추적 위치는 거의 비어 있습니다.**
`.moai/decisions/`에는 ADR 템플릿과 LSP 라이브러리 선정 기록, 파일 두 개뿐입니다. `.moai/specs/`는 아예 없어서 SPEC이 0개입니다. 다만 LSP 선정 기록에는 `Alternatives Considered` 표가 있어서 이슈가 말하는 "기각한 대안"이 추적 파일에 담긴 실사례가 한 건 있습니다.

**관찰 2. handoff 블록은 session 상태를 구조화해 남긴 유일한 기록인데, 저장 위치가 untracked입니다.**
`pending.json`은 `.moai/state/`에 있어 다른 clone이나 기계로 건너가지 않습니다. 필드는 `schema_version`, `spec_id`, `phase`, `saved_at`, `saved_by_session`, `conversation_language`, `directives`, `body`입니다. 이미 사용됐는지나 유효 기한을 나타내는 필드는 없습니다.

현재 파일은 이전 session이 2026-10-13 09:34 KST에 저장한 것(`spec_id: v3-cleanup`)이고 `body`의 전제 검증이 "main e7bc8cb"를 고정 문자열로 요구합니다. 지금 HEAD는 `483a203`이라 그 전제는 이미 성립하지 않습니다. 파일만 봐서는 이 블록이 낡았는지 알 수 없습니다.

한편 `session-handoff.md`는 이 repo가 session 상태 파일을 따로 두지 않고 git 상태를 기준으로 삼으며 블록은 붙여넣기용일 뿐이라고 스스로 밝힙니다. 이슈의 "context는 프로젝트가 가진다"는 방향과 이미 같은 쪽을 보고 있습니다.

**관찰 3. 일부 상태는 기계에 묶여 있어 이식 대상이 아닙니다.**
`active-sessions.json`은 host 이름, pid, 절대 경로 cwd를 담습니다. 다른 기계에서는 의미가 없고 옮기면 오히려 오해를 부릅니다. "portable context"를 정의하려면 이런 상태를 제외하는 기준도 함께 필요합니다.

**관찰 4. 교훈 저장소는 repo 밖에 있고 지금은 비어 있습니다.**
auto-memory 디렉터리에는 `MEMORY.md`도 다른 파일도 없습니다. 이전 session의 handoff 본문에는 "메모리 저장이 Write 훅에 막혀 이번 session 교훈은 기록되지 않음"이라는 줄이 있습니다. 교훈이 harness 전용 저장소에만 쌓이는 구조에서는 저장이 실패하면 어디에도 남지 않습니다. `.moai/lessons-inbox.jsonl`(7줄)도 untracked입니다.

**관찰 5. harness 종속 지점은 많고 adapter는 없습니다. (현재 사용 환경에서는 영향 없음, 나중을 위한 사전 목록)**
`AGENTS.md`는 없습니다. 이름에 codex나 opencode가 들어간 추적 파일은 review gate 훅 하나뿐입니다. `.claude/settings.json`에는 이벤트 훅이 26종 등록돼 있고 `.claude/rules/moai/`의 규칙 79개는 Claude Code의 규칙 로더를 전제로 작성됐습니다. 내용은 사람이 읽을 수 있는 markdown이라 다른 harness도 읽을 수는 있겠지만 자동으로 로드되고 강제된다는 성질은 Claude Code에만 있다고 추정합니다. 다른 harness에서 확인한 것은 아닙니다.

---

## 3. Q2 — 최소 handoff 상태

이슈 Q2가 후보로 든 10개 항목을 현재 resume 블록(`.claude/rules/local/session-handoff.md`)과 대조했습니다.

| 후보 | 현재 resume 블록 | 판정 |
|---|---|---|
| goal | 전용 줄 없음. `directives.goal` 필드가 있으나 지금은 비어 있음 | 부분 |
| current task | 첫 줄 `<SPEC-ID or task> <phase> 진입` | 있음 |
| decisions | 없음. `applied lessons`는 메모리 파일명만 가리킴 | 없음 |
| constraints | 없음 | 없음 |
| rejected alternatives | 없음 | 없음 |
| relevant files | 전용 줄 없음. `실행` 문장에 경로가 우연히 들어가는 정도 | 없음 |
| SPEC state | `spec_id`와 `phase`뿐. 이 repo에는 SPEC이 0개 | 부분 |
| verification state | 전제 검증 최대 4개(명령 → 기대 결과) | 부분 |
| git state | 전제 검증으로 간접 표현. HEAD를 고정 문자열로 적어 시간이 지나면 깨짐 | 부분 |
| next action | `실행` 1개와 `후속` 1개 | 있음 |

10개 중 있음 2, 부분 4, 없음 4입니다. 블록은 "다음에 무엇을 실행할지"에 맞춰 설계돼 있습니다. "왜 지금 이 상태인지"(결정·제약·기각한 대안)와 "어디를 봐야 하는지"(관련 파일)는 구조상 비어 있습니다. 이슈 Q6의 semantic continuity가 가장 먼저 새는 곳이 이 네 칸일 가능성이 큽니다.

**가설 H1**: 최소 handoff 상태는 현재 블록에 decisions, constraints, rejected alternatives, relevant files 네 칸을 더한 것이다. (회고 분석 결과는 §6, 앞으로의 검증 방법은 §7)

---

## 4. 다음 단계 후보 (Q1·Q2 범위 안)

1. **H1 검증.** 설계를 §5~§7에 적었습니다. 과거 session 쌍은 회고 분석(§6)으로 읽었고 앞으로의 handoff는 A/B 프로토콜(§7)로 기록합니다. 판정 기준은 이슈 Q6의 요소(Goal, Decision, Constraint, Task State, SPEC State, Verification State, Relevant Context)를 따릅니다.
2. **결정 기록 위치 점검.** 이미 추적되고 ADR 템플릿이 있는 `.moai/decisions/`를 그대로 쓸 수 있는지, 이슈의 `.agent/context/` 예시처럼 별도 위치가 필요한지는 1번 결과를 보고 판단합니다. 지금은 정하지 않습니다.
3. **제외 기준 정리.** `active-sessions.json`처럼 기계에 묶인 상태를 "이식 대상 아님"으로 분류하는 기준을 정리합니다.

---

## 5. H1 검증의 두 단계

H1은 두 단계로 나눠 검증합니다.

| 단계 | 내용 | 장점 | 한계 |
|---|---|---|---|
| 회고 분석 (§6) | 이미 일어난 재개를 transcript로 읽고 무엇이 유실됐는지 분류 | 새 session 없이 바로 할 수 있음 | 사후 해석이고 표본이 작음 |
| 앞으로의 A/B (§7) | 다음 실제 handoff부터 블록 두 종류를 함께 만들고 한쪽으로 재개해 기록 | 판정 기준을 미리 고정할 수 있음 | 표본이 쌓이기까지 시간이 걸림 |

과거 session의 상태를 되돌려 같은 블록으로 다시 재개해 보는 방식은 택하지 않았습니다. §6의 P1이 쓴 블록은 전제 검증 3번에서 "PR #11이 OPEN"을 요구하는데 이 PR은 `gh pr view 11`로 확인한 대로 2026-10-13 08:35 KST(`mergedAt` 2026-10-12T23:35:55Z)에 이미 머지됐습니다. 저장소를 그 시점으로 되돌리고 PR 상태까지 맞추는 비용이 실험 가치보다 큽니다.

---

## 6. 회고 분석 — 이미 일어난 재개에서 유실된 것

### 6.1 대상과 방법

transcript 15개 중 `ultrathink.` 블록으로 시작한 session은 6개입니다(이 조사를 하는 session 포함). 이 중 사용자 발화가 많아 실제 작업이 이어진 쌍 두 개를 골랐습니다. 나머지는 확인 위주의 짧은 session(사용자 발화 2~3턴)이라 열람하지 않았습니다.

| 쌍 | 블록을 만든 session | 블록으로 시작한 session | 사용자 발화 | 블록의 `실행` 요지 |
|---|---|---|---|---|
| P1 | `66bd6283` (10-11 16:32~17:33 KST) | `b4454abc` (10-13 08:22~09:36 KST) | 8턴 | PR #11이 main에 머지된 #12와 충돌하는지 검토 |
| P2 | `ede77010` (10-13 09:36~09:52 KST) | `b598b763` (15:41~15:45 KST), `c90bc19f` (15:45~16:25 KST) | 2턴, 12턴 | 지시 파일 용량 초과 경고를 줄이는 방안 조사 |

방법은 세 가지 일입니다. 각 session에서 사용자 발화, AskUserQuestion과 그 답, 조사 도구 호출, 보고문을 추출합니다. 재개한 session이 필요로 한 사실을 찾습니다. 그 사실을 세 부류로 나눕니다.

- (가) 블록에 있었음
- (나) 블록에는 없지만 repo나 GitHub에서 복구 가능했음
- (다) 원래 session 안에만 있었음

H1이 맞다면 (다)에 해당하는 사실이 네 칸(결정, 제약, 기각한 대안, 관련 파일)에 몰려 나와야 합니다. 아래 `#N`은 transcript의 줄 번호(0부터 센 jsonl 줄 인덱스)입니다.

### 6.2 P1 — `66bd6283` → `b4454abc`

- 블록의 `실행`과 전제 검증 4개가 첫 조사 전체를 이끌었습니다. 재개한 session은 전제 4개를 통과시킨 뒤 PR #11을 `git merge-tree`로 시험 머지했고(#35~#159) 충돌 파일 11개와 충돌로 표시되지 않는 함정 1개를 찾았습니다(#167).
- (가): PR #12의 내용(Pencil 제거, dhaa에서 `moai update` 금지 문서)은 `실행` 줄에, 리뷰 요구 승인 수 0은 전제 검증 4번에 들어 있었습니다.
- (나): `moai update` 금지의 근거는 보고문이 `development_pipeline_guideline.md:52`를 인용했고 열려 있는 PR 목록은 PR #11 설명과 `gh`로, `.moai/branches/`가 추적된 적 있는지는 git 이력으로 확인했습니다.
- 블록의 후속 줄에 있던 가설("원래 추적 대상이었을 수 있음")은 재개한 session이 git 이력으로 반증했습니다(#167 4항). 블록이 추측을 "수 있음"으로 표시해 둔 덕에 그대로 믿지 않고 검증으로 이어졌습니다.
- (다): 이 쌍에서는 찾지 못했습니다. 재개한 session의 AskUserQuestion 6건(#168, #214, #385, #465, #788, #1295)은 질문 문구를 `66bd6283`의 사용자 결정 목록과 대조했을 때 겹치는 것이 없는 새 결정이었습니다.

P1에서는 블록 A만으로 충분했습니다. 필요한 사실이 repo와 GitHub에 이미 기록돼 있었기 때문입니다.

### 6.3 P2 — `ede77010` → `b598b763` → `c90bc19f`

같은 블록이 두 session에 붙여넣어졌습니다.

- `b598b763`(4분)은 블록의 `실행`대로 사용자에게 Kanban Mode 사용 여부를 물어 "사용하지 않음"이라는 답을 받았습니다(#114~#115). 이어 `main-checkout-branch-guard.md` 제외를 골라 `.claude/settings.local.json`에 `claudeMdExcludes` 3개를 적용했습니다(#143). "세션 재시작하고 /context로 확인할게"로 끝났고 새 블록은 만들어지지 않았습니다(#162).
- 사용자는 바로 `c90bc19f`를 열고 `/context` 화면과 함께 **원래 블록을 그대로 다시 붙여넣어** "이게 원래 재개블록이였는데 그럼 이제부터 뭘 하면 됨?"이라고 물었습니다(#51).
- 그 결과 `c90bc19f`는 두 가지를 겪었습니다.
  1. Kanban 사용 여부를 **다시 물었고** 같은 답("쓰지 않음")을 다시 받았습니다(#88~#89). 이 답은 (다)에 해당합니다. 블록에 없었고 repo에도 남지 않았습니다.
  2. 메인 체크아웃의 `settings.local.json`에 `claudeMdExcludes`가 이미 있는 것을 grep으로 발견했고(#126) 이 session의 경고 수치가 메인과 다른 이유를 역추적해야 했습니다(#197). 이 변경은 (나)가 아니라 B층(untracked 로컬 파일)에 있었습니다. 같은 기계의 같은 작업 트리여서 찾아냈을 뿐 `.gitignore` 대상이라 다른 clone에서는 찾을 수 없습니다.

P2에서 유실을 만든 직접 원인은 필드 부족보다 **블록이 낡은 것**입니다. 첫 session이 상태를 바꿨는데(파일 수정 1건, 결정 2건) 블록을 갱신하지 않았고 사용자는 원래 블록을 다시 썼습니다. 다만 decisions 칸이 있어서 "Kanban 미사용 확정, 제외 3건 적용"이 적혀 있었다면 재질문과 역추적은 피할 수 있었습니다.

### 6.4 잠정 결론

- 두 쌍에서 네 칸 중 "없어서 다시 해야 했던" 사실은 decisions 1건(Kanban 미사용)뿐입니다. constraints, rejected alternatives, relevant files는 유실 사례를 찾지 못했습니다. 필요한 정보가 repo와 GitHub에 있었거나 다시 조사하는 비용이 작았습니다.
- 더 큰 문제는 스키마가 아니라 **갱신 시점**입니다. 상태가 바뀐 뒤 블록이 갱신되지 않으면 낡은 블록이 그대로 재사용됩니다. §2 관찰 2의 `pending.json`도 같은 문제를 보였습니다.

**가설 H2 (미검증)**: handoff 블록의 유실은 필드가 모자라서보다 블록이 낡아서 더 자주 생긴다.

표본은 2쌍이라 일반화할 수 없습니다. H1은 부분적으로만 지지됩니다(decisions 칸에 한해).

---

## 7. 앞으로의 A/B 검증 프로토콜

회고 분석의 한계(표본 2쌍, 사후 해석)를 메우기 위해 다음 실제 handoff부터 수동으로 기록합니다. 템플릿이나 `.claude/rules/local/session-handoff.md`는 바꾸지 않습니다.

### 7.1 절차

1. 사용자가 session 종료를 선언하면 같은 session에서 블록 두 종류를 만듭니다. 블록 A는 현행 형식입니다. 블록 B는 A에 네 칸(결정, 제약, 기각한 대안, 관련 파일)을 더한 것이고 칸마다 3줄 이내로 제한해 길이 영향을 줄입니다.
2. 두 블록과 함께 handoff 시각의 `git rev-parse HEAD`와 `git status --short`를 기록합니다. 상태를 되돌려 재현하는 대신 기록해 둡니다.
3. 다음 session에는 둘 중 하나만 무작위로 붙여넣습니다(동전 던지기). 사용자가 직접 고르면 선택 편향이 들어갑니다. 쓰지 않은 블록은 보관합니다.
4. 재개한 session마다 아래 표의 항목을 기록합니다.
5. 사람이 직접 판정합니다. 임계값은 미리 정하지 않고 표본이 쌓이기 전에는 결론을 내리지 않습니다. 최소 표본 수는 첫 5쌍을 본 뒤에 정합니다.

한 쌍에서 두 블록으로 두 번 재개하는 설계는 쓰지 않습니다. 첫 재개가 repo 상태를 바꾸기 때문에 두 번째 재개의 조건이 달라집니다.

### 7.2 기록 항목

| 항목 | 의미 | 어느 가설과 관련 |
|---|---|---|
| 블록 종류 | A 또는 B | H1 |
| 첫 조치까지의 도구 호출 수 | 재개 후 첫 의미 있는 작업까지의 비용 | H1 |
| 사용자에게 한 질문 수 | AskUserQuestion과 일반 질문의 합 | H1 |
| 그중 이미 답이 나왔던 질문 수 | 이전 session의 결정을 다시 물은 횟수 | H1, H2 |
| 이전 결정을 뒤집거나 어긴 횟수 | 재개한 session이 모르고 어긴 결정 | H1 |
| 사용자가 "그럼 뭘 해야 해?"류로 되물은 횟수 | 블록만으로 시작하지 못한 정도 | H1, H2 |
| 블록을 만든 뒤 상태가 바뀌었는지 | 블록 작성 후 파일이나 결정이 바뀌었는데 블록을 갱신했는가 | H2 |

### 7.3 블록 B의 임시 추가 칸

아래는 실험용 임시 형식이며 표준이 아닙니다. 이슈가 형식을 고정하지 말라고 했으므로 칸 이름과 순서는 실험 도중 바꿀 수 있습니다.

```text
(블록 A의 전체)

결정:
- <이번 session에서 사용자가 확정한 것, 한 줄씩>
제약:
- <지켜야 하는 조건>
기각한 대안:
- <검토했다가 버린 것과 이유>
관련 파일:
- <경로 : 왜 봐야 하는지>
```

### 7.4 판정

- 이미 답이 나왔던 질문 수와 결정을 어긴 횟수가 B에서 A보다 낮으면 H1을 지지합니다.
- 중복 질문의 주된 원인이 "블록을 만든 뒤 상태가 바뀌었는데 블록이 갱신되지 않음"이면 A와 B 어느 쪽에서든 H2를 지지합니다. 이때는 네 칸을 더하는 것보다 블록 갱신 시점을 정하는 쪽이 먼저입니다.

---

## 8. 확인하지 못한 것

- 다른 harness에서 읽고 재개하는 일(Q4)은 시도하지 않았습니다.
- §6의 사실 분류는 질문 문구와 보고문을 읽고 한 해석입니다. 모든 도구 호출 결과까지 대조하지는 않았습니다.
- §6은 쌍 두 개만 읽었습니다. 나머지 짧은 session(`2cf8af4e`, `8bd27748`)은 열람하지 않았습니다.
- 과거 session 상태를 되돌려 같은 블록으로 재개하는 실험은 하지 않았습니다(§5).
- D층 중 transcript로 확인한 것은 §6의 두 쌍뿐입니다. auto-memory는 비어 있어서 나머지 D층 목록은 이슈 본문을 따른 서술입니다.
- `.moai/state/goal/`은 조사 시점에 이 repo에 없었고 규칙 문서에만 위치가 나옵니다. 그래서 goal 상태 파일의 내용은 보지 못했습니다.
- `.moai/config` 등 추적 파일의 내용은 개수만 확인했습니다.
- `.moai/specs`의 부재와 `pending.json`의 내용은 HEAD `483a203` 시점의 값이며 session이 바뀌면 달라집니다.
