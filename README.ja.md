# DHAA

[English](README.en.md) · [한국어](README.md) · [日本語](README.ja.md) · [中文](README.zh.md)

> **Experiment Stage（実験段階）**  
> DHAAは現在、コンセプトと構造を検証するための実験段階にあります。インターフェース、ディレクトリ構成、対応するharnessやagentの構成は、実験結果に応じて変更される可能性があります。

**DHAA = Domain, Harness & Agent-Agnostic**

DHAAは、特定のアプリケーションドメイン、AI coding harness、agent実装に強く依存しない **agentic engineering workspace architecture** を目指すプロジェクトです。

現在のリファレンス実装では **Claude Code + MoAI-ADK** を使用しています。しかしDHAAの目的は、この組み合わせ自体を標準として固定することではありません。開発ワークフローと運用ルールを上位レイヤーへ分離し、異なるdomain、harness、agentの組み合わせでも再利用できる構造を検証することが目的です。

## 目標

DHAAは、次の3種類の結合を疎にすることを目指します。

- **Domain-agnostic** — PillWriter、SaaS、XR、backendなど、特定の製品や問題領域に依存しない
- **Harness-agnostic** — Claude Codeに固定せず、将来的に別のcoding-agent harnessへ置き換えられるよう構造化する
- **Agent-agnostic** — planner、reviewer、workerなどの特定agentやモデル実装から役割とルールを分離する

現在の実装には、まだClaude CodeおよびMoAI-ADKへの依存が存在します。そのため、このリポジトリは完成したagnostic frameworkではなく、依存関係をどこまで一般化し、結合度を下げられるかを検証するための **reference experiment** と位置付けています。

## 現在の実装：2レイヤー継承モデル

現在の実験環境では、Claude CodeとMoAI-ADKを利用した2-layer workspace modelを採用しています。

| レイヤー | 継承 | 内容 |
|---|---|---|
| **Claude Codeレイヤー** | ✅ 子ディレクトリへ自動継承 | `CLAUDE.md`、`.claude/`（agents/skills/rules/hooks/commands）、`/moai` slash commands |
| **`moai` binaryレイヤー** | ❌ ローカルの`.moai/`のみ認識 | `moai status`/`loop`/`fix`/quality gate — 各アプリにローカル`.moai/`が必要 |

- Claude Codeはディレクトリツリーを上方向に探索するため、子アプリのフォルダ内でセッションを開始するとworkspaceレベルのagentic engine設定を継承します。
- `moai` binaryは親の`.moai/`を継承しないため、各アプリで`moai init`を実行し、ローカル`.moai/`を用意します。
- この構造により、各アプリに同じ`CLAUDE.md`、agents、skills、rulesを複製することで生じるcontext bloatの削減を検証しています。

## リポジトリ構成

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

ドメインアプリとローカルruntime state（`.moai/reports|state|plans`、`.claude/tmp`など）は、このworkspace repositoryから分離します。

## クローン後のセットアップ

### 0. 前提条件

以下は現在のreference implementationに対する要件です。

- **Git** + **Git Bash**（Windows — hook scripts用）
- **Node.js** (LTS)
- **pnpm**
- **gh CLI**
- **moai binary** (MoAI-ADK)
- **Claude Code CLI**

harness abstractionが進んだ段階で、これらの要件はimplementation-specificなドキュメントへ分離する予定です。

### 1. Clone

```bash
git clone git@github.com:Seung-zedd/dhaa.git projects
cd projects
```

### 2. MCP Server設定

現在のreference environmentでは、以下のMCP構成を使用しています。

| Server | Scope | Transport | 用途 | Setup / Auth |
|---|---|---|---|---|
| **github** | project (`.mcp.json`) | HTTP (readonly) | repo/issue/PR read | `${GITHUB_PERSONAL_ACCESS_TOKEN}` 環境変数 |
| **context7** | user | HTTP | 最新ライブラリドキュメント | `claude mcp add --transport http context7 https://mcp.context7.com/mcp` |
| **serena** | user | stdio | LSP symbol search/edit | `uvx`でインストール |
| **headroom** | user | stdio | context compression | `headroom mcp serve` |
| **pencil** | user | stdio | UI design (.pen) editing | local desktop executable |
| **vercel** | plugin | HTTP | deployment/docs | Claude Code plugin |
| **claude.ai connectors** | account | HTTP | Google/Linear integration | `/mcp` authentication |

stdio serverの実行パスはマシンごとに異なる場合があります。

### 3. `.claude/settings.json` の `env.PATH` を修正

現在のreference implementationにはマシン固有のパスが含まれる場合があります。環境に合わせて以下を修正してください。

- Node.js installation path
- npm global path
- moai installation path

変更後はセッションを再起動します。

### 4. 動作確認

```bash
claude   # または moai cc
```

現在の実装では、以下を確認します。

- ccstatuslineが正常に表示される
- `/moai` slash commandsが認識される
- workspace-level instructions/skills/rulesが継承される

## 新しいドメインアプリの追加

> 以下は現在のClaude Code + MoAI-ADK reference implementationを前提としています。

```bash
# 1) local .moai/ を用意
moai init my-new-app
cd my-new-app

# 2) 親workspaceから継承される重複設定を削除
rm CLAUDE.md
rm -rf .claude/agents .claude/skills .claude/commands .claude/rules .claude/output-styles

# 現在の実装ではhooks/settingsなどlocal runtime-dependent filesは維持

# 3) session start
moai cc
```

現在のMoAI workflow例：

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

このworkflowはDHAAの安定したAPIではなく、**現在実験中のreference workflow**です。

## Experiment Roadmap

現在DHAAでは、主に次の問いを検証しています。

1. Domain-specific contextをworkspace engineからどこまで明確に分離できるか？
2. Claude Code固有のinstructionsを、他のharnessでも再利用可能な形へ抽象化できるか？
3. Planner、reviewer、workerなどのagent roleを、特定のモデルやagent implementationから分離できるか？
4. SPEC、test、review、syncなどのengineering lifecycleをharness-independent contractとして定義できるか？
5. この抽象化によってcontext bloatやorchestration complexityを実際に削減できるか？

これらが十分に検証されるまでは、DHAAの構造や名称を安定したpublic APIとはみなしません。

## 注意事項

- 現在は **Experiment Stage** のため、breaking changesが発生する可能性があります。
- Claude CodeとMoAI-ADKは現在の **reference implementation** であり、DHAAの必須構成要素として確定したものではありません。
- `moai update`などimplementation-specificなコマンドは、現在のreference environmentの動作に従います。
- アプリフォルダは、それぞれ独立したGit repositoryとして管理することを前提としています。
- パッケージ導入前に`pkg-supply-chain-check.sh`を使ってsupply-chain checkを実行できます。

---

**DHAAは、agentic engineering workflowを、それを実行するdomain、harness、agent implementationから分離できるかを検証する実験です。**
