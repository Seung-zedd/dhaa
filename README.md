# general-moai-adk

특정 도메인에 종속되지 않는 **MoAI-ADK 워크스페이스 컨테이너**입니다. Claude Code 엔진(에이전트·스킬·룰·훅)을 컨테이너 레벨에 한 번만 설치하고, 개별 앱은 하위 폴더에서 **상속**받아 사용합니다. 이 구조로 앱마다 CLAUDE.md(~29K)가 중복 로드되는 context bloat을 원천 차단합니다.

## 핵심 개념: 2-레이어 상속 모델

| 레이어 | 상속 여부 | 내용 |
|--------|-----------|------|
| **Claude Code 레이어** | ✅ 하위 폴더로 자동 상속 | `CLAUDE.md`, `.claude/`(agents/skills/rules/hooks/commands), `/moai` 슬래시 명령 |
| **`moai` 바이너리 레이어** | ❌ 로컬 `.moai/`만 인식 | `moai status`/`loop`/`fix`/quality gate — 앱마다 로컬 `.moai/` 필요 |

- Claude Code는 디렉토리 트리를 **위로 탐색**하므로, 앱 하위 폴더에서 세션을 열면 이 컨테이너의 엔진이 전부 로드됩니다 (앱의 `.claude/`가 비어 있어도 됨).
- `moai` 바이너리는 상속하지 않으므로 앱마다 `moai init`으로 로컬 `.moai/`만 확보합니다.

## 레포 구성

```
projects/                        ← 이 레포 (컨테이너)
├── CLAUDE.md                    # MoAI 오케스트레이터 지시문 (상속됨)
├── development_pipeline_guideline.md  # 에이전틱 개발 파이프라인 가이드
├── core-skills/                 # 글로벌 암묵지 룰셋 (CLAUDE.md가 @import)
├── .claude/                     # 엔진: agents/skills/commands/rules/hooks/output-styles
│   └── settings.json            # ⚠️ env.PATH가 머신 종속 — 아래 셋업 3번 참조
├── .moai/                       # 컨테이너 레벨 config (config/sections, project/brand 등)
├── .mcp.json                    # MCP 서버 정의 (토큰은 환경변수 참조)
├── pkg-supply-chain-check.sh    # npm 패키지 공급망 공격 사전 검사 스크립트
├── skills-lock.json             # 설치된 스킬 버전 잠금
└── (앱 폴더들)                   # git 추적 제외 — 각자 독립 레포
```

도메인 앱(예: pillwriter)과 로컬 런타임 상태(`.moai/reports|state|plans`, `.claude/tmp` 등)는 `.gitignore`의 "general-moai-adk container repo exclusions" 섹션으로 제외되어 있습니다.

## 클론 후 셋업

### 0. 사전 요구사항

- **Git** + **Git Bash** (Windows — 훅 스크립트가 bash로 실행됨)
- **Node.js** (LTS) — `npx` 필수 (ccstatusline 상태줄, 각종 툴링)
- **pnpm** — Node 패키지 관리는 pnpm만 사용
- **gh CLI** — `gh auth login`으로 인증 (GitHub MCP는 읽기 전용 엔드포인트라 쓰기 작업은 gh CLI로)
- **moai 바이너리** (moai-adk) — 공식 설치 가이드에 따라 설치 후 `moai --version`으로 확인
- **Claude Code** CLI

### 1. 클론

```bash
# 워크스페이스 컨테이너로 클론 (폴더명은 자유)
git clone git@github.com:Seung-zedd/general-moai-adk.git projects
cd projects
```

### 2. MCP 서버 설정

이 컨테이너가 실제로 사용하는 MCP 서버는 두 종류로 나뉩니다. **프로젝트 스코프**만 레포에 committed되고(`.mcp.json`), 나머지는 머신 종속(절대경로)이거나 계정 종속이라 committed하지 않습니다 — 클론 후 각자 `claude mcp add`로 설치하세요. 현재 상태는 `claude mcp list`로 확인합니다.

| 서버 | 스코프 | 전송 | 용도 | 설치 / 인증 |
|------|--------|------|------|-------------|
| **github** | 프로젝트 (`.mcp.json`) | HTTP (readonly) | 레포/이슈/PR 읽기 | `${GITHUB_PERSONAL_ACCESS_TOKEN}` 환경변수 등록. 쓰기 작업은 읽기 전용 엔드포인트라 `gh` CLI 사용 |
| **context7** | user | HTTP | 최신 라이브러리 문서 조회 | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` (API 키 불필요) |
| **serena** | user | stdio | LSP 심볼 검색·편집 | `uv`/`uvx` 설치 후 `claude mcp add serena -- uvx --from git+https://github.com/oraios/serena@v1.5.3 serena start-mcp-server --project-from-cwd --context claude-code` |
| **headroom** | user | stdio | 컨텍스트 압축 | `headroom` 패키지 설치 후 `claude mcp add headroom -- headroom mcp serve` |
| **pencil** | user | stdio | UI 디자인(.pen) 편집 | Pencil 데스크탑 앱 설치 후, 앱의 `mcp-server` 실행파일 경로로 `claude mcp add` (경로는 머신마다 다름) |
| **vercel** | plugin | HTTP | Vercel 배포·문서 | Claude Code 플러그인(`plugin:vercel:vercel`)으로 설치, `https://mcp.vercel.com` |
| **claude.ai** (Gmail/Calendar/Drive/Linear) | account | HTTP | Google/Linear 연동 | Claude 계정에 연결된 커넥터 — 세션 안에서 `/mcp`로 인증 |

