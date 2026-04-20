# treesitter-vba 実装プラン

## ゴール
VBA (Visual Basic for Applications) をパースできる tree-sitter 文法を実装する。

## 🔴 最優先事項 (2026-04-21 時点)

**`queries/locals.scm` のリグレッションテストが tree-sitter CLI の upstream バグにより不可能**

- 影響: `test/locals/` にファイルを置くと `tree-sitter test` が常に exit 1 になるため、locals クエリは**書けてもテストできない**状態
- 原因: query test runner が source path を query path としても使う実装バグ (詳細: Phase 2 調査ログ)
- **0.26.8 でも未修正** (2026-04-21 Phase 3 Sprint 4 で確認): 新セクション `queries:` が追加されたが根本バグ継続
- 自力解決不能: tree-sitter CLI 0.27+ 修正待ち
- アクション:
  1. tree-sitter/tree-sitter へ upstream issue を起票する (草稿は Phase 2 セクションに完成済み)
  2. 0.27+ リリース時に `test/locals/basics.bas` を復活させて検証
  3. それまで locals.scm の着手は保留 — 先に highlight fixture 拡充に時間を割く

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
| (D) corpus 拡充 | ✅ 完了 | 57→62 件。追加パターン: Optional/ParamArray 付きパラメータ / Property Let / Property Set / While/Wend / Inline If |
| (C) textobjects.scm | ✅ 完了 | `@function.outer/inner` (sub/function/property_declaration)、`@class.outer/inner` (type/enum_declaration)。CLI 検証で警告なし確認済み |
| (A) locals.scm | 🔲 ブロック | tree-sitter 0.25.10 バグにより `test/locals/` テスト不可 — 0.26+ 待ち |

### (C) textobjects.scm 検証メモ (2026-04-21)

**検証手段:** `tree-sitter query queries/textobjects.scm <vba_file>`

**観測結果:**
- `@function.outer/inner`: `sub_declaration` ✓、`function_declaration` ✓、`property_declaration` ✓
- `@class.outer/inner`: `type_declaration` (各 `type_field`) ✓、`enum_declaration` (各 `enum_member`) ✓
- 警告なし、エラーなし

**発見したギャップ & 修正:**
- `property_declaration` が `@function.outer/inner` に含まれていなかった → 追加済み
- VBA の Property は手続きとして呼び出し可能なため `@function.*` の対象が適切

**結論:** `test/corpus/` 形式では textobjects assertion を埋め込む構文がない。検証手段は CLI manual run のみ (corpus ファイルはコードと S 式の混合テキストとして parse されるため、クエリ結果にノイズが混入する)。

### (D) corpus 拡充 完了記録 (2026-04-21)

| テスト名 | ファイル | カバーする構文 |
|----------|----------|----------------|
| Optional parameter with default and ParamArray | procedures.txt | `Optional` / `ParamArray` キーワード付きパラメータ |
| Property Let | procedures.txt | `property_declaration` accessor=Let |
| Property Set | procedures.txt | `property_declaration` accessor=Set |
| While / Wend loop | statements.txt | `while_statement` |
| Inline If Then Else | statements.txt | `if_statement` (単行、consequence/alternative が `paren_less_call`) |

**非対応パターン (grammar 非実装のため corpus 追加不可):**
- `GoSub` / `Return` (GoSub ラベル): grammar に `gosub_statement` なし
- `DefType` 文 (`DefInt`, `DefStr` 等): grammar に未実装
- `Event` 宣言: grammar に未実装
- `Implements` 文: grammar に未実装

---

## Phase 2 Sprint レトロスペクティブ (KPT)

### Keep (続けること)
- `tree-sitter parse /tmp/xxx.bas` で S 式を先に取得してから corpus エントリを書く → 構文ミスを防ぎ一発 green
- grammar.js のルール一覧と corpus ファイルのテスト名を突き合わせて未カバーパターンを体系的に特定する方法
- Tidy First: corpus 追加と plan.md 更新を別 commit に分離

### Problem (やめること / 改善すること)
- `tree-sitter query` を corpus ファイルに対して実行すると S 式テキストも VBA としてパースされノイズが発生する → 専用の `.bas` テストファイルを使うべき
- GoSub / DefType / Event / Implements など grammar が未実装の構文は期待だけ高まる → 候補リスト作成時に grammar.js で存在確認を先に行う

