#!/usr/bin/env node
// PreToolUse guard: hard-blocks any Bash command that INVOKES curl, wget, or
// nc (netcat) — as the whole command, or as any sub-command chained with &&,
// ||, ;, |, a backtick, or a $(...) substitution (leading whitespace and an
// optional "sudo " prefix allowed on each sub-command). This is NOT shell
// evaluation — the hook has no concept of exit-code truthiness for && / ||;
// it simply splits the raw text on shell separator tokens and checks each
// resulting piece against the same "starts with (sudo )?(curl|wget|nc)" rule.
// A command that merely mentions one of these tools inside a path, filename,
// or argument (not as the invoked program of some sub-command) is still not
// blocked. Known limitation: splitting is text-based, not a real shell
// tokenizer, so a separator token appearing inside a quoted string (e.g.
// echo "a && b") is still treated as a split point — a rare false positive, not
// a bypass. Exits 2 so the tool call is actually denied, not just warned about.
// This runs BEFORE the permission system, so unlike permissions.deny
// ("Bash(curl *)" / "Bash(wget *)" in this project's settings.json) it also
// fires under bypassPermissions / acceptEdits / auto modes. Filename kept as
// block-curl-command.js (curl was the original scope) — see commit history.

const SUB_COMMAND_SEPARATOR = /&&|\|\||;|\||`|\$\(/;
const EXFIL_COMMAND_PATTERN = /^\s*(sudo\s+)?(curl|wget|nc)\b/i;

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

  if (input.tool_name !== "Bash") {
    process.exit(0);
  }

  const command = String((input.tool_input || {}).command || "");
  const subCommands = command.split(SUB_COMMAND_SEPARATOR);
  const hitMatch = subCommands
    .map((part) => part.match(EXFIL_COMMAND_PATTERN))
    .find((match) => match !== null);

  if (hitMatch) {
    const hitCommand = hitMatch[2].toLowerCase();
    const reason = `Blocked: command invokes ${hitCommand}, directly or as a chained sub-command ("${command}"). curl/wget/nc execution is hard-denied by the block-curl-command hook, regardless of permission mode (including bypassPermissions).`;

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
