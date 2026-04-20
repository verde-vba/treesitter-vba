# treesitter-vba 実装プラン

## ゴール
VBA (Visual Basic for Applications) をパースできる tree-sitter 文法を実装する。

## スコープ (MVP)
- モジュール (標準/クラス) のトップレベル宣言
- `Sub` / `Function` / `Property` 定義
- 変数宣言: `Dim` / `Public` / `Private` / `Const` / `Static`
- 型: 組み込み型, `As <Type>`, 配列, ユーザー定義型 (`Type ... End Type`)
- 制御構文: `If/ElseIf/Else/End If`, `For/Next`, `For Each`, `Do/Loop`, `While/Wend`, `Select Case`, `With`
- 式: 四則, 比較, 論理, メンバアクセス, 呼び出し, インデックス
- リテラル: 数値, 文字列, 真偽, `#date#`, `Nothing`, `Null`
- コメント (`'`, `Rem`), 行継続 (` _\n`)
- エラー処理: `On Error ...`, `Resume`
- `Enum` / `Const`
- 属性: `Attribute ... = ...` (ヘッダ)

## 非スコープ (将来)
- プリプロセッサ `#If` / `#Const` の完全サポート (最低限のスキップのみ)
- COM 参照解決
- 自動インデント/ハイライト用クエリは後続

## 進め方 (TDD)
1. 小さな構文単位ごとに `test/corpus/*.txt` に RED のテストを追加
2. `grammar.js` を追記し `tree-sitter generate && tree-sitter test` で GREEN
3. Tidy First で整理

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
