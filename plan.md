# treesitter-vba 実装プラン

## ゴール
VBA (Visual Basic for Applications) をパースできる tree-sitter 文法を実装する。

## 🔴 最優先事項 (2026-04-21 時点)

**`queries/locals.scm` のリグレッションテストが tree-sitter 0.25.10 の upstream バグにより不可能**

- 影響: `test/locals/` にファイルを置くと `tree-sitter test` が常に exit 1 になるため、locals クエリは**書けてもテストできない**状態
- 原因: `cli/src/main.rs` の generic query test runner が source path と query path を取り違えている (詳細: L111-217)
- 自力解決不能: tree-sitter CLI 側の修正待ち (0.26+ を想定)
- アクション:
  1. tree-sitter/tree-sitter へ upstream issue を起票する (草稿は L159-217 に完成済み)
  2. 0.26+ リリース時に `test/locals/basics.bas` を復活させて検証
  3. それまで locals.scm の着手は保留 — 先に (D) corpus 拡充 / (E) highlight 優先度バグに時間を割く

## スコープ (MVP) — 実装済み
- [x] モジュール (標準/クラス) のトップレベル宣言
- [x] `Sub` / `Function` / `Property` 定義
- [x] 変数宣言: `Dim` / `Public` / `Private` / `Const` / `Static`
- [x] 型: 組み込み型, `As <Type>`, 配列, ユーザー定義型 (`Type ... End Type`)
- [x] 制御構文: `If/ElseIf/Else/End If`, `For/Next`, `For Each`, `Do/Loop`, `While/Wend`, `Select Case`, `With`
- [x] 式: 四則, 比較, 論理, メンバアクセス, 呼び出し, インデックス
- [x] リテラル: 数値, 文字列, 真偽, `#date#`, `Nothing`, `Null`
- [x] コメント (`'`, `Rem`), 行継続 (` _\n`)
- [x] エラー処理: `On Error ...`, `Resume`
- [x] `Enum` / `Const`
- [x] 属性: `Attribute ... = ...` (ヘッダ)

## MVP 以降で追加した項目
- [x] `Declare [PtrSafe] Function/Sub [Lib ...] [Alias ...]`
- [x] Node / Rust バインディング (`tree-sitter init` による生成物)
- [x] クエリ: `highlights`, `folds`, `locals`, `indents`
- [x] 例: `Sample.bas`, `ClassModule.cls`, `FormEvent.bas`, `ErrorHandling.bas`, `Preprocessor.bas`, `ComReference.bas`
- [x] コーパステスト: 45/45 パス (arrays, calls, declarations, declare, literals, modules, procedures, statements)
- [x] `PtrSafe`, `Preserve` を named node 化 (2026-04-20, 1d08647)
- [x] 配列境界 (`Dim a(1 To 10)` など) を `array_bound` named node + `lower`/`upper` field 化 (2026-04-20, 1d08647)
- [x] array_bound 回帰コーパステスト 4 件追加 (2026-04-20, 2a47696 / 4c0213d / 69cedd8 / 6e93fef)
- [x] プリプロセッサディレクティブ `#If` / `#ElseIf` / `#Else` / `#End If` / `#Const` を named node 化 (2026-04-20, 06934e2)
- [x] `qualified_name` に `library` / `name` field を付与し、COM 参照の構文レベル区別を可能に (2026-04-20, 4caaf53)
- [x] `#If` 本体でモジュールレベル宣言 (`Sub` など) と手続きレベル文の両方を受容 (2026-04-20, 0230daf)
- [x] プリプロセッサ関連コーパステスト 5 件追加 (2026-04-20, 5348030 ほか)
- [x] `folds.scm` に `(preprocessor_if)` を追加 (2026-04-20, 7204a87)
- [x] `highlights.scm` で `#If` 条件の単独 identifier を `@constant` として捕捉 (2026-04-20, a109309)
- [x] `examples/Preprocessor.bas` / `examples/ComReference.bas` を追加しコーパス回帰 2 セクションで固定 (2026-04-20, 16a3075)
- [x] `#If` 条件に binary_expression (`And` / `Or` 等) を許容することを回帰テストで保証 (2026-04-20, 655f992)

## クエリ層カバレッジ (2026-04-20 時点)
- highlights: キーワード / 演算子 / リテラル / 宣言名 / 呼び出し / メンバアクセス / プリプロセッサ (`#If` 条件の identifier は `@constant`, 複合式は `@expression`)
- folds: 手続き / 型 / ループ / `If` / `Select` / `With` / `preprocessor_if`
- examples: MVP サンプル 4 件 + `Preprocessor.bas` (コンパイル時分岐) + `ComReference.bas` (COM 参照の `library`/`name` フィールド)

