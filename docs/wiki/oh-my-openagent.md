# Oh My OpenAgent (OmO) 분석

- 저장소: https://github.com/code-yeongyu/oh-my-openagent
- 라이선스: **Sustainable Use License 1.0 (비오픈소스)**
- npm: `oh-my-opencode` (`oh-my-openagent`로 이중 배포 중), Codex Light는 `lazycodex-ai`
- 조사일: 2026-07-29

**확인 범위**: 루트 트리, `README.md`(영문 전문), `packages/` 구성(43개 워크스페이스), `LICENSE.md`.
**한계**: `AGENTS.md`(51KB)와 `docs/`는 읽지 않았습니다. 성능 수치는 자체 보고값입니다. 설치·구동 검증은 하지 않았습니다.

---

## 1. 레이어 — 런타임 / 하네스

앞의 두 프로젝트와 **결정적으로 다른 지점**입니다.
MoAI와 ECC는 Claude Code 위에 얹는 지시문·문서 계층이지만, **OmO는 하네스를 갈아끼웁니다.**

Ultimate 에디션은 Claude Code가 아니라 **OpenCode + Bun** 위에서 돕니다.
즉 현 환경에 "추가"하는 물건이 아니라 "대체"하는 물건입니다.

한 문장 요약: **도구 자체를 다시 만드는 시스템.**

---

## 2. 정체성

- 저자(code-yeongyu)가 개인 프로젝트에 LLM 토큰 $24K를 태워 얻은 결론을 OpenCode 플러그인으로 압축.
- 사용법: 설치 후 `ultrawork`(또는 `ulw`) 한 단어.
- **반(反)락인이 명시적 정체성** — "Claude Code is a nice prison, but it's still a prison." Opus 5 / Kimi K3 / GPT-5.6 Sol / GLM-5를 섞어 쓰는 것이 기본 전제.
- 에이전트 명명은 그리스 신화: **Sisyphus**(오케스트레이터), **Hephaestus**(자율 심층 작업), **Prometheus**(인터뷰형 플래너), Oracle / Librarian / Explore / Multimodal Looker.

### 두 에디션

| 에디션 | 대상 | 설치 | 내용 |
|---|---|---|---|
| **Ultimate** | OpenCode | `bunx oh-my-openagent install` | 에이전트 11, 라이프사이클 훅 54+(Team Mode 포함 61), 내장 MCP 5, Team Mode, ulw-loop, hashline |
| **Light** | Codex CLI | `npx lazycodex-ai install` | 이식 가능 컴포넌트 8종 (rules, comment-checker, git-bash, lsp, ultrawork, ulw-loop, start-work-continuation, telemetry). 에이전트 오케스트레이션·`team_*` 없음 |

---

## 3. OmO만의 기술

### ① Hashline — 해시 앵커 편집 툴 (가장 중요)

읽은 모든 줄에 콘텐츠 해시를 붙여 반환합니다.

```
11#VK| function hello() {
22#XJ|   return "world";
33#MB| }
```

에이전트는 `LINE#ID`를 참조해 편집하고, 파일이 그 사이 변경됐다면 **해시 불일치로 손상 전에 편집이 거부**됩니다.
공백 재현도, stale-line 에러도 발생하지 않습니다.

자체 보고 효과: **Grok Code Fast 1의 성공률 6.7% → 68.3%** — 모델은 그대로 두고 편집 툴만 교체.

근거로 Can Bölük의 "The Harness Problem"을 인용합니다.

> "어떤 툴도 모델에게 변경하려는 줄에 대한 안정적이고 검증 가능한 식별자를 주지 않는다. 전부 모델이 이미 본 내용을 재현하는 데 의존한다. 재현하지 못할 때 — 그리고 자주 못 한다 — 사용자는 모델을 탓한다."

