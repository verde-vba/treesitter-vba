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

; ---------------------------------------------------------------------------
; Dedent tokens: End / Loop / Next / Wend close a block.
; ---------------------------------------------------------------------------
[
  "End"
  "Loop"
  "Next"
  "Wend"
] @indent.dedent

; ---------------------------------------------------------------------------
; Branch tokens: ElseIf / Else / Case dedent then re-indent.
; ---------------------------------------------------------------------------
[
  "ElseIf"
  "Else"
  "Case"
] @indent.branch