## 既知のギャップ (現時点では対応しない)
- ~~`PtrSafe`, `Preserve` は匿名トークンとして扱っているため AST に名前付きノードを残さない~~ (2026-04-20 解消 / 1d08647)
- ~~配列境界 (`Dim a(1 To 10)` など) はフラットな式列として表現され、`lower`/`upper` のフィールドを持たない~~ (2026-04-20 解消 / 1d08647)
- ~~プリプロセッサ `#If` / `#Const` の完全サポート (最低限のスキップのみ)~~ (2026-04-20 解消 / 06934e2, 0230daf)

## 非スコープ (将来)
- COM 参照の **型解決** (`library` と `name` の構文的区別は 4caaf53 で着地済み。ただし実際の型名を COM 型ライブラリに突き合わせてシンボル解決する処理は tree-sitter の責務外)
- プリプロセッサ条件の **評価** (`#If` 条件式の真偽判定に基づく分岐選別。`#Const` 値追跡を含む意味解析層の仕事)

## 進め方 (TDD)
1. 小さな構文単位ごとに `test/corpus/*.txt` に RED のテストを追加
2. `grammar.js` を追記し `tree-sitter generate && tree-sitter test` で GREEN
3. Tidy First で整理

## Phase 0 — highlight fixture 調査結果 (2026-04-20)

### 0-a: tree-sitter バージョン
```
tree-sitter 0.25.10
```

### 0-b: `tree-sitter test --help` 確認
`tree-sitter test` はコーパステスト (`test/corpus/`) 専用。
highlight 専用フラグは存在しない。
highlight テストの個別確認は `tree-sitter highlight -n <TEST_NUMBER>` を使う。

### 0-c: 公式ドキュメント確認
出典: `docs/src/3-syntax-highlighting.md` (tree-sitter/tree-sitter リポジトリ) — Unit Testing セクション

- fixture ファイルは `test/highlight/` ディレクトリに置く通常のソースコードファイル
- ファイル内にアサーション用コメントを埋め込む (Sublime Text 方式)
- 2 種類のアサーション記法:
  - **Arrow** `<-`: コメント文字列の列でキャプチャ名を検証
  - **Caret** `^`: `^` 文字の列でキャプチャ名を検証 (連続 `^` で複数列を同時検証可)
- `!` でキャプチャの否定 (例: `' <- !keyword`)

### 0-d: 本リポで採用する fixture フォーマット案

VBA のコメント文字 `'` を使った以下のスタイルを採用する:

```vba
' test/highlight/keywords.bas
Sub Hello()
' <- keyword
'    ^ function
    Dim x As Integer
    '       ^ keyword
    '          ^ type.builtin
End Sub
' <- keyword
```

**方針:**
- ファイル名はキャプチャカテゴリ別に分割 (`keywords.bas`, `literals.bas`, `operators.bas` 等)
- 1 ファイルあたり 20〜30 行程度に抑え、アサーション密度より網羅性を優先
- `tree-sitter highlight -n <番号>` で個別確認しながら追加 (一括実行コマンドは要調査)

## Phase 1 完了宣言 (2026-04-21)

| 指標 | 値 |
|------|-----|
| highlight fixture ファイル数 | 14 |
| アサーション数 | 199 |
| カバー済み主要領域 | basics / operators / keywords / control_flow / procedures / comments / declarations / types / literals / with_blocks / error_handling / module_attributes / preprocessor |

全 14 fixture が green。nvim-treesitter キャプチャ名規約に準拠した `highlights.scm` で VBA の主要言語機能を網羅。

---

## Phase 2 locals テスト調査ログ (2026-04-21)

### tree-sitter 0.25.10 の test/locals/ 実装バグ (確定)

`tree-sitter test` が `test/locals/` ファイルを **S 式クエリとしてコンパイルしようとする** ことを GitHub ソース (`cli/src/main.rs`) で確認。

**根本原因 (tree-sitter/tree-sitter v0.25.10 `cli/src/main.rs` ~L37628):**
```rust
query::query_file_at_path(
    language,
    path,           // source file: test/locals/basics.bas
    &path.display().to_string(),
    path,           // BUG: query_path も同じ path! → VBA を S 式としてコンパイルしようとする
    false, None, None, true, false, false, false,
)?;
```

