#!/usr/bin/env bash
set -euo pipefail

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: run this script from inside a Git repository." >&2
  exit 1
fi

checkpoint="$repo_root/.moai/state/dhaa-recovery.md"

echo "# DHAA Recovery Bundle"
echo
echo "> Reconcile before continuing. A handoff or checkpoint is evidence, not proof that the interrupted action completed."
echo

echo "## Live repository state"
echo
echo "- root: $repo_root"
echo "- branch: $(git -C "$repo_root" branch --show-current 2>/dev/null || echo "(unknown)")"
echo "- head: $(git -C "$repo_root" rev-parse HEAD 2>/dev/null || echo "(unknown)")"
echo
echo '```text'
live_status="$(git -C "$repo_root" status --short --untracked-files=all 2>/dev/null || true)"
[[ -n "$live_status" ]] && printf '%s\n' "$live_status" || echo "(clean)"
echo '```'
echo

echo "## Saved MoAI handoff candidate"
echo
handoff=""
if command -v moai >/dev/null 2>&1 && moai handoff show --help >/dev/null 2>&1; then
  handoff="$(moai handoff show --project-dir "$repo_root" 2>/dev/null || true)"
fi
if [[ -n "$handoff" ]]; then
  echo "> Candidate only. Verify every precondition against the live repository state before using it."
  echo
  echo '```text'
  printf '%s\n' "$handoff"
  echo '```'
else
  echo "(no readable MoAI handoff found)"
fi
echo

echo "## Last deterministic checkpoint"
echo
if [[ -f "$checkpoint" ]]; then
  cat "$checkpoint"
else
  echo "(no .moai/state/dhaa-recovery.md checkpoint found)"
fi
echo

echo "## Recent SPEC progress candidates"
echo
progress_candidates=()
if compgen -G "$repo_root/.moai/specs/*/progress.md" >/dev/null; then
  while IFS= read -r path; do
    progress_candidates+=("$path")
  done < <(ls -1t "$repo_root"/.moai/specs/*/progress.md 2>/dev/null | sed -n '1,5p')
fi

if ((${#progress_candidates[@]} == 0)); then
  echo "(no progress.md files found)"
else
  i=1
  for path in "${progress_candidates[@]}"; do
    echo "$i. ${path#"$repo_root"/}"
    ((i++))
  done

  newest="${progress_candidates[0]}"
  echo
  echo "### Newest candidate tail"
  echo
  echo "> This is an mtime heuristic, not an active-SPEC assertion."
  echo
  echo '```text'
  tail -n 120 "$newest" 2>/dev/null || true
  echo '```'
fi
echo

echo "## Project requirement entry points"
echo
for f in PRD.md README.md .moai/project/product.md .moai/project/structure.md .moai/project/tech.md; do
  if [[ -f "$repo_root/$f" ]]; then
    echo "- $f"
  fi
done
echo

echo "## Recovery order"
echo
echo "1. Prefer a current MoAI handoff when one exists, but verify its preconditions."
echo "2. Identify the correct SPEC from the handoff, checkpoint, or progress candidates."
echo "3. Read that SPEC's progress.md plus the minimum spec/plan files needed."
echo "4. Reconcile checkpoint Git state with the live branch/HEAD/status/diff."
echo "5. Treat the interrupted turn as incomplete unless repository/tool evidence proves otherwise."
echo "6. Only then continue the next unverified action."
