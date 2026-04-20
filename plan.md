# treesitter-vba 実装プラン

## ゴール
VBA (Visual Basic for Applications) をパースできる tree-sitter 文法を実装する。

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

---

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
- highlight fixture 形式: `tree-sitter/tree-sitter` repo `docs/src/3-syntax-highlighting.md` Unit Testing セクション
