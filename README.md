# Roblox AI Development Template

AI主導 Roblox 開発のための雛形プロジェクト。
Rojo + Selene + StyLua + Luau LSP + Claude Code 統合済み。

## このテンプレートを使う

### ローカル雛形として（推奨）

`~/.claude/skills/roblox-new-project/new-project.sh <project_name>` で新規プロジェクトを作成。

### GitHub Template として

```bash
gh repo create my-new-game --template <username>/roblox-ai-template --private --clone
cd my-new-game
rokit install
```

## 含まれているもの

- Rojo 7.6+ プロジェクト構造
- Selene + StyLua 設定（Roblox std）
- VS Code 設定（Luau LSP, 保存時整形）
- Claude Code 設定（permissions, hooks）
- CLAUDE.md（プロジェクト規約）
- 最小限の src/ サンプル

## 環境構築前提

- Roblox Studio（macOS / Windows）
- Rokit インストール済み
- VS Code + 拡張（Luau LSP, Rojo, Selene, StyLua）
- Claude Code

詳細はCLAUDE.mdを参照。
