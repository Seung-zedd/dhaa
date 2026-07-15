# 🚀 SaaS & Mobile App 에이전틱 개발 가이드라인 (MoAI-ADK 중심)

## ⚙️ 1. 개발 런타임 인프라 (Core Harness & Global Configuration)

특정 GUI 플랫폼 종속성을 원천 차단하기 위해, 클로드 코드 로컬 설정(`settings.local.json`) 혹은 `.claudeprofile`에 아래 **5개 핵심 마역 문서**와 **`skills.sh` 기반 범용 CLI 툴체인**을 바인딩하여 자율 최적화 파이프라인을 구축한다.

1. **글로벌 암묵지 룰셋 (Core Skills)**:

> 해당 마크다운 파일들은 "C:\Users\sdok1\projects\core-skills" 폴더에 있으므로 참고해서 그대로 플러그인 할 것.

- `skills/CLAUDE_TACIT_KNOWLEDGE.md` (Diff 중심의 토큰 최소화 기법으로 쿼터 방어)
- `skills/prevent-supply-chain-attack.md` (백엔드 공급망 공격 및 보안 취약점 차단)
- `skills/REPORT_RULE.md` (정량적 지표 중심의 포트폴리오 자동화 양산)
- `skills/CONTRIBUTING.md` (/whats-new 형식 변경 로그 자동화 및 깃 메시지 컨벤션 통제)
- `skills/RECOMMEND_WORKFLOW_CHAIN.md` (프로젝트 진행 단계별 MoAI 명령어 체인 라우팅 — 신규 기능/버그 수정/리팩토링/문서 갱신 워크플로우 자동 선택)

1. **독립형 오픈소스 및 클라우드 툴체인 (Platform-Agnostic Tools)**:
   - **기초 UI 및 대시보드 프로토타이핑**: `Pencil MCP Server` (구글 Pro 멤버십이 2026. 09. 23. 종료됨에 따라, 레이아웃 와이어프레임 설계 및 인터랙티브 구조 파악용 기초 도구로 제한 사용)
   - **고도화 UI 디자인 시스템 구축**: 구글 `나노바나나` (`https://stitch.withgoogle.com/`) -> 컴포넌트의 시각적 완성도를 극대화하고 고품질 UI 스타일 가이드를 에이전트에 피딩하기 위한 메인 디자인 스킬로 연동
     - **예외 가드레일 (Usage Limit 등 API 에러 발생 시)**: 에이전트 런타임 중 구글 계정 토큰 만료나 사용량 제한(Usage Limit) 에러가 감지되면, 에이전트는 즉시 프로세스를 일시정지하고 사용자에게 수동 액션을 요청하는 알림을 띄운다.
     - **사용자 수동 가이드 프롬프트**: *"현재 구글 디자인 서버의 호출 제한 또는 세션 만료가 감지되었습니다. 개발자님, 브라우저를 열고 Pro 멤버십이 활성화된 계정 세션 주소인 `https://stitch.withgoogle.com/u/1/?pli=1` 로 직접 접속하여 인증 상태를 갱신해 주세요."* 문구를 명시하고 검증 대기 상태로 전환한다.
   - **UI 비전 및 E2E 통제**: `Playwright CLI` + `ui-ux-pro-max-skill` (모바일 뷰포트 레이아웃 최종 무결성 스캔, 클릭 자율 테스트 수행 및 레이아웃 깨짐 교정)
   - **자가 치유 런타임**: 테스트 러너 로그 파서 스킬을 연동하여 `moai loop` 구동 시 런타임 콘솔 에러 자동 트래킹 및 자가 교정
   - **성능 게이트**: `k6` 또는 `Lighthouse CLI`를 통해 API 및 웹훅 라우팅 지연 시간을 계측하고, 임계치 초과 시 `moai fix` 자동 트리거
   - **지식 인덱싱**: `skills.sh`에서 검증된 최신 공식 도큐먼트(Vercel, Spring Boot 3.x 등) 가이드라인 스킬 주입

---

## 🎯 2. 단계별 자율 자동화 파이프라인 (Workflow)

### [1단계] 개발 환경 초기화 및 기획 문서 주입 (Initialization & PRD Seeding)

