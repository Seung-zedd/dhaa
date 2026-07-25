---
paths: "**/.claude/agents/**"
---

# Model Policy

Rules for agent model field values and multi-model architecture.

## Valid Model Field Values

Agent definition `model` field accepts only these values:
- inherit: Uses parent session's model (default)
- opus: Claude Opus (highest capability)
- sonnet: Claude Sonnet (balanced)
- haiku: Claude Haiku (fastest, lowest cost)

Current model generation mapping (updated 2026-07-25):
- opus = Opus 5 (default effort: medium for Max/Team, use "deepthink" keyword for high effort)
- sonnet = Sonnet 5
- haiku = Haiku 4.5 (no 5-generation release; 4.5 remains current)

Opus 5 fast mode: 1M context window with faster output. Toggle with /fast.

Invalid values (NEVER use):
- glm: Not a model field value (GLM is configured via environment variables)
- high/medium/low: These are CLI policy flags, not model field values
- Pinned version IDs (opus-4-1, sonnet-4-5, claude-opus-4-7): Auto-migrated to current generation

## Model Policy Tiers

Model policy is set via `moai init --model-policy <tier>`:

| Tier | Description | Opus Agents | Sonnet Agents | Haiku Agents |
|------|-------------|-------------|---------------|--------------|
| high | Maximum quality | spec, strategy, security | backend, frontend, ddd, tdd | quality, git, researcher |
| medium | Balanced (default) | spec, strategy, security | backend, frontend, ddd, tdd | quality, git, researcher |
| low | Cost optimized | None | spec, strategy, security | All others |

## CG Mode

CG Mode (Claude + GLM) uses environment variable overrides, not model field changes:
- Leader session: Uses Claude models (no GLM env)
- Teammate sessions: Inherit GLM env from tmux session
- Activation: `moai cg` (requires tmux)

## Effort Levels (Opus)

Opus supports effort levels that control reasoning depth:
- low: Fastest responses, less thorough
- medium: Default for Max/Team subscribers (v2.1.68+)
- high: Deep reasoning, activated by "deepthink" keyword for one turn
- xhigh / max: Maximum reasoning depth. Requires Opus 4.7 or later (Opus 5 included)

MoAI's --deepthink flag triggers high effort for the current turn. This aligns with the "deepthink" keyword behavior in Claude Code.

## Rules

- Agent `model` field must be one of: inherit, opus, sonnet, haiku
- GLM is configured via env vars in settings.json, never via model field
- Model policy tier is a CLI concern, not an agent definition concern
- CG Mode uses tmux session-level env isolation for model routing
- Old model versions are auto-migrated: do not pin to specific version IDs
