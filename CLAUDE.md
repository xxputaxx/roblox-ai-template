# <PROJECT_NAME> プロジェクト規約

> このファイルは Claude Code が毎セッション読み込む。
> プロジェクトに関わる AI（Claude Code 等）は本ファイルの規約に従って行動すること。
> ユーザー（Yohei）の明示的な指示がこのファイルと矛盾する場合は、確認の上ユーザー指示を優先する。

---

## 1. プロジェクト概要

- **名称**: <PROJECT_NAME>
- **種類**: Roblox ゲーム（本格公開予定）
- **開発体制**: AI主導開発 — Claude Code が実装主体、Human (Yohei) がレビューと方向性決定
- **開発者**: Yohei
- **公開先**: Roblox プラットフォーム

---

## 2. 環境

### 2.1 バージョン固定ツール（rokit.toml 管理）
- Rojo 7.6.1
- Selene 0.30.1
- StyLua 2.4.1

### 2.2 エディタ
- VS Code(拡張: Luau Language Server, Rojo, Selene, StyLua)
- Claude Code(CLI または VS Code 拡張)

### 2.3 パス
- プロジェクトルート: `/Users/yohei_macmini/Documents/GitHub/Roblox_dev/<PROJECT_NAME>/`
- Studio ファイル: `<PROJECT_NAME>.rbxl`
- Rojo ポート: 34872

### 2.4 開発ワークフロー
```
Claude Code がローカルファイル(.luau) を編集
   ↓
Rojo serve が変更検知 → Studio に自動同期
   ↓
Hooks が selene + stylua --check を自動実行
   ↓
警告があれば AI が自己修正、なければ完了
   ↓
Yohei が Studio で ▶ Play (F5) して動作確認
```

---

## 3. アーキテクチャと設計原則

### 3.1 Client-Server 分離(Roblox の根本原則)

- **サーバー(src/server/)が真実の源(source of truth)**
- **クライアント(src/client/)は表示・入力受付・予測のみ**
- 重要なロジック・データ・判定は必ずサーバーで行う
- クライアントは決して信用しない(クライアントは改ざんされる前提)
- RemoteEvent/RemoteFunction でやりとりするデータは、サーバー側で必ず検証する

### 3.2 セキュリティ原則

- **クライアント送信値はサーバーで再検証**(範囲、型、所有権、レート制限)
- **クライアントから「お金を増やす」「アイテム取得」等の操作要求を受けたら、サーバー側ロジックで条件を再判定**
- **DataStore への書き込みはサーバーのみ**
- **MarketplaceService の ProcessReceipt は必ずサーバー側で正しく実装**(DataStore で永続化しないと購入が失われる)

### 3.3 設計パターン

- ModuleScript ベースの Singleton パターンを推奨
- Service/Controller の分離(Server側: Service、Client側: Controller)
- 各 Module は明示的なインターフェイスを export(`type` で型定義)
- 当面フレームワーク(Knit, Matter)は使わない、純粋なLuauで構成

### 3.4 パフォーマンス指針

- ループ系の選択肢:
  - `RunService.Heartbeat` → 物理シミュレーション系(毎フレーム後)
  - `RunService.RenderStepped` → クライアント描画系のみ(サーバー禁止)
  - `RunService.Stepped` → 物理シミュレーション前の処理
  - `task.wait()` → 短い待機、軽い処理
- 不要になった Instance は必ず `:Destroy()`
- `Connection` は不要になったら `:Disconnect()`(メモリリーク対策)
- `task.spawn` の濫用禁止(毎フレーム spawn すると重い)

---

## 4. コーディング規約

### 4.1 言語と型

- **Luau を使用**(Lua 5.1 ではない)。ファイル拡張子は `.luau`
- **すべての ModuleScript の冒頭に `--!strict` を付ける**(型チェック厳格化)
- すべての関数に型注釈を付ける:
  ```luau
  local function add(a: number, b: number): number
      return a + b
  end
  ```
- 公開する型は `export type` で定義
- 戻り値が複雑な関数は型エイリアスで明確化

### 4.2 命名規則

- **PascalCase**: Instance名、関数名、ModuleScript名、型名、定数
  - 例: `PlayerData`, `function CalculateScore()`, `type Vector3State`
