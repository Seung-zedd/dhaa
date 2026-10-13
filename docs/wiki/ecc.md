# ECC (Everything Claude Code) 분석

- 저장소: https://github.com/affaan-m/ECC
- 라이선스: MIT
- 버전: 2.1.0 (`agent.yaml` 기준)
- 조사일: 2026-07-29

**확인 범위**: 루트 트리, `CLAUDE.md`, `AGENTS.md`, `agent.yaml`(스킬·커맨드 전체 목록), `SOUL.md`, `RULES.md`, `hooks/` 구성, `README.md`(106KB — 요약 fetch로 핵심 섹션만).
**한계**: 모든 수치는 메인테이너 자체 보고값이며 외부 벤치마크는 존재하지 않습니다. 설치·구동 검증은 하지 않았습니다.

---

## 1. 레이어 — 콘텐츠 / 카탈로그

ECC가 최적화하는 대상은 **선택지의 폭**입니다.
"어떻게 일할 것인가"를 규칙으로 고정하는 대신, 쓸 수 있는 에이전트·스킬·커맨드를 최대한 많이 공급합니다.

- 자기 규정: "the agent harness operating system"
- 파이프라인: `plan → test → implement → review → verify → remember → improve`
- 슬로건: "Optimize the context window. Persist everything else."

한 문장 요약: **선택지를 공급하는 시스템.**

---

## 2. 규모

| 구성 요소 | 수량 |
|---|---|
| 에이전트 | 67 |
| 스킬 | 281 |
| 커맨드 (레거시 shim) | 94 |
| 룰 | 34 (공통 + 언어별) |
| MCP 설정 | 14 |
| 언어 룰 팩 | 12개 생태계 |

스킬 목록에는 개발 외 도메인 버티컬도 포함됩니다 — `healthcare-phi-compliance`, `customs-trade-compliance`, `energy-procurement`, `investor-outreach`, `production-scheduling` 등.

내부 테스트: v1.8.0 기준 997건 통과(v1.7.0 992, v1.6.0 978).

---

## 3. ECC만의 자산

### AgentShield — 에이전트 설정 자체를 감사

세 프레임워크를 통틀어 **가장 독자적인 축**입니다. 앱 코드가 아니라 **하네스 설정 파일**을 스캔합니다.

- 대상: `CLAUDE.md`, `settings.json`, MCP 설정, 훅, 에이전트 정의, 스킬
- 5개 범주: 시크릿 탐지(14패턴) / 권한 감사 / 훅 인젝션 분석 / MCP 서버 리스크 프로파일링 / 에이전트 설정 리뷰
- 실행: `npx ecc-agentshield scan`, `--fix`, 또는 Claude Code 안에서 `/security-scan`
- 출력: 터미널 A–F 등급, JSON, Markdown, HTML. **critical 발견 시 exit 2** (빌드 게이트용)
- `--opus` 모드: red-team / blue-team / auditor 3에이전트 파이프라인
- 자체 보고 수치: 테스트 1282건, 커버리지 98%, 정적 분석 규칙 102개
- 출처: Claude Code Hackathon (Cerebral Valley x Anthropic, 2026-02)

관점의 핵심: **"훅, MCP 서버, 프로젝트 지시문을 실행 가능한 설정으로 취급하라."**

### Instinct 시스템 (continuous-learning-v2)

세션에서 학습한 패턴에 **신뢰도 점수**를 붙여 저장하고, 세션 시작 시 임계치 이상 상위 N개만 주입합니다.

| 항목 | 값 |
|---|---|
| 주입 개수 상한 | `ECC_MAX_INJECTED_INSTINCTS` (기본 6) |
| 신뢰도 임계치 | `ECC_INSTINCT_CONFIDENCE_THRESHOLD` (기본 0.7) |
| 저장 위치 | `CLV2_HOMUNCULUS_DIR` (기본 `~/.local/share/ecc-homunculus`) |

관련 커맨드: `/instinct-status`(신뢰도 조회), `/instinct-import`, `/instinct-export`(팀 공유), `/evolve`(유사 instinct를 스킬로 승격), `/prune`(만료 정리).
`/skill-create --instincts`로 git 히스토리에서 instinct를 생성할 수 있습니다.

### 통합 메모리 볼트 (`ecc memory`)

Claude / Codex / Hermes / OpenClaw / Kimi가 **하나의 로컬 Markdown 저장소**를 공유합니다.