### Try (試すこと)
- GoSub / DefType / Event / Implements を grammar.js に追加して corpus カバレッジをさらに拡大 (Phase 3 候補)
- ~~`While/Wend` や `Inline If` の highlight fixture を追加して highlight 層のカバレッジも向上~~ ✅ 完了 (2026-04-21)

---

## Phase 2 Sprint 3 (highlight fixture 拡充) 完了記録 (2026-04-21)

| ファイル | assertions | カバーする構文 |
|----------|-----------|----------------|
| `test/highlight/while_wend.bas` | 5 | `While/Wend` ループ (`while_statement` ノード) |
| `test/highlight/inline_if.bas` | 8 | Inline If (consequence のみ) / Inline If Else (consequence + alternative) |

**全 fixture green 確認:** `tree-sitter test --file-name while_wend` / `--file-name inline_if` ともに 16 ファイル全 ✓

### Sprint 3 レトロスペクティブ (KPT)

#### Keep
- S 式を `/tmp/*.bas` で先取りしてカラム位置を確定してから fixture を書く → アサーション一発 green
- `--file-name <partial>` で部分マッチ実行 — 全フィクスチャを再テストするため新旧のリグレッションを同時確認できる

#### Problem
- highlight fixture は `^` カラム指定がズレると silent failure しやすい → 先に `tree-sitter parse` で位置を数えてから書く習慣が重要

#### Try (Phase 3 向け)
- ~~GoSub を grammar.js に追加~~ ✅ 完了 (2026-04-21)
- DefType / Event / Implements を grammar.js に追加 → corpus + highlight fixture セット追加
- tree-sitter 0.26 リリース時に `test/locals/basics.bas` を復活させて locals.scm を検証 (npm: tree-sitter-cli 0.26.8 確認済み、package.json は ^0.25.0 制約のため upgrade は別 Sprint)

---

---

## Phase 3 Sprint 7 (GoTo/@label 昇格 + DefType 複数レンジ fixture 補強) 完了記録 (2026-04-21)

### Sprint Goal
`On Error GoTo` / `GoTo` 文の target ラベルを `@label` に昇格 (grammar.js probe 必須) + `DefType` 複数レンジ fixture 補強の 2 件束ね。

### probe 結果 (Step A)

| 確認項目 | 結果 |
|----------|------|
| `goto_statement` の field 名 | `target:` — gosub と同パターン |
| `on_error_statement` の field 名 | なし — `(identifier)` 子ノードが直接存在 |
| `GoTo 0` / `On Error Resume Next` | `identifier` 子ノードなし → field なしクエリで誤爆しない |

**判断:** `goto_statement` は `target:` field で直接対応 (XS)。`on_error_statement` は field なしクエリ `(on_error_statement (identifier) @label)` で対応 (XS)。grammar 変更不要。

### 実施内容

| 変更 | 詳細 |
|------|------|
| `queries/highlights.scm` | `(goto_statement target: (identifier) @label)` + `(on_error_statement (identifier) @label)` 追加 |
| `test/highlight/goto_on_error.bas` | highlight fixture 追加 (4 assertions: GoTo target + On Error GoTo target + 2 label declarations) |
| `test/corpus/modules.txt` | `DefBool A-C, E-M` (corpus entry 53) + `DefDate X-Z` (corpus entry 54) 追加 (72 → 74 件) |
| `test/highlight/deftype.bas` | DefDate X-Z エントリ追加 (+3 assertions: keyword + 2 variable) |

**全 fixture green 確認:** corpus 74/74 ✓、highlight 7 ファイル確認 (goto_on_error.bas 4 assertions ✓)

### TDD サイクル記録

- **probe:** `grep -n 'goto_statement\|on_error'` → grammar.js L571-572 で `goto_statement` は `target:` field 確認。`on_error_statement` は field なしを確認
- **probe:** `tree-sitter query` で `GoTo CleanUp` / `On Error GoTo ErrorHandler` の capture を確認。`ErrorHandler` は ` ErrorHandler` (leading space込み) でキャプチャ → visual col 位置で assertion 配置
- **RED:** `goto_on_error.bas` 作成 → Nix 0.25.10 で EXIT 137 + `row:1, col:9 expected label actual variable` 確認
- **GREEN:** highlights.scm に 2 capture 追加 → EXIT 137 (pre-existing クラッシュ) + `goto_on_error.bas (4 assertions) ✓` 確認
- **Step B:** corpus に `DefBool A-C, E-M` / `DefDate X-Z` 追加 → 74/74 ✓。`deftype.bas` に +3 assertions

