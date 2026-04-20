; Syntax highlighting captures for VBA.
; Keyword, operator, literal, and identifier classes follow the
; nvim-treesitter capture naming conventions.

; Keywords
[
  "Sub" "Function" "Property" "End" "Get" "Let" "Set"
  "Dim" "Public" "Private" "Friend" "Static" "Const" "Global" "ReDim" "Preserve" "WithEvents"
  "As" "Optional" "ByVal" "ByRef" "ParamArray" "New"
  "If" "Then" "Else" "ElseIf"
  "For" "Each" "In" "To" "Step" "Next"
  "Do" "Loop" "While" "Wend" "Until"
  "Select" "Case" "Is"
  "With"
  "Call" "Return" "Exit" "GoSub" "Implements" "Event"
  "DefBool" "DefByte" "DefCur" "DefDate" "DefDbl" "DefDec"
  "DefInt" "DefLng" "DefLngLng" "DefLngPtr" "DefObj" "DefSng" "DefStr" "DefVar"
  "Type" "Enum"
  "On" "Error" "GoTo" "Resume"
  "Option" "Explicit" "Compare" "Base" "Binary" "Text" "Database"
  "Declare" "PtrSafe" "Lib" "Alias"
  "AddressOf" "Attribute"
  "Me"
] @keyword

; Operators (as keywords)
[
  "And" "Or" "Xor" "Not" "Eqv" "Imp" "Mod" "Like"
] @keyword.operator

(builtin_type) @type.builtin

(ptr_safe) @keyword
(preserve) @keyword

; Generic identifier catch-all — must appear BEFORE specific identifier
; rules because tree-sitter highlights use last-wins semantics: a later
; pattern index overrides an earlier one for the same node position.
(identifier) @variable

; Declarations
(sub_declaration name: (identifier) @function)
(function_declaration name: (identifier) @function)
(property_declaration name: (identifier) @function)
(declare_statement name: (identifier) @function)

(parameter name: (identifier) @variable.parameter)

(type_declaration name: (identifier) @type)
(enum_declaration name: (identifier) @type)
(type_field name: (identifier) @property)
(enum_member name: (identifier) @constant)

(const_declaration name: (identifier) @constant)

(implements_statement name: (identifier) @type)
(event_declaration name: (identifier) @function)
(variable_declarator type: (identifier) @type)

; Calls
(call_expression function: (identifier) @function.call)
(call_expression function: (member_access property: (identifier) @function.method))
(paren_less_call function: (identifier) @function.call)
(paren_less_call function: (member_access property: (identifier) @function.method))

; Labels (GoSub/GoTo/On Error GoTo targets and label declarations)
(gosub_statement target: (identifier) @label)
(goto_statement target: (identifier) @label)
(on_error_statement (identifier) @label)
(label name: (identifier) @label)

(member_access property: (identifier) @property)
(leading_dot_member_access property: (identifier) @property)

; Literals
(string_literal) @string
(integer_literal) @number
(float_literal) @number.float
(hex_literal) @number
(octal_literal) @number
(date_literal) @string.special
(boolean_literal) @constant.builtin
(nothing_literal) @constant.builtin
(null_literal) @constant.builtin
(empty_literal) @constant.builtin

(comment) @comment

; Preprocessor directives
[
  "#If" "#ElseIf" "#Else" "#End" "#Const"
] @keyword.directive

(preprocessor_const
  name: (identifier) @variable)

; Preprocessor condition identifiers are compile-time constants in VBA
; (e.g. VBA7, Win64, user-defined #Const). Compound conditions are highlighted
; via the generic operator/identifier/literal rules later in this file.
(preprocessor_if
  condition: (identifier) @constant)

(preprocessor_elseif
  condition: (identifier) @constant)

; Punctuation
[ "(" ")" "," "." ":" ] @punctuation.delimiter
[ "=" "+" "-" "*" "/" "\\" "^" "&" "<" ">" "<=" ">=" "<>" ":=" ] @operator

(qualified_name
  library: (identifier) @namespace
  name: (identifier) @type)