- **snake_case** は使わない(Roblox の慣習に反する)
- **camelCase** はローカル変数のみ許可(ただし PascalCase 推奨)
- **プライベートメソッド**: `_` プレフィックス(例: `_internalHelper`)
- **真偽値**: `is`, `has`, `can` で始める(例: `isActive`, `hasPermission`)

### 4.3 deprecated API(使用禁止)

| 旧API | 代替 |
|---|---|
| `wait()` | `task.wait()` |
| `spawn()` | `task.spawn()` |
| `delay()` | `task.delay()` |
| `tick()` | `os.clock()` / `workspace:GetServerTimeNow()` |
| `Instance.new("X", parent)` 第2引数 | `.Parent = parent` を別途代入 |
| `LoadLibrary` | 削除済み、使用不可 |
| `game.Workspace` 直接参照 | `game:GetService("Workspace")` |

### 4.4 推奨パターン

- **サービス取得は冒頭で1回**:
  ```luau
  local Players = game:GetService("Players")
  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  ```
- **文字列結合**: 短い時は `..`、長い・複雑な時は `string.format()`
- **テーブル走査**: 配列なら `ipairs`、辞書なら `pairs`(Luau の `pairs` は順序保証なし)
- **nil チェック**: `if value then` ではなく `if value ~= nil then`(false と nil を区別したい時)
- **エラー処理**: 例外的なケースは `error()`、警告は `warn()`、デバッグは `print()`

### 4.5 アンチパターン(避ける)

- グローバル変数の定義(`_G.foo = ...` 等)
- 1ファイルに複数の責務を詰め込む
- 深いネスト(4階層を超えるifやループ)
- マジックナンバー(定数化する)
- `pcall` で例外を握りつぶしてログも残さない

---

## 5. ファイル/ディレクトリ規約

### 5.1 構造(Rojo 7系)

```
<PROJECT_NAME>/
├── src/
│   ├── server/     → ServerScriptService 配下(サーバーロジック)
│   ├── client/     → StarterPlayerScripts 配下(クライアントロジック)
│   └── shared/     → ReplicatedStorage 配下(両側で require可)
├── default.project.json  → DataModel 構造定義
├── selene.toml
├── stylua.toml
└── .vscode/settings.json
```

### 5.2 命名規則(Rojo の解釈)

| ファイル名 | Studio 上での扱い |
|---|---|
| `init.server.luau` | そのフォルダのコンテナ Script |
| `init.client.luau` | そのフォルダのコンテナ LocalScript |
| `init.luau` | そのフォルダのコンテナ ModuleScript |
| `<Name>.server.luau` | Script |
| `<Name>.client.luau` | LocalScript |
| `<Name>.luau` | ModuleScript |

### 5.3 新規ファイル追加時

- `default.project.json` の "tree" 構造を確認すること
- 既存の src/server/, src/client/, src/shared/ のどれに属すか明確にする
- 迷ったら Yohei に確認

---

## 6. 品質保証

### 6.1 必須検証(ファイル編集後に毎回実行)

```bash
selene src/              # Lint チェック(警告ゼロを目指す)
stylua --check src/      # フォーマット違反チェック
stylua src/              # フォーマット適用
```

- Hooks で自動実行される(PostToolUse)
- AI も能動的に確認すること

### 6.2 VS Code 連携

- PROBLEMS タブで Luau LSP の型エラー・診断結果を確認可能
- 保存時に StyLua が自動フォーマットする
- `sourcemap.json` は VS Code を開くと自動生成(手動実行不要)

### 6.3 Studio 動作確認

- 「実装完了」と宣言する前に、以下を Yohei に依頼:
  1. Studio で ▶ Play(F5)
  2. Window → Output でログ確認
  3. 期待通りの動作かフィードバック
- Studio 側でしか検出できないエラー(physics, replication 等)があるため必須

### 6.4 ログ規約

- `print(...)` → 通常の情報出力([INFO] 相当)
- `warn(...)` → 警告(黄色で表示、想定外だが致命的でない)
- `error(...)` → 致命的(スクリプト停止)
- 構造化を意識:
  ```luau
  print(("[PlayerData] Loaded player %d, level=%d"):format(userId, level))
  ```

---

## 7. AIの行動指針

### 7.1 最新仕様の確認

- 不安があれば WebFetch で公式を確認すること:
  - Rojo: https://rojo.space/docs/v7/
  - Roblox Creator Hub: https://create.roblox.com/docs
  - Luau: https://luau-lang.org/
