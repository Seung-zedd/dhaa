# You can choose certain chaining workflow based on project progress.

## 1. new feature development:
`/moai plan → /moai run SPEC-XXX → /moai sync SPEC-XXX`

## 2. bug fix:
`/moai fix (또는 /moai loop) → /moai review → /moai sync`

## 3. refactoring:
`/moai plan → /moai clean → /moai run SPEC-XXX → /moai review → /moai coverage → /moai codemaps`

## 4. update docs:
`/moai codemaps → /moai sync`