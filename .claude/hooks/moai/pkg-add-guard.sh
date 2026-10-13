#!/usr/bin/env bash
# pkg-add-guard.sh - PreToolUse fast supply-chain gate for pnpm/npm/yarn add-type commands.
#
# Vendored under .claude/hooks/moai/ (not an absolute path) so $CLAUDE_PROJECT_DIR-relative
# references stay portable across machines and repos (same convention as the other handle-*.sh
# hooks here, and as C:\Users\sdok1\projects\core-skills\* being vendored into sub-apps).
#
# This is deliberately a SUBSET of pkg-supply-chain-check.sh: registry-metadata lookup +
# lifecycle-script scan only (no pnpm audit, no lockfile generation, no interactive pause).
# It exists to fit inside a blocking PreToolUse hook (seconds, not tens of seconds).
# For the full deep check (release history, maintainers, dependency-tree audit), run the
# manual `pkg-check <package> [version]` alias documented in prevent-supply-chain-attack.md.
#
# Decision policy: deny only on an unambiguous signal (exact match against the historically
# hijacked package list). Everything else that looks worth a second look (lifecycle scripts,
# a registry lookup that failed) becomes "ask" so a human/Claude confirms rather than silently
# blocking or silently installing.
#
# No jq dependency, by design (matches pkg-supply-chain-check.sh's own approach): node is
# already required for pnpm/npm work, so it is guaranteed present wherever this hook can fire.
set -uo pipefail

SUSPICIOUS_LIST="chalk debug ansi-styles strip-ansi colors braces"

INPUT="$(cat)"
COMMAND="$(node -e "
  let d = '';
  process.stdin.on('data', c => d += c).on('end', () => {
    try { process.stdout.write((JSON.parse(d).tool_input || {}).command || ''); } catch (e) {}
  });
" <<< "$INPUT")"
[ -z "$COMMAND" ] && exit 0

# Cheap pre-filter so every other Bash call (the vast majority) pays only this grep.
# Matches at the start of the command or after a chain operator (&&, ;, |) so
# `cd app && pnpm add lodash` is still caught, not just a bare `pnpm add lodash`.
printf '%s' "$COMMAND" | grep -Eq '(^|[;&|]) *(pnpm add|npm install|npm add|yarn add|npm i\b)' || exit 0

# Strip everything up through the subcommand keyword; longest-alternative-first so
# "npm install" is preferred over "npm i" matching as a substring of it.
REST="$(printf '%s' "$COMMAND" | sed -E 's/^.*(pnpm add|npm install|npm add|yarn add|npm i)//')"

PACKAGES=()
for tok in $REST; do
  case "$tok" in
    -*) ;;                 # skip flags: --save-dev, -D, -g, --ignore-scripts, ...
    *) PACKAGES+=("$tok") ;;
  esac
done
[ "${#PACKAGES[@]}" -eq 0 ] && exit 0   # bare install/restore from lockfile — nothing new to vet

emit() {
  # $1 = "deny"|"ask", $2 = reason text shown to the user/Claude
  node -e "
    console.log(JSON.stringify({hookSpecificOutput:{hookEventName:'PreToolUse',permissionDecision:process.argv[1],permissionDecisionReason:process.argv[2]}}));
  " "$1" "$2"
  exit 0
}

NOTES=""

for spec in "${PACKAGES[@]}"; do
  if [[ "$spec" == @*@* ]]; then
    VER="${spec##*@}"; NAME="${spec%@*}"
  elif [[ "$spec" == @* ]]; then
    NAME="$spec"; VER="latest"
  elif [[ "$spec" == *@* ]]; then
    NAME="${spec%@*}"; VER="${spec##*@}"
  else
    NAME="$spec"; VER="latest"
  fi

  for s in $SUSPICIOUS_LIST; do
    if [ "$NAME" = "$s" ]; then
      emit deny "'$NAME' is on the historically-hijacked package list ($SUSPICIOUS_LIST). Run 'pkg-check $NAME $VER' manually and review before installing."
    fi
  done

  TARBALL_URL="$(pnpm view "$NAME@$VER" dist.tarball 2>/dev/null | tr -d '[:space:]')"
  if [ -z "$TARBALL_URL" ]; then
    emit ask "Could not verify '$NAME@$VER' against the registry (lookup failed, or the package/version does not exist). Confirm before installing."
  fi

  TMPDIR="$(mktemp -d)"
  if ! curl -fsSL --max-time 10 "$TARBALL_URL" -o "$TMPDIR/pkg.tgz" 2>/dev/null; then
    rm -rf "$TMPDIR"
    emit ask "Could not download the tarball for '$NAME@$VER' (network/timeout). Confirm before installing."
  fi
  tar -xzf "$TMPDIR/pkg.tgz" -C "$TMPDIR" 2>/dev/null

  PKG_JSON="$TMPDIR/package/package.json"
  if [ -f "$PKG_JSON" ]; then
    HIT="$(node -e "
      try {
        const p = require(process.argv[1]);
        const keys = ['preinstall','install','postinstall','prepare','prepublish','prepublishOnly'];
        console.log(keys.filter(k => p.scripts && p.scripts[k]).join(','));
      } catch (e) {}
    " "$PKG_JSON" 2>/dev/null)"
    [ -n "$HIT" ] && NOTES="${NOTES}'$NAME@$VER' declares lifecycle script(s): $HIT. "
  fi
  rm -rf "$TMPDIR"
done

if [ -n "$NOTES" ]; then
  emit ask "${NOTES}pnpm 10+ blocks dependency lifecycle scripts by default (onlyBuiltDependencies allowlist), but confirm this is expected before proceeding."
fi

exit 0
