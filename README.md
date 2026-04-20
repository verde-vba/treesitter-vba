# tree-sitter-vba

VBA (Visual Basic for Applications) grammar for [tree-sitter](https://tree-sitter.github.io/).

## Status

MVP. Handles the most common constructs found in `.bas` / `.cls` files:

- Modules, `Option` statements, `Attribute` headers
- `Sub`, `Function`, `Property Get/Let/Set` declarations (with `ByVal`, `ByRef`, `Optional`, `ParamArray`)
- `Dim`, `Public`, `Private`, `Static`, `Const`, `ReDim [Preserve]`
- Types (built-in, user defined `Type`/`End Type`, `Enum`, arrays, `As New`)
- Control flow: `If/ElseIf/Else`, `For/Next`, `For Each`, `Do/Loop`, `While/Wend`, `Select Case`, `With`
- Expressions: arithmetic, comparison, logical, member access, indexing, `New`, `AddressOf`
- Literals: integer, float, hex (`&H`), octal (`&O`), string, date (`#...#`), `True`/`False`/`Nothing`/`Null`/`Empty`
- Comments (`'`, `Rem`), line continuation (` _<NL>`)
- Error handling: `On Error GoTo`, `On Error Resume Next`, `Resume`

## Build

```sh
npm install
npx tree-sitter generate
npx tree-sitter test
```

## Parse a file

```sh
npx tree-sitter parse path/to/Module1.bas
```
