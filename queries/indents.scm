; Indent rules compatible with nvim-treesitter-indent.
;
; Capture semantics:
;   @indent.begin   - children of this node indent one level
;   @indent.end     - children return to the parent level
;   @indent.branch  - dedent this line then re-indent subsequent lines
;   @indent.dedent  - dedent this line once
;   @indent.auto    - let the indenter decide automatically

; ---------------------------------------------------------------------------
; Bodies that should indent one level
; ---------------------------------------------------------------------------
(sub_declaration
  body: (statement_block) @indent.begin)

(function_declaration
  body: (statement_block) @indent.begin)

(property_declaration
  body: (statement_block) @indent.begin)

(for_statement
  body: (statement_block) @indent.begin)

(for_each_statement
  body: (statement_block) @indent.begin)

(do_statement
  body: (statement_block) @indent.begin)

(while_statement
  body: (statement_block) @indent.begin)

(with_statement
  body: (statement_block) @indent.begin)

; If / ElseIf / Else — each body indents one level.
(if_statement
  consequence: (statement_block) @indent.begin)

(if_statement
  elseif_body: (statement_block) @indent.begin)

(if_statement
  alternative: (statement_block) @indent.begin)

; Type and Enum members indent one level.
(type_declaration
  (type_field) @indent.begin)

(enum_declaration
  (enum_member) @indent.begin)

; Select Case: each Case clause gets its own indented body.
(case_clause) @indent.begin
(case_else_clause) @indent.begin

; Preprocessor #If / #ElseIf / #Else — each conditional body indents one
; level. These nodes don't expose a `body:` field in the grammar (body
; items are unnamed repeated children), so we capture the whole node as
; the indent container and rely on the explicit dedent/branch tokens
; below to close / re-indent at `#End If`, `#ElseIf`, and `#Else`.
(preprocessor_if) @indent.begin
(preprocessor_elseif) @indent.begin
(preprocessor_else) @indent.begin

; ---------------------------------------------------------------------------
; Dedent tokens: End / Loop / Next / Wend close a block.
; ---------------------------------------------------------------------------
; Note: "End" (used for End Sub / End If / ...) and "#End" (used for
; #End If) are *distinct* anonymous tokens in the grammar, so the bare
; "End" literal below does NOT match `#End`. We add an explicit entry
; for "#End" to dedent the `#End If` line that closes a preprocessor_if.
[
  "End"
  "#End"
  "Loop"
  "Next"
  "Wend"
] @indent.dedent

; ---------------------------------------------------------------------------
; Branch tokens: ElseIf / Else / Case dedent then re-indent.
; ---------------------------------------------------------------------------
; "#ElseIf" / "#Else" are distinct anonymous tokens from "ElseIf" /
; "Else" (they include the leading `#`), so we list them explicitly to
; get the same dedent-then-reindent behaviour on preprocessor lines.
[
  "ElseIf"
  "Else"
  "Case"
  "#ElseIf"
  "#Else"
] @indent.branch
