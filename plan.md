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
- [x] コーパステスト: 30/30 パス (arrays, calls, declarations, declare, literals, modules, procedures, statements)

## 既知のギャップ (現時点では対応しない)
- `PtrSafe`, `Preserve` は匿名トークンとして扱っているため AST に名前付きノードを残さない
- 配列境界 (`Dim a(1 To 10)` など) はフラットな式列として表現され、`lower`/`upper` のフィールドを持たない

## 非スコープ (将来)
- プリプロセッサ `#If` / `#Const` の完全サポート (最低限のスキップのみ)
- COM 参照解決

## 進め方 (TDD)
1. 小さな構文単位ごとに `test/corpus/*.txt` に RED のテストを追加
2. `grammar.js` を追記し `tree-sitter generate && tree-sitter test` で GREEN
3. Tidy First で整理

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