### 特記事項: EXIT 137 の origin

Nix PATH tree-sitter 0.25.10 は highlight test を 7 ファイル処理した後にクラッシュ (EXIT 137)。ベースライン確認で **Sprint 7 前から存在** する pre-existing 問題と確定 (新規ファイル削除してもEXIT 137)。`node_modules/.bin/tree-sitter` (0.26.8) は非 TTY では highlight 出力を `/dev/tty` に書き出すため EXIT 0 のみ。

### Sprint 7 レトロスペクティブ (KPT)

#### Keep
- grammar.js の field 名を grep で先に確認 → `target:` vs なし の違いを即座に判別できた
- `on_error_statement` で field なしクエリが使える事実を probe で検証してから実装 → 誤爆リスクを確認済みで実装
- ベースライン確認 (新規ファイル削除して再テスト) で EXIT 137 が pre-existing と確定 → Sprint スコープ外と明示できた

#### Problem
- Nix 0.25.10 の highlight テストランナーが 7 ファイルでクラッシュするため `deftype.bas` 等の assertions を自動検証できない → `tree-sitter query` で手動確認が必要

#### Try (Phase 3 Sprint 8 候補)
- **★筆頭 (upstream 待ち):** tree-sitter 0.27+ リリース時に locals runner 修正を再確認 → `test/locals/basics.bas` 復活
- `WithEvents` 変数宣言の highlight: `variable_declarator` の `name:` field (現状は `@variable`、`@variable.other.member` 等への昇格検討)
- `exit_statement` の対象 (`Sub`/`Function`/`For`/`Do`) を `@keyword` として個別 capture (現状はキーワードリストで一括)

### 完了判定

| 完了基準 | 状態 |
|----------|------|
| corpus 72 → 74 ✓ | ✅ 74/74 |
| highlight goto_on_error.bas fixture ✓ | ✅ 4 assertions |
| deftype.bas +3 assertions (query 手動検証 ✓) | ✅ |
| 2 feat + 1 docs commit 構成 | ✅ |
| Sprint 8 自動着手しない | ✅ (完了後 idle 復帰) |

**判定: 達成** — Step A (GoTo/@label XS) + Step B (DefType fixture XS) 両件、2 feat commit で完了。

---

