# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

> **Experiment Stage（实验阶段）**  
> DHAA 目前处于用于验证概念和结构的实验阶段。接口、目录结构、支持的 harness 以及 agent 组成可能会根据实验结果发生变化。

**DHAA = Domain, Harness & Agent-Agnostic**

DHAA 的目标是构建一种不与特定应用领域、AI coding harness 或 agent 实现强绑定的 **agentic engineering workspace architecture**。

当前参考实现采用 **Claude Code + MoAI-ADK**。但 DHAA 的目标并不是将这一组合固定为标准，而是探索如何将开发工作流和运行规则分离到更高层，使其能够在不同的 domain、harness 和 agent 组合之间复用。

## 目标

DHAA 旨在降低以下三类耦合：

- **Domain-agnostic** — 不依赖 PillWriter、SaaS、XR、backend 等某一个特定产品或问题领域
- **Harness-agnostic** — 不永久绑定 Claude Code，并在结构上允许未来替换为其他 coding-agent harness
- **Agent-agnostic** — 将角色和规则与特定 planner、reviewer、worker agent 或模型实现分离

当前实现仍然存在对 Claude Code 和 MoAI-ADK 的依赖。因此，本仓库并不是一个已经完成的 agnostic framework，而更接近一个用于验证这些依赖能够被抽象和降低到什么程度的 **reference experiment**。

## 当前实现：双层继承模型

当前实验环境使用 Claude Code 和 MoAI-ADK 构建双层 workspace model。

| 层 | 是否继承 | 内容 |
|---|---|---|
| **Claude Code 层** | ✅ 自动继承到子目录 | `CLAUDE.md`、`.claude/`（agents/skills/rules/hooks/commands）、`/moai` slash commands |
| **`moai` binary 层** | ❌ 仅识别本地 `.moai/` | `moai status`/`loop`/`fix`/quality gate — 每个应用都需要自己的本地 `.moai/` |

- Claude Code 会向上遍历目录树，因此在子应用目录中启动 session 时，会继承 workspace 级别的 agentic engine 配置。
- `moai` binary 不继承父目录中的 `.moai/`，因此每个应用都需要通过 `moai init` 获得自己的本地 `.moai/`。
- 该结构用于实验性地减少由于每个应用重复保存相同 `CLAUDE.md`、agents、skills 和 rules 所产生的 context bloat。

## 仓库结构

```text
projects/                        ← DHAA workspace
├── CLAUDE.md                    # current reference orchestrator instructions
├── development_pipeline_guideline.md
├── core-skills/                 # reusable engineering rules
├── .claude/                     # current harness implementation
│   └── settings.json
├── .moai/                       # current MoAI-ADK reference configuration
├── .mcp.json                    # project-scoped MCP definitions
├── pkg-supply-chain-check.sh    # npm package supply-chain pre-check
├── skills-lock.json             # installed skill versions
└── (app folders)                # independent domain repositories
```

Domain 应用和本地 runtime state（例如 `.moai/reports|state|plans`、`.claude/tmp`）与该 workspace repository 分离。

## Clone 后的设置

### 0. 前置要求

以下要求适用于当前 reference implementation。

- **Git** + **Git Bash**（Windows — 用于 hook scripts）
- **Node.js** (LTS)
- **pnpm**
- **gh CLI**
- **moai binary** (MoAI-ADK)
- **Claude Code CLI**

随着 harness abstraction 的推进，这些要求预计会被拆分到 implementation-specific 文档中。

### 1. Clone

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

### 2. MCP Server 配置

当前 reference environment 使用以下 MCP 配置。

| Server | Scope | Transport | 用途 | Setup / Auth |
|---|---|---|---|---|
| **github** | project (`.mcp.json`) | HTTP (readonly) | repo/issue/PR read | `${GITHUB_PERSONAL_ACCESS_TOKEN}` 环境变量 |
| **context7** | user | HTTP | 最新 library docs | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` |
| **serena** | user | stdio | LSP symbol search/edit | 通过 `uvx` 安装 |
| **headroom** | user | stdio | context compression | `headroom mcp serve` |
| **pencil** | user | stdio | UI design (.pen) editing | local desktop executable |
| **vercel** | plugin | HTTP | deployment/docs | Claude Code plugin |
| **claude.ai connectors** | account | HTTP | Google/Linear integration | `/mcp` authentication |

stdio server 的执行路径可能因机器而异。

### 3. 修改 `.claude/settings.json` 中的 `env.PATH`

当前 reference implementation 可能包含与机器相关的路径。请根据自己的环境修改：

- Node.js installation path
- npm global path
- moai installation path

修改后重新启动 session。

### 4. 验证环境

```bash
claude   # 或 moai cc
```

当前实现中需要确认：

- ccstatusline 正常显示
- `/moai` slash commands 能够被识别
- workspace-level instructions/skills/rules 能够被继承

## 添加新的 Domain 应用

> 以下步骤基于当前 Claude Code + MoAI-ADK reference implementation。

```bash
# 1) 获取本地 .moai/
moai init my-new-app
cd my-new-app

# 2) 删除从父 workspace 继承而产生的重复配置
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles

# 当前实现中保留 hooks/settings 等 local runtime-dependent files

# 3) start session
moai cc
```

当前 MoAI workflow 示例：

```text
/moai project <name>
    ↓
/moai plan
    ↓
/moai run SPEC-XXX
    ↓
/moai loop / fix
    ↓
/moai sync
```

该 workflow 并不是 DHAA 的稳定 API，而是 **当前正在实验的 reference workflow**。

## Experiment Roadmap

DHAA 当前主要探索以下问题：

1. Domain-specific context 能够在多大程度上与 workspace engine 清晰分离？
2. Claude Code-specific instructions 能否被抽象为可供其他 harness 复用的形式？
3. Planner、reviewer、worker 等 agent role 能否与特定模型或 agent implementation 分离？
4. SPEC、test、review、sync 等 engineering lifecycle 能否被定义为 harness-independent contract？
5. 这些抽象是否能够实际减少 context bloat 和 orchestration complexity？

在这些问题得到充分验证之前，DHAA 的结构和命名不应被视为稳定的 public API。

## 注意事项

- DHAA 当前处于 **Experiment Stage**，因此可能发生 breaking changes。
- Claude Code 和 MoAI-ADK 是当前的 **reference implementation**，尚未被确定为 DHAA 的强制依赖。
- `moai update` 等 implementation-specific 命令目前遵循 reference environment 的行为。
- 每个应用目录都应作为独立的 Git repository 进行管理。
- 安装 package 前，可以使用 `pkg-supply-chain-check.sh` 执行 supply-chain check。

---

**DHAA 是一项实验，旨在探索如何将 agentic engineering workflow 与执行它的 domain、harness 和 agent implementation 分离。**