- stdio 서버(serena/headroom/pencil)의 실행 경로는 **본인 머신의 설치 경로에 맞게** 지정하세요. 위 명령은 예시이며, 정확한 값은 원본 머신의 `claude mcp list` 출력을 참고합니다.
- 프로젝트 스코프 서버 활성화는 `.claude/settings.local.json`의 `enabledMcpjsonServers`로 제어됩니다(비추적, 머신 로컬).
- 예전에 시도했던 `moai-lsp`는 미동작으로 `.mcp.json`에서 제거되었습니다 — `enabledMcpjsonServers`에 잔여 참조가 있으면 정리하세요.

### 3. ⚠️ `.claude/settings.json`의 `env.PATH` 수정 (필수)

`env.PATH`는 원본 머신(`C:\Users\sdok1`) 전용 절대경로입니다. **본인 머신의 경로로 교체하세요**:

- Node.js 설치 경로 (예: `C:\Program Files\nodejs` / `/c/Program Files/nodejs`)
- npm 전역 경로 (예: `C:\Users\<you>\AppData\Roaming\npm`)
- moai 설치 경로 (예: `C:\Users\<you>\AppData\Local\Programs\moai`)

**수정하지 않으면 생기는 증상** (settings.json 내 `"//"` 주석 참조):
- `npx`가 exit 127로 죽어 ccstatusline **상태줄이 아예 안 뜸**
- moai 훅들이 에러 없이 **조용히 no-op** (MoAI 컨텍스트 주입 소실)

수정 후 반드시 **세션 재시작** — `statusLine`/`env` 블록은 세션 시작 시에만 로드됩니다.

### 4. 동작 확인

```bash
# 컨테이너에서 세션을 열어 엔진 로드 확인
claude   # 또는 moai cc
```

- 상태줄(ccstatusline)이 뜨는지 확인
- `/moai` 슬래시 명령이 인식되는지 확인

## 새 앱 추가 방법

> 상세 절차와 트러블슈팅은 `development_pipeline_guideline.md` 1단계 참조.

```bash
# 1) 컨테이너 루트에서 앱 스캐폴딩 (목적: 로컬 .moai/ 확보)
moai init my-new-app
cd my-new-app

# 2) 상속되는 중복본 제거 (context bloat 방지)
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles
# ⚠️ .claude/hooks는 절대 삭제 금지 — settings.json 훅이 상대경로로 참조 (상속 안 됨)
# 유지: .moai/, .claude/settings*.json, .claude/hooks, .gitignore, .mcp.json

# 3) statusLine 고정 (moai init이 만든 bash 래퍼는 Windows에서 실행 안 됨)
#    .claude/settings.json의 statusLine 블록을 아래로 교체:
#    {"type":"command","command":"npx -y ccstatusline@latest","padding":0,"refreshInterval":10}
rm .moai/status_line.sh

# 4) PRD.md를 앱 루트에 배치 후 세션 시작
moai cc
```

세션 안에서: `/moai project <이름>` → `/moai plan` → `/moai run SPEC-XXX` → `/moai loop`/`fix` → `/moai sync`

## 주의사항

- **`moai update`는 반드시 이 컨테이너 루트에서만** 실행 — 앱에서 실행하면 템플릿이 다시 밀려들어와 중복 제거·statusLine 고정을 재수행해야 합니다.
- **앱 폴더는 각자 독립 git 레포**로 관리 — 이 컨테이너 레포에는 절대 추적되지 않습니다 (`.gitignore` 참조). 새 앱 폴더를 만들면 exclusions 섹션에 폴더명을 추가하세요.
- **상태줄이 안 뜰 때 진단 순서**: ① 세션 재시작(1순위 원인) → ② `settings.json`의 `statusLine.command`가 `npx -y ccstatusline@latest`인지 확인 → ③ `env.PATH`에 nodejs 포함 여부(셋업 3번) → ④ `~/.config/ccstatusline/` 전역 설정 충돌.
- **패키지 설치 전** `pkg-supply-chain-check.sh`로 공급망 검사: `bash pkg-supply-chain-check.sh <package> [version]`
