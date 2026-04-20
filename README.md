# tree-sitter-vba

VBA (Visual Basic for Applications) grammar for [tree-sitter](https://tree-sitter.github.io/).

## Status

Handles the most common constructs found in `.bas` / `.cls` / `.frm` files:

- Modules, `Option` statements, `Attribute` headers
- `Sub`, `Function`, `Property Get/Let/Set` declarations (with `ByVal`, `ByRef`, `Optional`, `ParamArray`)
- `Declare [PtrSafe] Function/Sub Lib ... [Alias ...]`
- `Dim`, `Public`, `Private`, `Static`, `Const`, `ReDim [Preserve]`
- Types (built-in, user defined `Type`/`End Type`, `Enum`, arrays, `As New`)
- Control flow: `If/ElseIf/Else`, `For/Next`, `For Each`, `Do/Loop`, `While/Wend`, `Select Case`, `With`
- Expressions: arithmetic, comparison, logical, member access, indexing, `New`, `AddressOf`
- Literals: integer, float, hex (`&H`), octal (`&O`), string, date (`#...#`), `True`/`False`/`Nothing`/`Null`/`Empty`
- Comments (`'`, `Rem`), line continuation (` _<NL>`)
- Error handling: `On Error GoTo`, `On Error Resume Next`, `Resume`

## Bindings

### Node.js

```js
const Parser = require('tree-sitter');
const VBA = require('tree-sitter-vba');

const parser = new Parser();
parser.setLanguage(VBA);
const tree = parser.parse('Sub Hello(): MsgBox "hi": End Sub');
```

### Rust

```toml
[dependencies]
tree-sitter = "0.25"
tree-sitter-vba = "0.1"
```

```rust
let mut parser = tree_sitter::Parser::new();
parser.set_language(&tree_sitter_vba::LANGUAGE.into()).unwrap();
```

## Queries

Available under `queries/`:

- `highlights.scm` — syntax highlighting captures
- `folds.scm` — foldable block regions
- `locals.scm` — scopes, definitions, and references
- `indents.scm` — indent/dedent/branch hints for nvim-treesitter-indent

nvim-treesitter discovers these automatically once the parser is installed; the `tree-sitter` field in `package.json` points editors at the same files.

## Examples

`examples/` contains runnable fixtures used to smoke-test end-to-end parsing:

- `Sample.bas` — standard module covering declarations, control flow, and expressions
- `ClassModule.cls` — class module with `VB_PredeclaredId`, fields, and properties
- `FormEvent.bas` — event handler style sub with conditional logic
- `ErrorHandling.bas` — `On Error GoTo` / `Resume` patterns

## Development

```sh
npm install              # fetch tree-sitter-cli
npx tree-sitter generate # regenerate src/ from grammar.js
npx tree-sitter test     # run the corpus tests under test/corpus
npx tree-sitter parse examples/Sample.bas
```
