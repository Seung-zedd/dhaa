#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash .dhaa/adapters/codex/bootstrap.sh [--apply]

Default: preview only. No files are written.
--apply: enable MoAI Codex wiring and install the local DHAA Codex skill.
EOF
}

apply=false
case "${1:-}" in
  "")
    ;;
  --apply)
    apply=true
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: run this script from inside a Git repository." >&2
  exit 1
fi

adapter_skill="$repo_root/.dhaa/adapters/codex/SKILL.md"
installed_skill="$repo_root/.agents/skills/dhaa/SKILL.md"

for cmd in codex moai; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found on PATH: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f "$repo_root/AGENTS.md" ]]; then
  echo "ERROR: missing root AGENTS.md; this snapshot does not contain the DHAA Codex adapter contract." >&2
  exit 1
fi

if [[ ! -f "$adapter_skill" ]]; then
  echo "ERROR: missing adapter skill: $adapter_skill" >&2
  exit 1
fi

# Do not fall back to 'moai init --force' or a broad 'moai update'.
# Existing DHAA snapshots can contain local template modifications, so only the
# dedicated additive Codex wiring command is accepted here.
if ! moai tool enable codex --help >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ERROR: this MoAI binary does not expose 'moai tool enable codex'.

Do not use 'moai init --force' as a workaround on a DHAA snapshot.
Upgrade/reconcile MoAI in the DHAA engine repository through its normal
dedicated update branch + review process, then rerun this bootstrap.
EOF
  exit 1
fi

echo "DHAA Codex adapter"
echo "  repo:    $repo_root"
echo "  codex:   $(codex --version 2>/dev/null | head -n 1 || echo present)"
echo "  moai:    $(moai version 2>/dev/null | head -n 1 || echo present)"
echo

echo "[1/2] MoAI Codex wiring preview"
moai tool enable codex --project-root "$repo_root" --dry-run

echo
echo "[2/2] DHAA skill deployment"
echo "  source: $adapter_skill"
echo "  target: $installed_skill"

if [[ "$apply" != true ]]; then
  echo
  echo "Preview complete. Nothing was written."
  echo "Run 'bash .dhaa/adapters/codex/bootstrap.sh --apply' to apply."
  exit 0
fi

echo
echo "Applying MoAI Codex wiring..."
moai tool enable codex --project-root "$repo_root"

echo "Installing local DHAA Codex skill..."
mkdir -p "$(dirname "$installed_skill")"
cp "$adapter_skill" "$installed_skill"

echo
echo "Codex adapter installed."
echo "Next:"
echo "  1. Run 'bash .dhaa/adapters/codex/doctor.sh'"
echo "  2. Start with 'moai codex' (preferred) or your approved Codex CLI launcher"
echo "  3. In Codex, use: \$dhaa plan <request>"
