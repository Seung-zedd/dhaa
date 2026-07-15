#!/usr/bin/env bash
# pkg-supply-chain-check.sh - 패키지 공급망 공격 방지 안전성 검사 스크립트 (pnpm 기반)
#
# Claude Code 등 AI 코딩 에이전트가 패키지 설치를 제안할 때, 실제 설치 전에
# 해당 패키지의 안전성을 검증하기 위한 범용 스크립트입니다.
# C:\Users\sdok1\projects 등 글로벌 환경 및 개발 폴더에서 실행 가능하도록 최적화되었습니다.
# 외부 jq 의존성 없이 pnpm과 함께 설치된 node를 활용해 동작합니다.
# 2026-07-11: npm → pnpm 전환 (프로젝트 표준 패키지 매니저가 pnpm으로 통일됨).
#
# 사용법:
#   1. pkg-check <package_name>
#   2. pkg-check <package_name> <version>
#
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "사용법: pkg-check <package_name> [version]"
  echo "예시: pkg-check chalk"
  echo "예시: pkg-check chalk 5.0.0"
  exit 1
fi

PKG="$1"
VER="${2:-latest}"
TMPDIR="$(mktemp -d /tmp/pkg-check-XXXX)"
CWD="$(pwd)"
SUSPICIOUS_LIST=("chalk" "debug" "ansi-styles" "strip-ansi" "colors" "braces")

echo "=== 패키지 안전 검사 시작 (pnpm) ==="
echo "패키지: $PKG@$VER"
echo "임시 디렉터리: $TMPDIR"
echo

cd "$TMPDIR"

# 0) 사전 검사: pnpm 존재 여부
if ! command -v pnpm >/dev/null 2>&1; then
  echo "오류: pnpm이 설치되어 있지 않습니다. corepack enable 또는 pnpm을 설치해 주세요."
  exit 1
fi

# 1) 레지스트리 메타데이터 확인
echo "1) 레지스트리 메타데이터 조회 (pnpm view)..."
echo "----------------------------------------"
pnpm view "$PKG@$VER" time --json || true
echo
echo "관리자(Maintainers):"
pnpm view "$PKG@$VER" maintainers --json || true
echo
echo "최근 버전 목록:"
pnpm view "$PKG" versions --json | node -e "let d=''; process.stdin.on('data', c=>d+=c).on('end', ()=>{ try{ console.log(JSON.stringify(JSON.parse(d).slice(-10), null, 2)); }catch(e){} })" || true
echo "----------------------------------------"
echo

# 2) tarball 다운로드(안전) 및 내부 파일 확인
#    pnpm pack은 로컬 프로젝트 전용이므로, 레지스트리의 tarball URL을 조회해 직접 내려받는다.
echo "2) tarball 다운로드 및 내부 파일 확인..."
TARBALL_URL="$(pnpm view "$PKG@$VER" dist.tarball | tr -d '[:space:]')"
if [ -z "$TARBALL_URL" ]; then
  echo "오류: tarball URL을 조회하지 못했습니다. 패키지명/버전을 확인하세요."
  exit 1
fi
TGZ="pkg-check.tgz"
curl -fsSL "$TARBALL_URL" -o "$TGZ"
echo "다운로드된 tarball: $TGZ ($TARBALL_URL)"
echo "tarball 내부 파일 목록:"
tar -tzf "$TGZ"
echo

# 3) package.json 추출 및 주요 필드 점검
echo "3) package.json 내용(중요 필드) 확인..."
mkdir -p inspect
tar -xzf "$TGZ" -C inspect
PKG_JSON="inspect/package/package.json"

if [ -f "$PKG_JSON" ]; then
  echo "-> package.json 경로: $PKG_JSON"
  echo "scripts:"
  node -e "try{ console.log(JSON.stringify(require('./$PKG_JSON').scripts, null, 2)); }catch(e){}" 2>/dev/null || cat "$PKG_JSON" | grep -E '"scripts"' -A5 || true
  echo
  echo "dependencies:"
  node -e "try{ console.log(JSON.stringify(require('./$PKG_JSON').dependencies, null, 2)); }catch(e){}" 2>/dev/null || cat "$PKG_JSON" | grep -E '"dependencies"' -A10 || true
  echo
  echo "devDependencies:"
  node -e "try{ console.log(JSON.stringify(require('./$PKG_JSON').devDependencies, null, 2)); }catch(e){}" 2>/dev/null || cat "$PKG_JSON" | grep -E '"devDependencies"' -A10 || true
else
  echo "경고: package.json을 찾을 수 없습니다."
fi
echo