本来 `query_path` は `queries/locals.scm` であるべき。  
このバグにより `test/locals/` の全ファイルが**構造的にテスト不可**。highlights/tags は専用ランナー (`test_highlight::test_highlights`, `test_tags::test_tags`) で正しく動作するため影響なし。

**確認済み動作 (2026-04-21):**
- corpus: 54/54 ✓
- highlights: 14 fixture / 199 assertions ✓
- locals: `Query compilation failed — Query error at 1:1. Invalid syntax: Sub Process()`
- exit code: 1 (test/locals/basics.bas が存在する限り常に失敗)

**対処:**
- `test/locals/basics.bas` を削除し `tree-sitter test` の exit 0 を復元
- scope-only fixture の内容は plan.md に保存 (tree-sitter 修正後に再追加)

**保存: scope-only fixture 案 (Sub/Function の `' <- local.scope` 2 件):**
```vba
Sub Process()
' <- local.scope
End Sub

Function GetValue() As Integer
' <- local.scope
End Function
```

**Follow-up:**
- tree-sitter/tree-sitter upstream issue を立てるか確認 (buggy path reuse in generic query test runner)
- 定義系 (Const / Type / Enum の `@local.definition.*`) のアサーションは修正後に着手
- 次バージョン (0.26+) で修正されているか確認してから `test/locals/` を復活させる

---

## Phase 2 upstream issue 草稿 (2026-04-21)

### タイトル
`tree-sitter test` crashes with `Query compilation failed` when `test/locals/` directory exists

### 再現環境
- tree-sitter CLI: 0.25.10
- Grammar: any (reproduced with tree-sitter-vba)
- OS: macOS (Darwin 25.3.0)

### 再現手順
1. 任意の tree-sitter grammar に `test/locals/basics.bas`（またはソースファイル）を作成
2. `tree-sitter test` を実行

### 実際の動作
```
Query compilation failed — Query error at 1:1.
  Invalid syntax: Sub Process()
```
exit code: 1

### 期待される動作
`test/locals/` 内のファイルが言語ソースとして扱われ、対応する `queries/locals.scm` と照合されてスコープ/定義/参照アサーションが検証される。

### 根本原因
`cli/src/main.rs` の generic query test runner（highlights/tags と同じランナーを流用）で、`path`（ソースファイル）を `query_path` にも渡している:

```rust
// cli/src/main.rs (approximately L37600–L37640, tree-sitter v0.25.10)
query::query_file_at_path(
    language,
    path,                            // source: test/locals/basics.bas
    &path.display().to_string(),
    path,                            // BUG: query_path も同じ path を指している
    false, None, None, true, false, false, false,
)?;
```

本来 `query_path` は `queries/locals.scm` であるべき。

`test_highlight::test_highlights` や `test_tags::test_tags` は専用ランナーを持ちソースと query を正しく分離しているため影響なし。

### 影響
- `test/locals/` に 1 ファイルでも置くと `tree-sitter test` が常に exit 1
- corpus テスト・highlights テストには影響しない
- 全文法で `queries/locals.scm` のリグレッションテストが実質的に不可能

### 最小再現ケース
```vba
; test/locals/basics.bas
Sub Process()
' <- local.scope
End Sub
```
これを `test/locals/basics.bas` として置き `tree-sitter test` を実行すると再現。

### 想定修正
`query_path` 引数を `queries/locals.scm` のパスに修正し、locals 専用テストランナー（`test_locals::test_locals`）を導入する。

---

## Phase 2 候補

### (A) `queries/locals.scm` 整備 ★推奨
スコープ解析・definition/reference tracking を追加。
- `@local.scope`: `sub_declaration`, `function_declaration`, `property_declaration`
- `@local.definition`: 変数・パラメータ・定数名
- `@local.reference`: 式中の `identifier`
- **効果**: LSP と相補的。エディタ (nvim-treesitter) の go-to-definition / rename / highlight-on-cursor が機能する。

### (B) `queries/injections.scm`
コメント内の SQL / HTML / Markdown を外部文法で injection。
- `(comment)` ノードに `@injection.content` + `@injection.language`
- **効果**: SQL 文字列ハイライトなど多言語埋め込みが有効になる。現状 VBA での利用頻度は限定的。

### (C) `queries/textobjects.scm`
nvim-treesitter-textobjects プラグイン対応。
- `@function.outer` / `@function.inner`: `sub_declaration`, `function_declaration`
- `@class.outer` / `@class.inner`: `type_declaration`, `enum_declaration`
- **効果**: `vif` (inner function) などのテキストオブジェクトが使える。

