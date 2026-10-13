#!/usr/bin/env node
// PreToolUse guard: hard-blocks Edit/Write/MultiEdit/NotebookEdit on any .env-prefixed file
// (.env, .env.local, .env.production, ...). Exits 2 so the tool call is actually denied,
// not just warned about. Scoped to this project only (registered in this project's own
// .claude/settings.json, not the shared C:\Users\sdok1\projects container).

const path = require("path");

const BLOCKED_TOOLS = new Set(["Edit", "Write", "MultiEdit", "NotebookEdit"]);
const ENV_FILE_PATTERN = /^\.env($|\.)/i;

let raw = "";
process.stdin.on("data", (chunk) => {
  raw += chunk;
});

process.stdin.on("end", () => {
  let input;
  try {
    input = JSON.parse(raw);
  } catch (err) {
    // Malformed/empty input — nothing to block on, let the tool proceed.
    process.exit(0);
  }

  const toolName = input.tool_name;
  if (!BLOCKED_TOOLS.has(toolName)) {
    process.exit(0);
  }

  const toolInput = input.tool_input || {};
  const filePath = toolInput.file_path || toolInput.notebook_path;
  if (!filePath) {
    process.exit(0);
  }

  const baseName = path.basename(String(filePath));

  if (ENV_FILE_PATTERN.test(baseName)) {
    const reason = `Protected file: "${baseName}" matches the .env* secrets-file pattern. ${toolName} on this file is blocked by the block-env-edit hook. Edit it manually outside Claude Code if you really need to change it.`;

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

  process.exit(0);
});