**세 프로젝트 중 유일하게 프롬프트가 아닌 툴 레이어를 건드린 사례입니다.**
영감 출처는 [oh-my-pi](https://github.com/can1357/oh-my-pi).

### ② 카테고리 기반 모델 라우팅

서브에이전트를 부를 때 **모델이 아니라 카테고리**를 지정하고, 하네스가 매핑을 관리합니다.

| 카테고리 | 용도 |
|---|---|
| `visual-engineering` | 프론트엔드, UI/UX, 디자인 |
| `deep` | 자율 리서치 + 실행 |
| `quick` | 단일 파일 변경, 오타 |
| `ultrabrain` | 어려운 로직, 아키텍처 결정 |

> MoAI에서 매번 `model` 을 명시해야 하는 문제(병렬 서브에이전트가 상위 모델을 잘못 상속)를 **구조적으로 해결한 형태**입니다.

### ③ 스킬 임베디드 MCP

MCP 서버가 컨텍스트 예산을 먹는 문제를, 스킬이 자기 MCP를 들고 다니며 **필요할 때만 스폰 → 끝나면 회수**하는 방식으로 해결합니다.
`.mcp.json` 상시 등록 방식(MoAI)은 비용을 항상 지불합니다.

내장 MCP: Exa(웹 검색), Context7(공식 문서), Grep.app(GitHub 코드 검색) — 런타임 주입이라 `opencode mcp list`에는 보이지 않습니다.

### ④ Team Mode v4.0 (opt-in)

리드 에이전트 + 최대 8명 병렬, tmux 그리드 실시간 시각화, `team_create` / `team_send_message` / `team_task_create` / `team_status` 툴 계열.

```jsonc
// .opencode/oh-my-openagent.jsonc
{
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
    "tmux_visualization": true
  }
}
```

개념 자체는 MoAI Agent Teams와 거의 같습니다. 차이는 **그 위에 얹은 적대적 스킬**입니다.

- `hyperplan` — 코드 한 줄 쓰기 전 **적대적 에이전트 5명**이 서로 직교하는 각도에서 계획을 찢음
- `security-research` — 취약점 헌터 3 + PoC 엔지니어 2 병렬 감사, 심각도를 **실제 익스플로잇 가능성**으로 보정

MoAI의 spec-interrogator / evaluator-active와 사상이 같고, 규모만 더 큽니다.

### ⑤ `/init-deep` — 계층형 AGENTS.md

```
project/
├── AGENTS.md              ← 프로젝트 전역 컨텍스트
├── src/
│   ├── AGENTS.md          ← src 전용 컨텍스트
│   └── components/
│       └── AGENTS.md      ← 컴포넌트 전용 컨텍스트
```

에이전트가 해당 디렉토리를 작업할 때만 그 컨텍스트를 읽습니다.
MoAI는 CLAUDE.md 단일 파일 + codemaps라 항상 전량 로드입니다.

### ⑥ Goal / Todo Enforcer / ulw-loop

에이전트가 idle로 빠지면 시스템이 도로 끌어당깁니다.
세션 목표를 지속 보관하고 **완료 감사(evidence audit)** 를 통과할 때까지 계속 재주입. 상태는 `.omo/ulw-loop/`에 저장.

MoAI의 `TeammateIdle` 훅(exit 2 = 계속 작업)과 `/moai loop`가 대응물이지만, OmO 쪽이 훨씬 공격적입니다("discipline agent").

### ⑦ 기타

- **IntentGate** — 행동 전 진짜 사용자 의도를 분석해 문자 그대로의 오해를 방지
- **LSP 통합** — `lsp_rename`, `lsp_goto_definition`, `lsp_find_references`, `lsp_diagnostics`. 전용 데몬 패키지 보유
- **AST-Grep** — 25개 언어 패턴 인식 검색·재작성
- **Tmux 통합** — REPL, 디버거, TUI를 세션 안에서 유지
- **Claude Code 호환 레이어** — 훅·커맨드·스킬·MCP·플러그인이 수정 없이 동작한다고 명시
- **`/start-work` → Prometheus 인터뷰** — 스코프와 모호성을 질문으로 걷어낸 뒤 계획 수립

---

## 4. 구조

`packages/` 아래 43개 워크스페이스로 분리된 TypeScript 모노레포입니다. 핵심 코어 패키지:

`hashline-core`, `lsp-core` / `lsp-daemon` / `lsp-tools-mcp`, `team-core`, `delegate-core`, `model-core`, `rules-engine`, `skills-loader-core`, `agents-md-core`, `claude-code-compat-core`, `mcp-client-core` / `mcp-stdio-core`, `tmux-core`, `telemetry-core`, `boulder-state`, `omo-codex`, `omo-opencode`, `openclaw-core`, `pi-goal` / `pi-webfetch`, `senpi-task`.

플랫폼별 프리빌트 바이너리 패키지가 별도로 존재합니다 (darwin arm64/x64, linux x64/arm64 (+musl, baseline), **windows x64/arm64**).

현재 **"Multi-Harness Agent OS Refactor" 진행 중** — 순수 TS 코어 / MCP 서버 / 스킬 / 어댑터 shim을 레이어로 분리해 OpenCode·Codex·Pi·Claude Code에서 재사용하는 것이 목표.

---

## 5. MoAI-ADK와의 차이

### OmO에 없는 것

SPEC 문서 생명주기, EARS, REQ↔시나리오 추적성, TRUST 5, @MX 태그, 3단계 SPEC 리뷰 파이프라인, FROZEN/EVOLVABLE 헌법, 평가자 관대화 방지 메커니즘.

Prometheus는 인터뷰형 플래너지 **문서 계약 시스템이 아닙니다.** `.omo/ulw-loop/`는 상태 저장소지 명세서가 아닙니다.

### 방향성

- OmO — "빠르고, 안 멈추게" 최적화
- MoAI — "정확하고, 추적 가능하게" 최적화

같은 문제를 푸는 게 아니라 다른 문제를 풉니다.

---

## 6. 도입 전 반드시 알아야 할 것

### ① 라이선스가 오픈소스가 아님 (중요)

**Sustainable Use License 1.0.** MoAI-ADK·ECC(MIT)와 다릅니다.

- 허용: 자기 회사 **내부 업무 용도**, 비상업·개인 용도 → PillWriter 개발 도구로 쓰는 것은 허용 범위
- 제한: 재배포는 **무료 + 비상업 목적일 때만**. 파생물을 상용으로 판매 불가
- 라이선스·저작권 고지 제거·변경 금지, 수정 시 수정 사실 명시 의무
- 특허 조항: 라이선서 상대로 특허 침해 주장 시 라이선스 즉시 종료
- 위반 시 자동 종료, 통지 후 30일 내 시정하면 소급 복원 (재위반 시 영구 종료)

**판단 기록 (2026-07-29): PillWriter 수익화와 라이선스는 무관합니다.**

SUL이 규율하는 대상은 "소프트웨어로 무엇을 만드느냐"가 아니라 "소프트웨어 자체를 어떻게 다루느냐"입니다.
`internal business purposes`는 허용 목록에 명시돼 있고, 이는 영리 회사가 자기 업무에 쓰는 것을 가리킵니다(SUL의 원 출처는 n8n — "내부 사용은 자유, 되팔거나 SaaS로 호스팅하지는 말 것"이 설계 의도).

| 축 | 대상 | PillWriter 상황 | 판정 |
|---|---|---|---|
| Use | OmO를 개발 도구로 구동 | 코드 작성에 사용 | 내부 업무 용도 → 허용 |
| Distribute | OmO 자체를 남에게 전달 | 하지 않음 | 해당 없음 |

RevenueCat 수익화는 **PillWriter라는 별개 저작물**의 상업화입니다. SUL에는 GPL 같은 카피레프트(전염) 조항이 없고, 산출물이 파생물이 된다는 규정 자체가 없습니다.

위반이 되는 경우는 다음 셋뿐입니다.

1. OmO 소스를 PillWriter에 벤더링해 유료 배포 (예: `hashline-core` 코드 복사)
2. OmO를 포함한 상용 제품·호스팅 서비스 판매
3. 포크·수정본을 유료 재배포

부수 의무: 라이선스·저작권 고지 제거 금지, 수정본 전달 시 수정 사실 명시.

이식 후보로 뽑은 카테고리 모델 라우팅·계층형 AGENTS.md는 **개념 차용**이라 라이선스와 무관합니다(코드를 가져오지 않고 같은 구조를 MoAI 규칙으로 새로 작성).

단, 이는 라이선스 원문 해석이며 법률 자문이 아닙니다. 투자 실사 등에서 사용 도구 목록을 제출해야 할 시점에는 별도 검토를 권합니다.

### ② 텔레메트리 기본 ON

PostHog로 **UTC 기준 일 1회, 머신당 1건** 활성 이벤트 전송. SHA256 해시 설치 ID 사용, raw hostname 미전송, person profile 미생성이라고 명시.

opt-out: `"telemetry": false` 설정, `OMO_DISABLE_POSTHOG=1`, `OMO_SEND_ANONYMOUS_TELEMETRY=0` (Codex Light는 `OMO_CODEX_*` 접두 변수).

MoAI는 텔레메트리가 없습니다.

### ③ 환경 전제 불일치

- Ultimate은 **OpenCode + Bun** 필수 → Claude Code 세션을 포기해야 함
- tmux 시각화 / Team Mode 그리드가 핵심 UX인데 **Windows에서 tmux는 WSL 없이 사실상 불가**
- 네이밍 혼란: npm 패키지명은 여전히 `oh-my-opencode`, 그리고 **`omo`는 다른 저자의 무관한 패키지**라 `npx omo` 사용 금지를 README가 직접 경고
- 저장소가 대규모 리팩터링 중
- 저자 본인이 "이 프로젝트의 99%는 OpenCode로 만들었고 TypeScript를 잘 모른다"고 기재. 유지보수도 AI 어시스턴트(Jobdori)가 실시간 수행한다고 명시
- 소셜 프루프 중심 마케팅 강함("Anthropic이 우리 때문에 OpenCode를 차단했다"). 성능 수치 전부 자체 보고

---

## 7. 이식 후보

| 우선순위 | 항목 | 이유 |
|---|---|---|
| 높음 | **카테고리 기반 모델 라우팅** | `.claude/rules/moai/`에 "작업 유형 → 모델" 매핑 테이블을 규칙으로 승격. 서브에이전트 모델 상속 사고를 구조적으로 제거 |
| 중간 | **계층형 AGENTS.md 패턴** | `/init-deep` 방식. 프로젝트 확장 시 단일 CLAUDE.md 로드 병목 대비. MoAI 구조를 건드리지 않고 얹을 수 있음 |
| 참고만 | **Hashline** | Claude Code Edit 툴 교체 불가 → 도입 불가능. 단 "편집 툴이 모델보다 큰 레버"라는 관점은 read-before-edit 규칙을 느슨하게 다루면 안 되는 근거로 유효 |

**결론: 교체 대상 아님.** OpenCode+Bun 전환 비용, SUL 라이선스, Windows/tmux 마찰, 그리고 무엇보다 SPEC 추적성 상실이 이득을 상회합니다.
