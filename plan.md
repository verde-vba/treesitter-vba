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
- [x] 例: `Sample.bas`, `ClassModule.cls`, `FormEvent.bas`, `ErrorHandling.bas`
- [x] コーパステスト: 42/42 パス (arrays, calls, declarations, declare, literals, modules, procedures, statements)
- [x] `PtrSafe`, `Preserve` を named node 化 (2026-04-20, 1d08647)
- [x] 配列境界 (`Dim a(1 To 10)` など) を `array_bound` named node + `lower`/`upper` field 化 (2026-04-20, 1d08647)
- [x] array_bound 回帰コーパステスト 4 件追加 (2026-04-20, 2a47696 / 4c0213d / 69cedd8 / 6e93fef)
- [x] プリプロセッサディレクティブ `#If` / `#ElseIf` / `#Else` / `#End If` / `#Const` を named node 化 (2026-04-20, 06934e2)
- [x] `qualified_name` に `library` / `name` field を付与し、COM 参照の構文レベル区別を可能に (2026-04-20, 4caaf53)
- [x] `#If` 本体でモジュールレベル宣言 (`Sub` など) と手続きレベル文の両方を受容 (2026-04-20, 0230daf)
- [x] プリプロセッサ関連コーパステスト 5 件追加 (2026-04-20, 5348030 ほか)

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

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
