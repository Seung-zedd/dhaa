#!/usr/bin/env bash
set -euo pipefail

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: run this script from inside a Git repository." >&2
  exit 1
fi

fail=0

ok()   { printf 'OK   %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*"; }
bad()  { printf 'FAIL %s\n' "$*"; fail=1; }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 is on PATH"
  else
    bad "$1 is not on PATH"
  fi
}

check_file() {
  if [[ -f "$repo_root/$1" ]]; then
    ok "$1 exists"
  else
    bad "$1 is missing"
  fi
}

echo "DHAA Codex adapter doctor"
echo "repo: $repo_root"
echo

check_cmd codex
check_cmd moai
check_file AGENTS.md
check_file .dhaa/constitution/core.md
check_file .dhaa/adapters/codex/SKILL.md
check_file .dhaa/runtime/checkpoint.sh
check_file .dhaa/runtime/recover.sh
check_file .agents/skills/dhaa/SKILL.md
check_file .codex/hooks.json
check_file .codex/config.toml

if [[ -f "$repo_root/.dhaa/adapters/codex/SKILL.md" && -f "$repo_root/.agents/skills/dhaa/SKILL.md" ]]; then
  if cmp -s "$repo_root/.dhaa/adapters/codex/SKILL.md" "$repo_root/.agents/skills/dhaa/SKILL.md"; then
    ok "installed DHAA skill matches adapter source"
  else
    bad "installed DHAA skill is stale; rerun bootstrap.sh --apply"
  fi
fi

if [[ -f "$repo_root/.codex/config.toml" ]]; then
  if grep -Eq '^\[mcp_servers\.moai\]' "$repo_root/.codex/config.toml"; then
    ok ".codex/config.toml contains [mcp_servers.moai]"
  else
    bad ".codex/config.toml does not contain [mcp_servers.moai]"
  fi
fi

if [[ -f "$repo_root/.codex/hooks.json" ]]; then
  if grep -q 'moai hook' "$repo_root/.codex/hooks.json"; then
    ok ".codex/hooks.json contains MoAI hook wiring"
  else
    bad ".codex/hooks.json contains no 'moai hook' wiring"
  fi
fi

for script in \
  "$repo_root/.dhaa/adapters/codex/bootstrap.sh" \
  "$repo_root/.dhaa/adapters/codex/doctor.sh" \
  "$repo_root/.dhaa/runtime/checkpoint.sh" \
  "$repo_root/.dhaa/runtime/recover.sh"; do
  if [[ -f "$script" ]]; then
    if bash -n "$script"; then
      ok "bash syntax: ${script#"$repo_root"/}"
    else
      bad "bash syntax: ${script#"$repo_root"/}"
    fi
  fi
done

if [[ -f "$repo_root/.claude/settings.json" ]]; then
  if grep -q '"matcher": "rate_limit|overloaded|' "$repo_root/.claude/settings.json"; then
    ok "Claude StopFailure matcher includes overloaded"
  else
    warn "Claude StopFailure matcher does not appear to include overloaded"
  fi
  if grep -q '.dhaa/runtime/checkpoint.sh' "$repo_root/.claude/settings.json"; then
    ok "Claude turn/failure checkpoint hook is wired"
  else
    warn "Claude checkpoint hook is not wired"
  fi
fi

if command -v moai >/dev/null 2>&1; then
  if moai tool enable codex --help >/dev/null 2>&1; then
    ok "MoAI additive Codex wiring command is available"
  else
    bad "MoAI additive Codex wiring command is unavailable"
  fi

  echo
  echo "MoAI Codex readiness (read-only):"
  if ! moai codex status; then
    warn "'moai codex status' did not complete successfully; inspect the output above"
  fi
fi

echo
echo "Capability note: DHAA Codex adapter intentionally assumes no subagent spawn."
echo "Independent-review steps must use an available MoAI audit/role surface or be reported as 'independence: degraded'."
echo "Recovery: use '$dhaa resume' in Codex, or 'bash .dhaa/runtime/recover.sh' from Git Bash."
echo "After wiring changes, verify/re-trust project hooks from Codex's /hooks UI when required."

if (( fail != 0 )); then
  echo
  echo "Codex adapter doctor: FAIL"
  exit 1
fi

echo
echo "Codex adapter doctor: PASS"