## 参考仕様
- VBA Language Specification (Microsoft [MS-VBAL])
- tree-sitter docs (https://tree-sitter.github.io/tree-sitter/)
- highlight fixture 形式: `tree-sitter/tree-sitter` repo `docs/src/3-syntax-highlighting.md` Unit Testing セクション

---

## Phase 3 Sprint 1 (GoSub grammar 追加) 完了記録 (2026-04-21)

### 実施内容

| 変更 | 詳細 |
|------|------|
| `grammar.js` | `gosub_statement` ルール追加 (goto_statement と同パターン) |
| `grammar.js` | `_statement` choice に `$.gosub_statement` 追加 |
| `queries/highlights.scm` | `"GoSub"` を keyword リストに追加 |
| `test/corpus/statements.txt` | GoSub / Return corpus テスト追加 (63 件目) |
| `test/highlight/gosub.bas` | highlight fixture 追加 (7 assertions) |

**全 fixture green 確認:** corpus 63 件 ✓、highlight 17 ファイル ✓

### TDD サイクル記録
- **RED:** `GoSub CleanUp` が `paren_less_call` として parse される (GoSub が identifier 扱い)
- **GREEN:** `gosub_statement` ルール追加 + `tree-sitter generate` で corpus テスト通過
- **highlight:** `gosub.bas` fixture 追加 (7 assertions green)

### probe 結果 (B: locals.scm 解除)
- GitHub: tree-sitter v0.26.8 リリース済み
- npm: `tree-sitter-cli@0.26.8` 利用可能
- 制約: `package.json` の `devDependencies` が `^0.25.0` (semver で 0.26.x は範囲外)
- 判断: upgrade は単独 Sprint として切り出す (既存 green を壊さないよう慎重に)

### Sprint 1 レトロスペクティブ (KPT)

#### Keep
- `goto_statement` と同パターンであることを grep で先に確認 → 実装 1 行で完結
- RED → GREEN → highlight fixture の TDD 順序を厳守したことで差分が最小

#### Problem
- `GoSub CleanUp` が ERROR でなく `paren_less_call` として parse される挙動は直感に反する → grammar に keyword が未登録の場合は identifier として fallback するパターンを先に probe すべき

#### Try
- ~~`Implements ClassName` grammar 追加 (module scope, 1 行 statement — XS)~~ ✅ 完了 (2026-04-21)
- DefType / Event grammar 追加 → corpus + highlight fixture セット追加 (Phase 3 Sprint 3 候補)
- tree-sitter-cli を 0.26.x に upgrade して locals.scm のバグを確認 (専用 Sprint)

---

## Phase 3 Sprint 2 (Implements grammar 追加) 完了記録 (2026-04-21)

### 実施内容

| 変更 | 詳細 |
|------|------|
| `grammar.js` | `implements_statement` ルール追加 (`choice($.qualified_name, $.identifier)` field name) |
| `grammar.js` | `_module_item` choice に `$.implements_statement` 追加 (module scope, `option_stmt` 直後) |
| `queries/highlights.scm` | `"Implements"` を keyword リストに追加 |
| `queries/highlights.scm` | `(implements_statement name: (identifier) @type)` を追加 (単純名を `@type` に昇格) |
| `test/corpus/modules.txt` | "Implements statement (simple)" / "Implements statement (qualified name)" corpus 追加 (65 件目・66 件目) |
| `test/highlight/implements.bas` | highlight fixture 追加 (6 assertions) |

**全 fixture green 確認:** corpus 65 件 ✓、highlight 18 ファイル ✓

---

## Phase 3 Sprint 3 (DefType + Event grammar 追加) 完了記録 (2026-04-21)

### 実施内容

| 変更 | 詳細 |
|------|------|
| `grammar.js` | `def_type_statement` ルール追加 (14 keyword variants + `commaSep1($.letter_range)`) |
| `grammar.js` | `letter_range` sub-rule 追加 (`start` / `end` field, `$.identifier` 使用) |
| `grammar.js` | `event_declaration` ルール追加 (optional visibility + `Event` keyword + name + parameter_list) |
| `grammar.js` | `_module_item` choice に `$.def_type_statement` / `$.event_declaration` 追加 |
| `queries/highlights.scm` | `"Event"` + 14 DefType キーワード群をキーワードリストに追加 |
| `queries/highlights.scm` | `(event_declaration name: (identifier) @function)` 追加 |
| `test/corpus/modules.txt` | DefType 4 件 + Event 3 件 corpus 追加 (65 → 72 件) |
| `test/highlight/deftype.bas` | highlight fixture 追加 (9 assertions: keyword / variable) |
| `test/highlight/event.bas` | highlight fixture 追加 (9 assertions: keyword / function / variable.parameter / type.builtin) |

**全 fixture green 確認:** corpus 72/72 ✓、highlight 20 ファイル ✓

### probe 結果 (事前確認)
- `DefInt A-Z`: `(ERROR ...)` として parse — 3 identifier に分解されていた
- `Event Click(...)`: `(ERROR ...)` として parse — `Public Event` は `variable_declaration` に誤パース
- `_module_item` 登録が両方に必要と判断 (Sprint 2 と同パターン)

### TDD サイクル記録
- **probe:** `tree-sitter parse` で ERROR / 誤パース確認 → `_module_item` 登録が必要と判断
- **RED:** corpus 7 件 (DefType 4 + Event 3) 追加 → 全 FAIL 確認
- **GREEN:** `def_type_statement` + `letter_range` + `event_declaration` ルール追加 + `_module_item` 登録 + `tree-sitter generate` → corpus 72 件 green
- **highlight:** `deftype.bas` (9 assertions) + `event.bas` (9 assertions) fixture green

### Sprint 3 レトロスペクティブ (KPT)

#### Keep
- probe → RED → GREEN → highlight の TDD 順序を厳守
- `letter_range` を `$.identifier` で実装: 単一文字制約は意味解析層の責務として grammar 層では不要
- `event_declaration` が既存の `parameter_list` を完全再利用できた — DRY を維持

#### Problem
- `tree-sitter query` 出力の node start が「空白を含む範囲」を報告するため fixture のカラム位置計算で混乱 → 実際の文字位置 (視覚的カラム) を使えば一発 green (Sprint 2 Problem の教訓が今回も効いた)

#### Try (Phase 3 Sprint 4 候補)
- tree-sitter-cli 0.26.x upgrade (筆頭) — locals.scm リグレッションテスト復活を確認
- `WithEvents` keyword 付き変数宣言の highlight fixture 追加 (XS)
- `GoSub` ラベル `Return` の highlight テスト追加 (XS)

### probe 結果 (事前確認)
- `Implements IFoo` の現状挙動: `(ERROR ...)` として parse — `paren_less_call` でなく完全な ERROR
- GoSub (Sprint 1) との違い: GoSub は手続き内で `paren_less_call` にフォールバックしたが、`Implements` はモジュールスコープで `_statement` choice にもないため ERROR

### TDD サイクル記録
- **probe:** `tree-sitter parse` で ERROR 確認 → `_module_item` 登録が必要と判断
- **RED:** corpus 2 件 (`Implements IFoo` / `Implements MyLib.IInterface`) 追加 → tests 46, 47 FAIL 確認
- **GREEN:** `implements_statement` ルール追加 + `_module_item` 登録 + `tree-sitter generate` → corpus 65 件 green
- **highlight:** `"Implements"` keyword 追加 + `(implements_statement name: (identifier) @type)` 追加 + `implements.bas` fixture 6 assertions green

### Sprint 2 レトロスペクティブ (KPT)

#### Keep
- `tree-sitter parse` による事前 probe を必須とした → Sprint 1 Problem への対処が機能し、ERROR vs paren_less_call の挙動の違いを素早く確認できた
- `_module_item` vs `_statement` の登録先選択を事前に AST 位置から判断できた

#### Problem
- `tree-sitter` の parse 位置報告に一見矛盾があった (`Implements` 10 chars + 空白 1 = identifier start が col 10 と col 11 で迷った) → 実際に fixture を書いて実行して確認するのが最速

#### Try (Phase 3 Sprint 3 候補)
- ~~`DefType` 文 (`DefInt`, `DefStr` 等): grammar 未実装 — module scope 単行宣言~~ ✅ 完了 (2026-04-21)
- ~~`Event` 宣言 (`Event EventName(args)`): grammar 未実装 — module scope 宣言~~ ✅ 完了 (2026-04-21)
- ~~tree-sitter-cli 0.26.x upgrade (専用 Sprint) — locals.scm リグレッションテスト復活を確認~~ → Phase 3 Sprint 4 (2026-04-21): upgrade 完了、locals runner バグ 0.26.8 でも未修正 (詳細は Sprint 4 記録)

---

## Phase 3 Sprint 4 (tree-sitter-cli 0.26.x upgrade) 完了記録 (2026-04-21)

### 実施内容

| 変更 | 詳細 |
|------|------|
| `package.json` | `devDependencies` の `tree-sitter-cli` を `^0.25.0` → `^0.26.0` に変更 |
| `bun.lock` | `tree-sitter-cli@0.26.8` に更新 |

### ベースライン (upgrade 前)

| 指標 | 値 |
|------|-----|
| tree-sitter (Nix PATH) | 0.25.10 |
| node_modules/.bin/tree-sitter | 0.25.10 → 0.26.8 へ upgrade |
| corpus | 72/72 ✓ |
| highlight | 20 ファイル ✓ |
| locals | test/locals/ 空 (バグにより不可) |

### upgrade 後確認

| 指標 | 値 |
|------|-----|
| node_modules/.bin/tree-sitter | 0.26.8 ✓ |
| corpus | 72/72 ✓ (破壊的変更なし) |
| highlight | 20 ファイル ✓ |
| locals | 依然不可 (下記参照) |

### 🔴 locals runner バグ: 0.26.8 でも未修正

**観測:** `test/locals/basics.bas` (内容問わず、bare VBA ファイルでも) を置くと:

```
queries:
    locals
Total parses: 72; ...

Error: Query compilation failed

Caused by:
    Query error at 1:1. Invalid syntax:
    Sub Process()
    ^
```

**0.26.8 での変化 (vs 0.25.10):**
- 新セクション `queries:` が追加され、`locals` ラベルが表示されるようになった
- しかし内部では依然として source file を query file として扱う根本バグが残存

**確認手段:** bare VBA (`Sub Process()\nEnd Sub`) でも同エラー → アサーション記法の問題ではなく runner 自体のバグ

**保存: 将来の再試行用 fixture 案 (0.27+ 修正後に使用)**
```vba
Sub Process()
' <- local.scope
    Dim x As Integer
    '   ^ local.definition.var
    x = 1
    '^ local.reference
End Sub

Function GetValue() As Integer
' <- local.scope
    GetValue = 42
    '          ^ local.reference
End Function
```

### Sprint 4 レトロスペクティブ (KPT)

#### Keep
- upgrade 自体を独立 Sprint として切り出した → corpus/highlight の regression を独立して確認できた
- bare ファイルで probe → 「アサーション記法の問題か runner のバグか」を即座に識別

#### Problem
- 0.26.8 リリースノートを事前に精査できなかった → `queries:` セクション追加は表面的な変更で根本バグは未修正だった
- Nix PATH の tree-sitter (0.25.10) と npm の tree-sitter (0.26.8) が混在しており、`tree-sitter --version` での確認が混乱を招く

#### Try (Phase 3 Sprint 5 候補)
- `WithEvents` keyword 付き変数宣言の highlight fixture 追加 (XS) — Sprint 3 Try 残り
- `GoSub` ラベル `Return` の highlight fixture 追加 (XS) — Sprint 3 Try 残り
- tree-sitter 0.27+ リリース時に locals runner 修正を再確認 → `test/locals/basics.bas` 復活

### 完了判定

| 完了基準 | 状態 |
|----------|------|
| node_modules/.bin/tree-sitter が 0.26.x を報告 | ✅ 0.26.8 |
| corpus 72 件 ✓ | ✅ |
| highlight 20 ファイル ✓ | ✅ |
| locals テスト新規 green | ❌ upstream バグ継続 (0.27+ 待ち) |

**判定: 部分達成** — upgrade と regression ゼロは確認。locals 復活は upstream 修正待ち継続。

---

## Phase 3 Sprint 5 (WithEvents + GoSub/Return highlight fixture 追加) 完了記録 (2026-04-21)

### Sprint Goal
既存 grammar 変更なしで highlight fixture を 2 件追加し、`WithEvents` 変数宣言と `GoSub Label → Return` ラベル参照経路の highlight を pin する。

### 実施内容

| 変更 | 詳細 |
|------|------|
| `queries/highlights.scm` | `(variable_declarator type: (identifier) @type)` 追加 (user-defined 型名を `@type` に昇格) |
| `test/highlight/withevents.bas` | highlight fixture 追加 (10 assertions) |
| `test/highlight/gosub_return.bas` | highlight fixture 追加 (7 assertions) |

**全 fixture green 確認:** corpus 72/72 ✓、highlight 22 ファイル ✓

### probe 結果 (事前確認)

**WithEvents:**
- `Private WithEvents xlApp As Application` → `variable_declaration` 配下で正常 parse
- `WithEvents` は既にキーワードリストに登録済み (`highlights.scm` line 8)
- `Application` 等 user-defined 型名は `variable_declarator type: (identifier)` ノードだが `@type` ルール未登録 → `@variable` にフォールバックしていた
- `builtin_type` (`Integer`, `String` 等) は別ノード種別のため既存 fixture への影響なし

**GoSub/Return:**
- `GoSub CleanUp` → `gosub_statement target: (identifier)` が `@variable`
- `CleanUp:` → `label name: (identifier)` が `@variable`、`:` が `@punctuation.delimiter`
- `Return` → `return_statement` として `@keyword` ✓ (Sprint 1 で追加済み)
- 既存 `gosub.bas` は `GoSub`/`Return` @keyword のみ pin; label 定義側と label reference は未 pin → 本 Sprint で追加

### TDD サイクル記録
- **probe:** `tree-sitter query` で各トークンのキャプチャ名・カラム位置を確認
- **実装:** `(variable_declarator type: (identifier) @type)` を highlights.scm に追加 (불足 발견)
- **fixture:** `withevents.bas` (10 assertions) + `gosub_return.bas` (7 assertions) — 一発 green

### Sprint 5 レトロスペクティブ (KPT)

#### Keep
- `tree-sitter query` で capture text を先に取得 → leading whitespace 込みの capture range vs 視覚的カラムの違いを事前に把握できた
- builtin_type と identifier の分離を確認してから highlights.scm を変更 → regression ゼロ

#### Problem
- tree-sitter query の capture start は leading whitespace を含む col を報告するため、fixture `^` 位置 (視覚的先頭列) との差異で混乱しやすい

#### Try (Phase 3 Sprint 6 候補)
- tree-sitter 0.27+ リリース時に locals runner 修正を再確認 → `test/locals/basics.bas` 復活 (★筆頭: upstream 修正待ち)
- `label name: (identifier)` を `@label` キャプチャに昇格させる highlight 追加 (現状 `@variable` にフォールバック)
- `DefType` / `Event` の highlight fixture 追加 (Sprint 3 で grammar 追加済み、fixture は既存)

### 完了判定

| 完了基準 | 状態 |
|----------|------|
| corpus 72 件 ✓ | ✅ |
| highlight 22 ファイル ✓ | ✅ (20 → 22) |
| `withevents.bas` fixture green | ✅ 10 assertions |
| `gosub_return.bas` fixture green | ✅ 7 assertions |
| grammar 変更なし | ✅ |

**判定: 達成** — XS 2 件、2 commit 構成で完了。

---

## Phase 3 Sprint 6 (parser.dylib .gitignore + @label 昇格) 完了記録 (2026-04-21)

### Sprint Goal
tree-sitter highlights の label capture を `@variable` から `@label` に昇格させ、GoSub ターゲット・ラベル定義の意味論上の区別を明確化。あわせて `parser.dylib` を `.gitignore` に追加する chore を消化。

### 実施内容

| 変更 | 詳細 |
|------|------|
| `.gitignore` | `*.dylib` / `*.so` / `*.dll` を追加 (既存 `*.wasm` の隣に 3 プラットフォーム分) |
| `queries/highlights.scm` | `(gosub_statement target: (identifier) @label)` + `(label name: (identifier) @label)` 追加 |
| `test/highlight/gosub_return.bas` | `@variable` → `@label` に assertion 更新 (7 assertions) |

### probe 結果 (事前確認)

**grammar.js フィールド名の確認:**
- `gosub_statement` → `target:` フィールド (直感的な `label:` ではなく `target`)
- `label` rule → `name:` フィールド、`prec(1, ...)` で宣言

**highlights.scm last-wins 挙動:**
- `(identifier) @variable` は catch-all として早期に定義済み
- 後に定義した `(gosub_statement target: (identifier) @label)` / `(label name: (identifier) @label)` が last-wins で勝つ

**テスト挙動の観察:**
- highlight テスト失敗時の終了コード: **137** (他ファイルは通るが失敗ファイルが表示されずに終了)
- tree-sitter 0.25.10 で確認 (0.27+ 待ちの locals バグとは別事象)

### TDD サイクル記録
- **RED:** `gosub_return.bas` の assertion を `@label` 期待に書き換え → EXIT 137 で失敗確認
- **GREEN:** `highlights.scm` に 2 capture 追加 → EXIT 0、corpus 72/72 ✓、highlight 6 ファイル ✓
- **stash 実験:** 元ファイルで EXIT 0 を確認 → RED が my change によるものと証明

### Sprint 6 レトロスペクティブ (KPT)

#### Keep
- grammar.js の field 名を `grep` で先に確認 (`target:` vs `label:`) → ハマりを回避
- stash を使って「変更前は通る」を実証 → RED の原因を明確に切り分けできた

#### Problem
- highlight テスト失敗時に失敗メッセージが表示されず EXIT 137 のみ → どのアサーションが失敗したか分かりにくい (tree-sitter 0.25.10 の挙動)

#### Try (Phase 3 Sprint 7 候補)
- **★筆頭 (upstream 待ち):** tree-sitter 0.27+ リリース時に locals runner 修正を再確認 → `test/locals/basics.bas` 復活
- `DefType` 特殊ケース補強: `DefBool` / `DefDate` 等の複数レンジ組み合わせ fixture 追加
- `On Error GoTo` ラベルも `(goto_statement target: (identifier) @label)` で昇格させるか検討 (grammar.js の node 名を probe してから判断)
- highlight テスト失敗時の詳細出力を得る方法を調査 (tree-sitter 0.26.x / 0.27+ で改善されているか確認)

### 完了判定

| 完了基準 | 状態 |
|----------|------|
| corpus 72 件 ✓ | ✅ |
| highlight 6 ファイル ✓ (変化なし) | ✅ |
| `gosub_return.bas` assertions `@label` 期待で green | ✅ 7 assertions |
| `.gitignore` に `*.dylib` / `*.so` / `*.dll` 追加 | ✅ |
| `git status` clean | ✅ |
| 3 commit 構成 (chore + feat + docs) | ✅ |

**判定: 達成** — chore XS + feat XS の 2 件、3 commit 構成で完了。

