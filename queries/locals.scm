; Scope and definition captures for VBA, used by nvim-treesitter's
; locals module to resolve identifier references within a module.

; Scopes
[
  (sub_declaration)
  (function_declaration)
  (property_declaration)
  (for_statement)
  (for_each_statement)
  (with_statement)
] @local.scope

; Definitions: callables
(sub_declaration
  name: (identifier) @local.definition.function)
(function_declaration
  name: (identifier) @local.definition.function)
(property_declaration
  name: (identifier) @local.definition.function)

; Definitions: parameters
(parameter
  name: (identifier) @local.definition.parameter)

; Definitions: variables
(variable_declarator
  name: (identifier) @local.definition.var)

; Definitions: constants
(const_declaration
  name: (identifier) @local.definition.constant)

; Definitions: preprocessor constants (module-wide syntactic scope).
; References such as `#If DEBUG_MODE Then` or `#If DEBUG_MODE And VBA7 Then`
; resolve through the generic `(identifier) @local.reference` rule below,
; because `condition:` holds either an identifier or a binary_expression
; whose operands are identifiers.
(preprocessor_const
  name: (identifier) @local.definition.constant)

; Definitions: types
(type_declaration
  name: (identifier) @local.definition.type)
(enum_declaration
  name: (identifier) @local.definition.type)

; Definitions: labels
(label
  name: (identifier) @local.definition.label)

; References: plain identifiers used as expressions.
; Declarations above capture `name:` fields first, so non-declaration
; identifiers fall through to this generic reference pattern.
(identifier) @local.reference
