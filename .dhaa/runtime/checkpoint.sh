#!/usr/bin/env bash
set -euo pipefail

reason="manual"
quiet=false

usage() {
  cat <<'EOF'
Usage: bash .dhaa/runtime/checkpoint.sh [--reason <label>] [--quiet]

Writes a deterministic, model-free recovery checkpoint to:
  .moai/state/dhaa-recovery.md

The checkpoint is local-only (under .moai/state) and is intended to survive
sudden provider errors, quota exhaustion, or an interrupted harness session.
EOF
}

while (($#)); do
  case "$1" in
    --reason)
      [[ $# -ge 2 ]] || { echo "ERROR: --reason requires a value" >&2; exit 2; }
      reason="$2"
      shift 2
      ;;
    --quiet)
      quiet=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: run this script from inside a Git repository." >&2
  exit 1
fi

state_dir="$repo_root/.moai/state"
checkpoint="$state_dir/dhaa-recovery.md"
mkdir -p "$state_dir"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
branch="$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
[[ -n "$branch" ]] || branch="(detached)"
head_sha="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || echo "(unknown)")"

candidate_progress=""
if compgen -G "$repo_root/.moai/specs/*/progress.md" >/dev/null; then
  candidate_progress="$(ls -1t "$repo_root"/.moai/specs/*/progress.md 2>/dev/null | sed -n '1p')"
fi
candidate_rel=""
if [[ -n "$candidate_progress" ]]; then
  candidate_rel="${candidate_progress#"$repo_root"/}"
fi

status="$(git -C "$repo_root" status --short --untracked-files=all 2>/dev/null || true)"
status_count="$(printf '%s\n' "$status" | awk 'NF {n++} END {print n+0}')"
diff_stat="$(git -C "$repo_root" diff --stat 2>/dev/null || true)"
diff_names="$(git -C "$repo_root" diff --name-status 2>/dev/null || true)"
cached_stat="$(git -C "$repo_root" diff --cached --stat 2>/dev/null || true)"
cached_names="$(git -C "$repo_root" diff --cached --name-status 2>/dev/null || true)"

tmp="$checkpoint.tmp.$$"
trap 'rm -f "$tmp"' EXIT

{
  echo "# DHAA Recovery Checkpoint"
  echo
  echo "> Machine-generated, model-free recovery state. Treat it as evidence, not as a completion claim."
  echo
  echo "- captured_at_utc: \`$timestamp\`"
  echo "- reason: \`$reason\`"
  echo "- branch: \`$branch\`"
  echo "- head: \`$head_sha\`"
  if [[ -n "$candidate_rel" ]]; then
    echo "- candidate_progress: \`$candidate_rel\`"
  else
    echo "- candidate_progress: none"
  fi
  echo "- working_tree_entries: $status_count"
  echo
  echo "## Git status (live at checkpoint)"
  echo
  echo '```text'
  if [[ -n "$status" ]]; then
    printf '%s\n' "$status" | sed -n '1,200p'
    if (( status_count > 200 )); then
      echo "... truncated: $((status_count - 200)) more entries"
    fi
  else
    echo "(clean)"
  fi
  echo '```'
  echo
  echo "## Unstaged diff summary"
  echo
  echo '```text'
  [[ -n "$diff_stat" ]] && printf '%s\n' "$diff_stat" || echo "(none)"
  [[ -n "$diff_names" ]] && { echo; printf '%s\n' "$diff_names"; }
  echo '```'
  echo
  echo "## Staged diff summary"
  echo
  echo '```text'
  [[ -n "$cached_stat" ]] && printf '%s\n' "$cached_stat" || echo "(none)"
  [[ -n "$cached_names" ]] && { echo; printf '%s\n' "$cached_names"; }
  echo '```'

  if [[ -n "$candidate_progress" && -f "$candidate_progress" ]]; then
    echo
    echo "## Candidate progress tail"
    echo
    echo "> Candidate only: newest progress.md by mtime. Verify the SPEC/handoff before continuing."
    echo
    echo '```text'
    tail -n 120 "$candidate_progress" 2>/dev/null || true
    echo '```'
  fi

  echo
  echo "## Recovery invariants"
  echo
  echo "- Do not assume an interrupted tool call or model turn completed."
  echo "- Re-read current Git state before any write, commit, push, or destructive action."
  echo "- Prefer a valid MoAI handoff when available; verify its preconditions against current state."
  echo "- If handoff is missing or stale, reconstruct from progress.md + current Git state + project requirements."
} >"$tmp"

mv -f "$tmp" "$checkpoint"
trap - EXIT

if [[ "$quiet" != true ]]; then
  echo "DHAA recovery checkpoint written: ${checkpoint#"$repo_root"/}"
fi