- AI 事前知識のみで判断せず、deprecated 化等は必ず公式で裏取り

### 7.2 自己検証ループ

```
編集 → Hooks で自動検証 → 警告読解 → 自己修正 → 警告ゼロまで反復
```
警告ゼロを「作業完了」の基準とする。

### 7.3 確認・質問のタイミング

- **計画段階で確認すること**:
  - 20行を超える変更 → 編集前に方針を提示して確認
  - 新規ファイル作成 → どこに何を作るか共有してから
  - 既存ファイルの大幅リファクタリング → 必ず承認を取る
  - default.project.json の構造変更 → 必ず承認を取る
- **質問は1〜3個まで**: 多すぎる質問は避ける、優先度の高いものに絞る
- **不明点はWebFetchを先に**: 質問する前に公式ドキュメントで自分で調べる

### 7.4 やってはいけないこと

- ❌ 勝手な `git commit` / `git push`
- ❌ `<PROJECT_NAME>.rbxl` の直接編集(必ず Rojo 経由)
- ❌ `.rokit/`, `~/.zshrc` 等のシステム/環境ファイル編集
- ❌ `rojo serve` のターミナルを止める操作
- ❌ ユーザー承認なしの破壊的操作(大量ファイル削除、構造変更)
- ❌ クライアント側でのセキュリティ判定(必ずサーバー側で)
- ❌ 「動けばいい」という妥協(型注釈、警告ゼロは目指すべき水準)

### 7.5 エラー対応のフロー

1. エラーメッセージを正確に読む(推測しない)
2. selene/stylua/Luau LSP の出力を確認
3. 公式ドキュメントで該当APIを確認
4. それでも不明なら Yohei に状況を要約して相談(推測で進めない)

### 7.6 タスクの粒度

- 大きなタスクは TodoWrite で分割
- 各サブタスクは「動く形」で完結させる
- 中途半端な状態でコミットを残さない

---

## 8. よく使うコマンド

### 開発系
```bash
# Rojo サーバー起動(同期開始)
rojo serve

# 検証
selene src/
stylua --check src/
stylua src/                    # フォーマット適用

# ファイル探索
rg "pattern" src/              # 高速 grep
fd ".luau$" src/               # 高速 find

# Rojo のソースマップ手動生成(通常は自動)
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
```

### Git 系(AIは確認なしに実行しないこと)
```bash
git status
git diff
# 以下はユーザー承認後のみ
git add <files>
git commit -m "<message>"
git push
```

---

## 9. コミット規約(Git 導入後)

- **Conventional Commits 形式**:
  - `feat:` 新機能
  - `fix:` バグ修正
  - `refactor:` 振る舞いを変えない改善
  - `docs:` ドキュメント
  - `chore:` 雑務(依存更新、設定変更)
  - `test:` テスト関連
- 例: `feat: implement player ping tracking system`
- メッセージは英語、簡潔・命令形
- 1コミット = 1論理変更

---

## 10. 環境固有の挙動メモ

### 10.1 Rojo 7.6.x
- `rojo serve` は変更検知時のログを出さない仕様(同期は確実に動いている)
- 同期確認は `cat <ファイル>` と Studio Explorer のスクリプト中身で行う
- 詳細ログを見たい時: `RUST_LOG=info rojo serve`

### 10.2 Roblox Studio (macOS)
- Output ウィンドウは **Window メニュー**から開く(View ではない)
- F9 ショートカットでも開く
- Plugins タブ → Rojo アイコン → Connect で同期開始
- Studio バージョン更新時は Rojo Studio プラグインも再インストールが必要なことがある

### 10.3 Rokit
- ツールは **rokit.toml がある作業ディレクトリ内でしか実行できない**
- ホーム等で実行すると `Failed to find tool 'X' in any project manifest file.` エラー
- PATH: `~/.rokit/bin` を `.zshrc` に追加済み

---

## 11. 参考リンク

- Rojo: https://rojo.space/docs/v7/
- Roblox Creator Hub: https://create.roblox.com/docs
- Luau: https://luau-lang.org/
- Selene: https://kampfkarren.github.io/selene/
- StyLua: https://github.com/JohnnyMorganz/StyLua
- Roblox API Reference: https://create.roblox.com/docs/reference/engine

---

*最終更新: 2026-05-16*