> **[워크스페이스 상속 모델 — 필독]**
> `C:\Users\sdok1\projects\`는 **개별 프로젝트가 아니라 공유 MoAI 엔진을 담은 워크스페이스 컨테이너**다. 여기에 이미 `moai init`이 되어 있어 `CLAUDE.md` + `.claude/`(에이전트 24개·스킬·룰·훅) + `.moai/config`가 설치돼 있다.
> Claude Code는 **하위 폴더에서 세션을 열면 상위의 `CLAUDE.md`와 `.claude/` 엔진을 자동 상속**한다(검증됨: 하위 프로젝트의 `.claude/`가 비어 있어도 풀 MoAI가 로드됨). 반면 **`moai` 바이너리(status·loop·fix·quality gate)는 상속하지 않고 로컬 `.moai/`만 본다**(검증됨: 로컬 `.moai/` 없는 폴더는 "Not initialized"로 뜸).
> 따라서 **레이어를 분리**한다 — 무거운 지시문/엔진(`CLAUDE.md`, `.claude/`)은 컨테이너에서 **상속**받고, 바이너리가 필요로 하는 `.moai/`만 앱마다 **로컬**로 둔다. 이렇게 하면 `CLAUDE.md`(약 29K) 중복 로드로 인한 컨텍스트 bloat가 사라진다.

- **명령어 (신규 앱 생성 시)**:
  1. `moai init my-new-app` — 앱 폴더 + 스캐폴딩 생성. **목적은 오직 로컬 `.moai/`(config·specs·loop 상태) 확보**. (컨테이너 `projects/`는 이미 초기화돼 있으니 재-init 금지)
  2. **중복 제거 (bloat 방지, 핵심 단계)**: 방금 생성된 앱 폴더 안에서 상위로부터 상속되는 무거운 복제본을 삭제한다.
     - `rm CLAUDE.md` (상위 `projects/CLAUDE.md`가 커버 — 이걸 지워야 29K 중복 로드가 사라짐)
     - `rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles` (엔진은 상위에서 상속)
     - **`.claude/hooks`는 절대 삭제 금지 (SPEC-확인됨, 2026-07-05 트러블슈팅)**: `.claude/settings.json`(로컬 유지 대상)의 `SessionStart` 등 각종 훅 항목이 `$CLAUDE_PROJECT_DIR/.claude/hooks/moai/*.sh`를 **상대경로로 직접 참조**한다. `.claude/hooks`는 `CLAUDE.md`/`.claude` 엔진과 달리 상위 `projects/`에서 자동 상속되지 않으므로, 이 폴더를 지우면 세션 시작마다 `SessionStart:startup hook error`(`No such file or directory`)가 non-blocking으로 발생한다. 이 훅 실패는 세션 자체를 막지는 않지만 그 여파로 **ccstatusline 상태줄이 통째로 렌더링되지 않는 증상**으로 이어진다("상태줄이 안 뜬다"의 실제 근본 원인 중 하나 — 아래 statusLine 진단 순서보다 먼저 확인할 것). 만약 실수로 삭제했다면 `cp -r projects/.claude/hooks/. my-new-app/.claude/hooks/`로 복구한다.
     - **유지**: `.moai/`(바이너리 필수), `.claude/settings*.json`, `.claude/hooks`(위 이유로 필수), `.gitignore`, `.mcp.json`
     - **statusLine 고정 (ccstatusline 통일, 핵심 단계)**: `moai init`은 매번 `.moai/status_line.sh`(bash 래퍼)를 생성하고 `.claude/settings.json`의 `statusLine.command`가 이를 가리키도록 설정한다. 그러나 이 bash 래퍼는 **Windows Claude Code 셸에서 실행되지 않아 상태줄이 아예 뜨지 않는다**. 따라서 앱마다 컨테이너 `projects/`·글로벌과 동일하게 맞춘다:
       - `.claude/settings.json`의 `statusLine` 블록을 `{"type":"command","command":"npx -y ccstatusline@latest","padding":0,"refreshInterval":10}`로 교체
       - `rm .moai/status_line.sh` (더 이상 참조하지 않음)
       - **이유**: `settings.json`은 `CLAUDE.md`/`.claude` 엔진과 달리 **상속되지 않고 로컬(앱 폴더)이 우선**하므로, 앱마다 직접 고정하지 않으면 상위의 ccstatusline 설정이 적용되지 않는다. `npx` 명령은 Windows에서도 정상 동작한다.
       - **[필독] 설정 수정 후 반드시 세션 재시작**: `statusLine` 블록은 **세션 시작 시점에만 로드되고 실행 중에는 핫리로드되지 않는다.** 따라서 이미 열려 있는 세션에서 `settings.json`을 고쳐도 상태줄은 그대로 안 뜬다 — 파일이 올바르게 고쳐져 있어도 화면에 반영되려면 세션을 한 번 종료 후 재시작(`/exit` → `moai cc`)해야 한다. **"상태줄이 안 뜬다"는 증상의 1순위 원인은 설정 오류가 아니라 이 세션 미리로드다.** 진단 순서: (1) `.claude/settings.json`의 `statusLine.command`가 `npx -y ccstatusline@latest`인지 확인 → (2) 해당 앱 폴더에서 `echo '{"model":{"display_name":"Opus 4.8"}}' | npx -y ccstatusline@latest` 로 명령 자체가 출력을 내는지 확인 → (3) 둘 다 정상인데 화면에 없으면 **세션 재시작**이 해답 → (4) 그래도 안 뜨면 `settings.json`의 `env.PATH`(아래 제3원인 항목)를 점검하고, 마지막으로 `~/.config/ccstatusline/` 전역 설정 충돌을 의심한다.
       - **[필독] 제3의 근본 원인 — env.PATH에 Node.js 누락 (확인됨, 2026-07-05 pillwriter 트러블슈팅)**: `.claude/settings.json`의 `env.PATH` 오버라이드에 Node.js/npm 경로가 빠져 있으면, Claude Code가 statusLine 서브프로세스에 이 PATH를 주입하므로 `npx -y ccstatusline@latest`가 `npx: command not found`(exit 127)로 죽어 상태줄이 **0바이트 출력 → 아예 렌더링되지 않는다**. `npx`는 `C:\Program Files\nodejs`와 `C:\Users\sdok1\AppData\Roaming\npm`에만 존재한다. 같은 PATH 문제의 부수 피해로 `moai.exe`도 해석 불가가 되어 26개 moai 훅 래퍼가 **에러 없이 조용히 no-op** 된다(MoAI 컨텍스트 주입 소실 — SessionStart는 exit 0으로 성공처럼 보임). 해결: 앱 `settings.json`의 `env.PATH`를 컨테이너 `projects/.claude/settings.json`의 검증된 값(`C:\Users\sdok1\AppData\Roaming\npm;C:\Users\sdok1\AppData\Local\Programs\moai;…`로 시작, `/c/Program Files/nodejs` 포함)으로 교체 후 세션 재시작. 진단 시 함정: 터미널에서 직접 돌리는 위 (2)번 테스트는 터미널의 온전한 PATH를 쓰므로 이 원인을 **놓친다** — 반드시 `settings.json`의 PATH 값을 환경변수로 넣고 **새 bash.exe를 스폰**해 테스트한다(이미 실행 중인 bash 안에서 `env PATH=...`로 덮으면 Windows 형식 PATH가 MSYS 변환되지 않아 가짜 음성이 나온다).
     - 주의: `moai update`는 템플릿을 다시 밀어넣으므로, 업데이트는 앱이 아니라 **컨테이너 `projects/`에서만** 수행한다. (앱에서 `moai update` 실행 시 `.moai/status_line.sh`와 엔진 복제본이 다시 생성되므로, 실행했다면 위 statusLine 고정·중복 제거를 재수행한다.)
  3. *(수동 작업)*: 기존에 빌드된 구글 독스 기반의 **`PRD.md`** 파일을 앱 폴더 루트에 배치
  4. **앱 폴더에서 Claude Code 세션을 연다**: 터미널에서 `cd my-new-app && moai cc` (`moai cc`가 Claude Code를 현재 폴더 기준으로 실행 → `$CLAUDE_PROJECT_DIR`가 앱을 가리켜 SPEC·리포트가 **앱 로컬 `.moai/`에** 쌓인다)
  5. 세션 안에서 `/moai project [프로젝트명]` 실행 (예: `/moai project 스마트 디톡스`)
- **용어 주의 — 바이너리 vs 슬래시 명령**:
  - **터미널 바이너리**: `moai init`, `moai update`, `moai status`, `moai cc/cg/glm`(Claude Code 실행)
  - **Claude Code 내부 슬래시 명령**: `/moai project`, `/moai plan`, `/moai run`, `/moai loop`, `/moai fix`, `/moai sync` — 이하 2~5단계의 `moai xxx` 표기는 전부 세션 안에서 실행하는 **`/moai` 슬래시 명령**이다(동일 이름의 바이너리 서브명령은 존재하지 않음).
- **동작**:
  - `moai init`은 오케스트레이션 엔진이 아니라 **로컬 `.moai/` 샌드박스만** 확보하기 위한 것이다(엔진은 상속). `PRD.md`를 앱 루트에 넣어 에이전트에게 기획 콘텍스트를 선제 주입한다.
  - 에이전트는 주입된 `PRD.md`를 기반으로 아키텍처 진입점과 디렉토리 구조(PID)를 자율 수립하되, 명세가 모호하거나 누락된 섹션에 대해서만 Charmbracelet(`huh`/`bubbletea`) 인터랙티브 인터뷰를 주동하여 스펙을 정교하게 최종 구체화한다.
  - 이후 모든 산출물(SPEC, 리포트, loop 스냅샷)은 세션을 연 앱 폴더의 로컬 `.moai/`에 격리 저장되어 프로젝트 간 혼선이 없다.

### [2단계] 명세 분해 및 테스크 쪼개기

- **명령어**: `moai plan`
- **동작**: 확정된 기획서(PID) 및 `PRD.md` 요구사항을 교차 파싱하여 기능별 원자 단위의 할 일 목록으로 쪼갠 뒤 SPEC 문서는 manager-spec 에이전트가 자동으로 생성합니다. 개발자가 직접 EARS 형식을 외울 필요 없이, 만약에 PRD 문서가 없고 자연어로 요청하면 에이전트가 변환합니다.
- **주의**: `/moai plan` 실행 시 하나의 SPEC 디렉토리 안에 3개 파일이 동시에 생성됩니다. 이때, 아래의 3단계로 넘어가기 전에, 사용자한테 `.moai/specs` 폴더에 있는 모든 문서들은(e.g. `spec.md`, `plan.md`, `acceptance.md`) 반드시 직접 읽어보라고 프롬프트로 명시할 것. 그리고 잘못되어 있는 사항을 발견하면 사용자한테 수정 사항을 요청하라는 문구도 프롬프트에 명시할 것.

### [3단계] 명세 기반 소스코드 구현

- **명령어**: `moai run [스펙번호]`
- **동작**: 분해된 `SPEC.md`와 `Pencil MCP Server`의 1차 레이아웃, 그리고 구글 `나노바나나` 가이드라인 및 `ui-ux-pro-max-skill` 컨벤션을 복합 참조하여 모바일 뷰포트/반응형 프런트엔드 컴포넌트와 백엔드 API를 기획 사양에 완벽히 일치하게 구현한다.
  - 만약에 Pencil MCP Server가 활성화되지 않으면, 유저한테 Pencil 데스크탑 앱을 실행하라고 프롬프트로 명시할 것.

### [4단계] 자가 치유 및 무한 루프 검증

- **명령어**: `moai loop [스펙번호]` 또는 `moai fix`
- **동작**: LSP 구문 스캔, 린터, 테스트 빌드를 수행하고, 에러 발생 시 테스트 커버리지 85%를 통과할 때까지 스스로 버그를 잡는 자가 치유(Self-Healing) 무한 루프를 구동한다.

### [5단계] 사양 동기화 및 기록 자동화

- **명령어**: `moai sync`
- **동작**: 구현 완료 후 코드를 명세서에 역동기화한다. 동시에 `REPORT_RULE.md`에 의거한 포트폴리오 문서화와 `CONTRIBUTING.md` 규칙에 따른 릴리즈 로그(/whats-new 형식을 활용한 변경점 요약 및 커밋 메시지 생성)를 수행한 뒤 안전하게 커밋 및 푸시를 실행한다.

---

## 🔒 3. 품질 및 리소스 관리 가드레일 (Limits)

- **토큰 최적화 통제 (Harness)**: 세션의 `ccstatusline` 게이지가 40~50% 임계치에 도달하면 즉시 수동 컴팩트(`/clear` 또는 `/compact`)를 트리거하여 불필요한 토큰 낭비를 원천 차단한다.
- **UI 무결성 검증**: 컴포넌트 양산 시 `Pencil MCP`를 통해 뼈대를 잡고 `나노바나나` 연동 데이터로 고도화하여 시각적 무결성을 확보하며, `ui-ux-pro-max-skill` 가이드라인을 위반하는 레이아웃 깨짐이나 터치 영역 오버랩이 발견되면 즉시 `moai fix`로 자가 교정한다.
