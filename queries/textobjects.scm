; nvim-treesitter-textobjects captures for VBA.
; https://github.com/nvim-treesitter/nvim-treesitter-textobjects

; ---------------------------------------------------------------------------
; @function.outer / @function.inner
; ---------------------------------------------------------------------------

(sub_declaration) @function.outer
(sub_declaration
  body: (statement_block) @function.inner)

(function_declaration) @function.outer
(function_declaration
  body: (statement_block) @function.inner)

(property_declaration) @function.outer
(property_declaration
  body: (statement_block) @function.inner)

; ---------------------------------------------------------------------------
; @class.outer / @class.inner
; VBA has no class keyword; Type and Enum are the closest structural analogs.
; @class.inner captures each member so the plugin spans from first to last.
; ---------------------------------------------------------------------------

(type_declaration) @class.outer
(type_declaration
  (type_field) @class.inner)

(enum_declaration) @class.outer
(enum_declaration
  (enum_member) @class.inner)
