#!/usr/bin/env node
// PostToolUse hook: lints only the file just touched by Edit/Write/MultiEdit/NotebookEdit.
// Always exits 0 (non-blocking) — this is a warn-only convenience hook, never a gate.

'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function which(bin) {
  const exts = process.platform === 'win32' ? ['.cmd', '.exe', ''] : [''];
  const dirs = (process.env.PATH || '').split(path.delimiter);
  for (const dir of dirs) {
    for (const ext of exts) {
      const p = path.join(dir, bin + ext);
      if (fs.existsSync(p)) return p;
    }
  }
  return null;
}

function findUp(startDir, names) {
  let dir = path.resolve(startDir);
  while (true) {
    for (const name of names) {
      if (fs.existsSync(path.join(dir, name))) return path.join(dir, name);
    }
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function localBin(startDir, bin) {
  let dir = path.resolve(startDir);
  const exe = process.platform === 'win32' ? bin + '.cmd' : bin;
  while (true) {
    const candidate = path.join(dir, 'node_modules', '.bin', exe);
    if (fs.existsSync(candidate)) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function run(cmd, args) {
  try {
    const out = execFileSync(cmd, args, {
      encoding: 'utf8',
      timeout: 20000,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { ok: true, output: out.trim() };
  } catch (err) {
    const output = [err.stdout, err.stderr].filter(Boolean).join('\n').trim();
    return { ok: false, output: output || String(err.message || err) };
  }
}

function lint(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const dir = path.dirname(filePath);

  if (ext === '.json') {
    try {
      JSON.parse(fs.readFileSync(filePath, 'utf8'));
    } catch (e) {
      return { linter: 'json-syntax', output: e.message };
    }
    return null;
  }

  if (['.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx'].includes(ext)) {
    const hasConfig = findUp(dir, [
      'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs', 'eslint.config.ts',
      '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yml', '.eslintrc',
    ]);
    const bin = localBin(dir, 'eslint');
    if (!hasConfig || !bin) return null; // no eslint set up in this project yet — skip quietly
    const r = run(bin, ['--no-color', filePath]);
    return !r.ok && r.output ? { linter: 'eslint', output: r.output } : null;
  }

  if (ext === '.py') {
    const ruff = which('ruff');
    const flake8 = which('flake8');
    if (ruff) {
      const r = run(ruff, ['check', filePath]);
      return !r.ok && r.output ? { linter: 'ruff', output: r.output } : null;
    }
    if (flake8) {
      const r = run(flake8, [filePath]);
      return !r.ok && r.output ? { linter: 'flake8', output: r.output } : null;
    }
    return null;
  }

  if (['.sh', '.bash'].includes(ext)) {
    const shellcheck = which('shellcheck');
    if (!shellcheck) return null;
    const r = run(shellcheck, [filePath]);
    return !r.ok && r.output ? { linter: 'shellcheck', output: r.output } : null;
  }

  if (['.yml', '.yaml'].includes(ext)) {
    const yamllint = which('yamllint');
    if (!yamllint) return null;
    const r = run(yamllint, [filePath]);
    return !r.ok && r.output ? { linter: 'yamllint', output: r.output } : null;
  }

  if (['.css', '.scss'].includes(ext)) {
    const bin = localBin(dir, 'stylelint');
    if (!bin) return null;
    const r = run(bin, [filePath]);
    return !r.ok && r.output ? { linter: 'stylelint', output: r.output } : null;
  }

  return null; // no linter mapped for this extension — skip quietly
}

function main() {
  let payload;
  try {
    payload = JSON.parse(readStdin() || '{}');
  } catch {
    return;
  }

  const input = payload.tool_input || {};
  const filePath = input.file_path || input.notebook_path;
  if (!filePath || !fs.existsSync(filePath)) return;

  let result;
  try {
    result = lint(filePath);
  } catch (e) {
    result = { linter: 'lint-on-edit', output: `hook error: ${e.message}` };
  }

  if (result) {
    const rel = path.relative(process.cwd(), filePath) || filePath;
    const msg = `[lint-on-edit] ${result.linter} flagged issues in ${rel}:\n${result.output}`.slice(0, 4000);
    process.stdout.write(JSON.stringify({ systemMessage: msg }));
  }
}

try {
  main();
} catch {
  // never block or crash the tool call — swallow any unexpected error
}
process.exit(0);
