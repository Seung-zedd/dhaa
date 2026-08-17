#!/usr/bin/env node
// PreToolUse guard: hard-blocks two npm supply-chain attack vectors on the
// Bash tool, independent of permissions.deny (so it also fires under
// bypassPermissions / acceptEdits / auto modes):
//
//   1. npm install / npm i / npm ci without --ignore-scripts. A compromised
//      dependency's preinstall/install/postinstall lifecycle script runs
//      automatically the moment the package is installed — that automatic
//      execution, not the install command itself, is the actual mechanism
//      behind most recent npm worm/credential-theft incidents. Requiring
//      --ignore-scripts forces a deliberate, separate step before any
//      lifecycle script can run.
//   2. npx <package> / npm exec <package> where <package> is not already
//      declared in this project's package.json (dependencies or
//      devDependencies) or in the small built-in allowlist below. npx runs
//      the package immediately with no install step to review first — the
//      direct-execution equivalent of piping a random URL into sh.
//
// Both checks run on each `&&`/`||`/`;`/`|`/backtick/`$(`-separated
// sub-command, same text-based splitting (and the same known false-positive
// limitation for separator tokens inside quoted strings) as
// block-curl-command.js. Exits 2 so the tool call is actually denied.
//
// Deliberately NOT touched: npm run/test/start/ls/outdated/view/etc, and
// plain npm install/ci once --ignore-scripts is present — neither carries
// the lifecycle-script or direct-execution risk this hook targets. Global
// installs (npm install -g, npx -y, npm exec -y) are blocked unconditionally
// via this project's permissions.deny instead, since a simple deny prefix
// already covers them without needing this hook's parsing.
//
// Companion manual tool: run `pkg-check <package>` (see
// core-skills/prevent-supply-chain-attack.md) BEFORE adding a new package to
// package.json to actually vet it — this hook only enforces that the vetting
// step happened (package is declared) plus the lifecycle-script opt-in.

import fs from "node:fs";
import path from "node:path";

const SUB_COMMAND_SEPARATOR = /&&|\|\||;|\||`|\$\(/;

// Extra CLI tools safe to `npx` even before they're declared in
// package.json. Extend this set as needed.
const BUILTIN_NPX_ALLOWLIST = new Set([
  "eslint",
  "prettier",
  "tsc",
  "typescript",
  "tsx",
  "ts-node",
  "vite",
  "vitest",
  "jest",
  "playwright",
  "stylelint",
  "http-server",
  "serve",
  "rimraf",
  "cross-env",
  "concurrently",
  "nodemon",
]);

function projectRoot() {
  return process.env.CLAUDE_PROJECT_DIR || process.cwd();
}

function declaredPackages() {
  const pkgPath = path.join(projectRoot(), "package.json");
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
    return new Set([
      ...Object.keys(pkg.dependencies || {}),
      ...Object.keys(pkg.devDependencies || {}),
    ]);
  } catch {
    return new Set();
  }
}

function checkInstallCommand(part) {
  const isInstall = /^\s*(sudo\s+)?npm\s+(install|i|ci)\b/i.test(part);
  if (!isInstall) return null;
  if (/--ignore-scripts\b/.test(part)) return null;
  return `Blocked: npm install/ci without --ignore-scripts runs any dependency's preinstall/install/postinstall lifecycle script automatically ("${part.trim()}"). Add --ignore-scripts, or vet the package first with pkg-check (core-skills/prevent-supply-chain-attack.md). Hard-denied by the block-npm-supply-chain-risk hook, regardless of permission mode (including bypassPermissions).`;
}

function checkNpxCommand(part) {
  const match = part.match(/^\s*(sudo\s+)?(npx|npm\s+exec)\b(.*)$/i);
  if (!match) return null;

  const rest = match[3] || "";
  const tokens = rest.trim().split(/\s+/).filter(Boolean);
  const pkgToken = tokens.find((t) => !t.startsWith("-"));
  if (!pkgToken) return null; // e.g. `npx --version` with no package to run

  // "some-pkg@1.2.3" -> "some-pkg"; "@scope/name@1.2.3" -> "@scope/name"
  const pkgName = pkgToken.startsWith("@")
    ? pkgToken.split("@").slice(0, 2).join("@")
    : pkgToken.split("@")[0];

  if (BUILTIN_NPX_ALLOWLIST.has(pkgName) || declaredPackages().has(pkgName)) {
    return null;
  }

  return `Blocked: npx/npm exec would run "${pkgName}" immediately with no install step to review first ("${part.trim()}"). Vet it with pkg-check <package> (core-skills/prevent-supply-chain-attack.md), then either add it to package.json devDependencies or extend BUILTIN_NPX_ALLOWLIST in block-npm-supply-chain-risk.js. Hard-denied by the block-npm-supply-chain-risk hook, regardless of permission mode (including bypassPermissions).`;
}

let raw = "";
process.stdin.on("data", (chunk) => {
  raw += chunk;
});

process.stdin.on("end", () => {
  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    // Malformed/empty input — nothing to block on, let the tool proceed.
    process.exit(0);
  }

  if (input.tool_name !== "Bash") {
    process.exit(0);
  }

  const command = String((input.tool_input || {}).command || "");
  const subCommands = command.split(SUB_COMMAND_SEPARATOR);

  for (const part of subCommands) {
    const reason = checkInstallCommand(part) || checkNpxCommand(part);
    if (reason) {
      process.stdout.write(
        JSON.stringify({
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: reason,
          },
        })
      );
      process.stderr.write(reason + "\n");
      process.exit(2);
    }
  }

  process.exit(0);
});