# 4) package.json에 의심스러운 lifecycle script가 있는지 체크
echo "4) lifecycle script 검사 (preinstall, install, postinstall, prepare 등)..."
for key in preinstall install postinstall prepare prepublish prepublishOnly; do
  if node -e "const pkg=require('./$PKG_JSON'); process.exit(pkg.scripts && pkg.scripts['$key'] ? 0 : 1)" >/dev/null 2>&1; then
    echo "주의: scripts.$key 존재: "
    node -e "console.log(require('./$PKG_JSON').scripts['$key'])" 2>/dev/null || true
  fi
done
echo "참고: pnpm 10+는 기본적으로 의존성 lifecycle 스크립트를 차단하며,"
echo "      onlyBuiltDependencies 허용 목록에 있는 패키지만 빌드 스크립트를 실행합니다."
echo

# 5) 의존성 목록 스캔 (과거 취약/의심 패키지 검사)
echo "5) 의존성에서 과거 문제가 됐던 패키지 검색..."
FOUND=0
for s in "${SUSPICIOUS_LIST[@]}"; do
  if node -e "const pkg=require('./$PKG_JSON'); const keys=Object.keys({...pkg.dependencies, ...pkg.devDependencies}); keys.forEach(k=>console.log(k))" 2>/dev/null | grep -E "^${s}$" >/dev/null 2>&1; then
    echo "의심 패키지 발견: $s"
    FOUND=1
  fi
done
if [ "$FOUND" -eq 0 ]; then
  echo "의심 패키지(예: chalk/debug 등) 직접 포함되지 않음(단, 하위 의존성으로 포함될 수 있음)."
fi
echo

# 6) lockfile 생성 (의존성 트리 확보) — 실제 스크립트 실행은 차단
echo "6) pnpm-lock.yaml 생성 (스크립트 실행 차단: --ignore-scripts + --lockfile-only)"
pnpm init >/dev/null 2>&1 || true
# lockfile만 생성 (설치/빌드/스크립트는 수행하지 않음)
pnpm add "$PKG@$VER" --lockfile-only --ignore-scripts >/dev/null 2>&1 || true

if [ -f pnpm-lock.yaml ]; then
  echo "pnpm-lock.yaml 생성됨."
  echo "의존성 트리(packages 섹션 상위 일부):"
  grep -E "^  [^ ].*:$" pnpm-lock.yaml | sed 's/:$//' | sed -n '1,200p' || true
else
  echo "pnpm-lock.yaml 생성 실패—권한/네트워크 확인 필요."
fi
echo

# 7) pnpm audit 실행 (알려진 취약점 검사)
echo "7) pnpm audit 실행 (JSON 출력 저장: audit.json)"
pnpm audit --prod --json > audit.json 2>/dev/null || true
if [ -s audit.json ]; then
  echo "audit.json 생성됨 — 요약:"
  node -e "try{ const a=require('./audit.json'); console.log(JSON.stringify(a.metadata && (a.metadata.vulnerabilities || a.metadata.summary) || {}, null, 2)); }catch(e){}" 2>/dev/null || true
  echo "상세 취약점(심각도 높은 순, 최대 20개):"
  node -e "try{ const audit=require('./audit.json'); const vulns=audit.advisories||audit.vulnerabilities||{}; const entries=Object.entries(vulns).map(([k,v])=>({key:k,val:v,w:{'critical':4,'high':3,'moderate':2,'low':1,'info':0}[v.severity||'info']||0})); entries.sort((a,b)=>b.w-a.w); console.log(JSON.stringify(entries.slice(0,20).map(e=>({[e.key]:e.val})), null, 2)); }catch(e){}" 2>/dev/null || true
else
  echo "audit.json 비어있거나 취약점 없음."
fi
echo

# 8) 네트워크/포스트 인스펙션 힌트
echo "8) 추가 검사 팁"
echo "- tarball의 package.json에 lifecycle 스크립트가 있으면 수동으로 내용(명령)을 검토하세요."
echo "- 의심되는 스크립트(예: curl, wget, powershell 호출이나 루트 디렉터리 재귀 삭제 등) 발견 시 설치 중단 권장."
echo "- audit에서 HIGH/CRITICAL 취약점이 나오면 의존성 전체를 수동 분석 필요."
echo "- 실제 설치 시에도 pnpm의 기본 스크립트 차단을 유지하고, 빌드가 필요한 패키지만 onlyBuiltDependencies에 명시적으로 허용하세요."
echo

# 결과 요약 위치
echo "검사 결과 파일:"
ls -l "$TGZ" pnpm-lock.yaml audit.json inspect/package/package.json 2>/dev/null || true
echo
echo "=== 검사 완료 ==="
echo "임시 디렉터리 ($TMPDIR) 를 유지하려면 아무 키나 누르세요. 삭제하려면 10초 후 자동 삭제됩니다..."
read -r -t 10 || true

# 자동 정리
echo "임시 디렉터리 삭제 중..."
cd "$CWD"
rm -rf "$TMPDIR"
echo "임시 파일 삭제 완료. 필요하면 스크립트를 다시 실행하세요."
