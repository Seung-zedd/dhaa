#!/usr/bin/env node
// Stop hook: shows a compact list of working-tree changed files whenever
// Claude finishes responding. Always exits 0 (non-blocking) — informational only.

'use strict';

const fs = require('fs');
const { execFileSync } = require('child_process');

function readStdin() {
  try {
    fs.readFileSync(0, 'utf8');
  } catch {
    // ignore — stdin content isn't needed for this hook
  }
}

function gitStatus(cwd) {
  try {
    return execFileSync('git', ['status', '--porcelain=v1'], {
      cwd,
      encoding: 'utf8',
      timeout: 8000,
    });
  } catch {
    return null; // not a git repo, or git unavailable
  }
}

const STATUS_LABELS = {
  M: '수정',
  A: '추가',
  D: '삭제',
  R: '이름변경',
  C: '복사',
  U: '충돌',
  '?': '미추적',
};

function label(code) {
  const c = code.trim().charAt(0) || '?';
  return STATUS_LABELS[c] || code.trim();
}

function main() {
  readStdin();

  const cwd = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const raw = gitStatus(cwd);

  if (raw === null) {
    process.stdout.write(JSON.stringify({
      systemMessage: '[changed-files] git 저장소가 아니거나 git 명령을 찾을 수 없습니다.',
    }));
    return;
  }

  const lines = raw.split('\n').filter(Boolean);

  if (lines.length === 0) {
    process.stdout.write(JSON.stringify({ systemMessage: '[changed-files] 변경된 파일 없음.' }));
    return;
  }

  const entries = lines.map((line) => {
    const code = line.slice(0, 2);
    const file = line.slice(3);
    return `  ${label(code)}: ${file}`;
  });

  const msg = `[changed-files] 작업 트리 변경 파일 (${lines.length}개):\n${entries.join('\n')}`.slice(0, 4000);
  process.stdout.write(JSON.stringify({ systemMessage: msg }));
}

try {
  main();
} catch {
  // never crash the Stop event
}
process.exit(0);