### (D) corpus test/ 文法レベルテスト拡充
- `test/corpus/` に未カバーパターン (ネスト `With`, `Enum` 値式, `Declare` エラー系) を追加。
- 現状 45 テスト。20 件追加目標。

### (E) fixture 優先度バグ解消
- `with_blocks.bas` の `With` ブロック内プロパティが `@variable` にフォールバックしている箇所を `@property` に修正。
- `highlights.scm` でキャプチャ順を調整し、`leading_dot_member_access` の property を優先。

#### probe 結果 (2026-04-21)

**観測手順:** `tree-sitter query queries/highlights.scm /tmp/probe_vba.bas` で全キャプチャを出力

**観測データ (`.Bar = 1` の `Bar`):**
```
pattern: 20  capture: 6  - property, start: (2, 9), end: (2, 12)  Bar
pattern: 39  capture: 17 - variable, start: (2, 9), end: (2, 12)  Bar
```

**観測データ (`Sub Foo()` の `Foo`):**
```
pattern: 5   capture: 3  - function, start: (0, 3), end: (0, 7)   Foo
pattern: 39  capture: 17 - variable, start: (0, 3), end: (0, 7)   Foo
```

**確定した優先度モデル: _後着優先 (last-wins)_ — 同一ノードに複数のキャプチャが当たった場合、pattern index が最も高いものが勝つ。**

- `(identifier) @variable` は pattern 39 (ファイル末尾) であり、全ての identifier に対して pattern 5〜20 のより具体的なルールを上書きする。
- これは `with_blocks.bas` の `.PropName` だけでなく、**手続き名 (`@function`), 定数名 (`@constant`), 型名 (`@type`), フィールド名 (`@property`) を含む全識別子キャプチャに及ぶ**。
- `types.bas` の `X` → `@variable`, `declarations.bas` の `MAX_SIZE` → `@variable`, `basics.vba` の `HelloWorld` → `@variable` がすべて同一原因で説明される。

**影響範囲:**
- Pattern 5–8: `@function` (手続き名) → `@variable` にフォールバック
- Pattern 9: `@variable.parameter` → `@variable` にフォールバック
- Pattern 10–11: `@type` (型名, enum 名) → `@variable` にフォールバック
- Pattern 12: `@property` (type フィールド) → `@variable` にフォールバック
- Pattern 13–14: `@constant` (enum 値, const 名) → `@variable` にフォールバック
- Pattern 15–18: `@function.call` / `@function.method` → (call_expression の場合は呼び出しノードが異なるため影響軽微)
- Pattern 19–20: `@property` (member_access, leading_dot) → `@variable` にフォールバック

**修正方針 (次サイクルで実施):**
`(identifier) @variable` を `highlights.scm` の **最初のキャプチャ** (keywords ブロックの直後、pattern index を低くする) に移動する。具体的に言うと、identifier を catch-all する行を pattern 2〜3 相当の位置に置き、その後ろに全ての具体的識別子ルール (function / property / constant など) を配置することで後着優先モデルを活用する。

**後続作業:**
1. `highlights.scm` で `(identifier) @variable` を先頭グループ直後に移動
2. `with_blocks.bas` / `types.bas` / `declarations.bas` / `basics.vba` のアサーションを正しい capture 名に更新
3. `tree-sitter test` 全件グリーンを確認

---

## Phase 2 進捗 (2026-04-21)

| ステップ | 状態 | 内容 |
|----------|------|------|
| upstream issue 草稿 | ✅ 完了 | `cli/src/main.rs` query_path バグを再現手順・根本原因・最小再現ケース付きで plan.md に記録 |
| (E) fixture priority 修正 | ✅ 完了 | `(identifier) @variable` を catch-all 先頭に移動 (last-wins 活用)。13 アサーション更新: @function / @property / @constant / @type が正しく動作 |
| (D) corpus 拡充 | 🟡 部分完了 | Nested With / Enum 値式 (`Or` binary_expression) / Declare legacy (PtrSafe なし) を追加。54→57 件 |
| (A) locals.scm | 🔲 ブロック | tree-sitter 0.25.10 バグにより `test/locals/` テスト不可 — 0.26+ 待ち |

---

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
- highlight fixture 形式: `tree-sitter/tree-sitter` repo `docs/src/3-syntax-highlighting.md` Unit Testing セクション