- 포맷: `ecc.memory.v1`. 프로젝트·팀 메모리는 `.ecc/memory/`, 사용자 메모리는 `~/.ecc/memory/`
- CLI: `init --scope project`, `search`, `read`, `handoff`, `doctor`
- **신뢰 경계 명시**: "Memory is unreviewed context, not executable policy." 에이전트가 회수된 본문을 실행 가능한 지시로 취급하는 것을 금지
- 본문 입력은 `--stdin` 또는 `--body-file`만 허용 (CLI 인자로 못 넣음)
- MCP 서버는 툴 4개만 노출: `memory_save`, `memory_search`, `memory_read`, `memory_doctor`
- 하네스 신원(`ECC_MEMORY_HARNESS`)은 **서버 바인딩**이라 호출자가 위조 불가

### 기타 가드레일

- **GateGuard** — `rm`, 강제/경로 `git checkout`, 파괴적 `find -exec`를 실행 전 차단
- **단일 커넥터 MCP 정책** — 기본 커넥터를 `chrome-devtools` 하나로 축소(2026-06 감사에서 기존 6개 폐기)
- **프롬프트 방어 베이스라인** — `CLAUDE.md` 상단에 역할 변경 거부, 유니코드·제로폭·동형문자 의심, 외부 fetch 데이터 무신뢰 처리 블록
- 공급망 경고 — 공식 배포 채널(저장소, npm `ecc-universal`/`ecc-agentshield`, GitHub App, 플러그인 `ecc@ecc`, ecc.tools) 외 미러 사용 금지 명시

### 멀티 하네스

Claude Code, Codex, Cursor, OpenCode, Gemini CLI, Zed, Antigravity, Qwen, Hermes, OpenClaw, Kimi, CodeBuddy, JoyCode, GitHub Copilot.

단, **하네스별 지원 편차가 큽니다**:

| 하네스 | 에이전트 | 커맨드 | 스킬 | 훅 |
|---|---|---|---|---|
| Claude Code | 67 | 94 | 281 | 8종 |
| Cursor | 48 | — | — | 15 이벤트 |
| OpenCode | 12 | 35 | 37 | 11 |
| Codex | — | — | 10 (네이티브 포맷) | **없음** |
| Copilot | 없음 | — | — | 없음 |

---

## 4. MoAI-ADK와의 차이

### ECC에 없는 것

SPEC 문서 생명주기, EARS, REQ↔시나리오 추적성, @MX 태그, 3단계 리뷰 파이프라인, FROZEN/EVOLVABLE 헌법, 평가자 관대화 방지 메커니즘, LSP 위상별 게이트.

`spec-miner`(브라운필드 스펙 추출), `plan-canvas`, `prp-*` 커맨드가 있지만 **문서 세트를 버전 관리하며 추적성을 강제하는 계약**은 아닙니다.

### 설계 철학의 정반대 지점

| | MoAI | ECC |
|---|---|---|
| 커맨드 | Thin Command (20 LOC 미만, 단일 스킬 라우팅) | 94개 — 스스로 "legacy compatibility surface"로 강등, `skills/` 단일화 진행 중 |
| 컨텍스트 | Progressive Disclosure 3단계 | 카탈로그 규모로 승부, 선택 비용은 사용자 부담 |
| 방향성 | 계약 강제 | 카탈로그 확장 |

흥미로운 점: ECC가 지금 정리하려는 문제(커맨드 표면 비대)를 MoAI는 Thin Command로 이미 해결한 상태입니다.

---

## 5. 리스크

- 모든 성능 수치가 자체 보고. 외부 벤치마크 없음.
- 281개 스킬은 진입 시 선택 비용이 큼.
- **설치 경로 중첩 금지** — 플러그인 + `--profile full`을 같이 쓰면 스킬·훅·설정이 중복된다고 문서가 직접 경고.
- `multi-*` 커맨드는 별도 런타임(`ccg-workflow`) 의존. 없으면 정상 동작하지 않음.
- 식별자 3종이 서로 다름 — 저장소 `affaan-m/ECC`, 플러그인 `ecc@ecc`, npm `ecc-universal`.

---

## 6. 이식 후보

| 우선순위 | 항목 | 이유 |
|---|---|---|
| 높음 | **AgentShield 단발 감사** | `npx ecc-agentshield scan`으로 현재 `.claude/settings.json`·훅·MCP 설정 점검. MoAI를 건드리지 않고 독립 실행 가능. 과거 `env.PATH` 누락으로 훅이 조용히 no-op 되던 계열의 결함을 잡는 도구 |
| 높음 | **프롬프트 방어 베이스라인 6줄** | `CLAUDE.md` 상단 블록 이식. 비용 거의 0 |
| 중간 | **Instinct의 신뢰도 임계치 + 주입 상한** | Lessons Protocol에 개념만 차용. 전체 시스템 도입은 불필요 |

실행 전 주의: 외부 npm 패키지이므로 `pkg-check ecc-agentshield` 선검사를 먼저 거칠 것 (`core-skills/prevent-supply-chain-attack.md` 절차).
