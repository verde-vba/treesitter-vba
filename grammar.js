/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

/**
 * Case-insensitive literal keyword. Builds a regex that matches each letter in
 * either case, so that `Sub`, `sub`, `SUB` all parse the same.
 */
function ci(word) {
  const pattern = word
    .split('')
    .map((c) => (/[a-zA-Z]/.test(c) ? `[${c.toLowerCase()}${c.toUpperCase()}]` : c))
    .join('');
  return new RegExp(pattern);
}

/** Keyword token aliased back to its canonical spelling in the AST. */
function kw(word) {
  return alias(token(ci(word)), word);
}

/**
 * Preprocessor keyword token (e.g. `#If`, `#Const`). `#` is matched literally
 * and the keyword body is case-insensitive. Aliased to `#Word` in the AST.
 */
function kwSharp(word) {
  return alias(token(seq('#', ci(word))), '#' + word);
}

const PREC = {
  imp: 1,
  eqv: 2,
  xor: 3,
  or: 4,
  and: 5,
  not: 6,
  compare: 7,
  concat: 8,
  add: 9,
  mul: 10,
  mod: 11,
  int_div: 12,
  unary: 13,
  power: 14,
  member: 15,
  call: 16,
};

module.exports = grammar({
  name: 'vba',

  word: ($) => $.identifier,

  extras: ($) => [/[ \t]/, $._line_continuation, $.comment],

  conflicts: ($) => [
    [$._primary_expression, $._type_name],
    // `preprocessor_directive` is reachable from both `_module_item` and
    // `_statement`; only at reduce time can we know which wrapper to pick.
    [$._module_item, $._statement],
    // `variable_declaration` and `const_declaration` are reachable from
    // both `_declaration` (module scope) and `_statement` (procedure scope),
    // so preprocessor bodies need to defer the choice.
    [$._declaration, $._statement],
  ],

  supertypes: ($) => [$._statement, $._expression, $._declaration],

  rules: {
    source_file: ($) =>
      seq(
        optional($._terminator),
        optional(
          seq(
            $._module_item,
            repeat(seq($._terminator, $._module_item)),
            optional($._terminator),
          ),
        ),
      ),

    _module_item: ($) =>
      choice(
        $.attribute_stmt,
        $.option_stmt,
        $.implements_statement,
        $.def_type_statement,
        $.event_declaration,
        $._declaration,
        $.preprocessor_directive,
      ),

    _declaration: ($) =>
      choice(
        $.sub_declaration,
        $.function_declaration,
        $.property_declaration,
        $.variable_declaration,
        $.const_declaration,
        $.type_declaration,
        $.enum_declaration,
        $.declare_statement,
      ),

    // ─── Headers / pragmas ─────────────────────────────────────────────

    attribute_stmt: ($) =>
      seq(kw('Attribute'), field('name', $.identifier), '=', field('value', $._expression)),

    option_stmt: ($) =>
      seq(
        kw('Option'),
        choice(
          kw('Explicit'),
          seq(kw('Compare'), choice(kw('Binary'), kw('Text'), kw('Database'))),
          seq(kw('Base'), $.integer_literal),
          kw('Private'),
        ),
      ),

    implements_statement: ($) =>
      seq(kw('Implements'), field('name', choice($.qualified_name, $.identifier))),

    def_type_statement: ($) =>
      seq(
        choice(
          kw('DefBool'), kw('DefByte'), kw('DefCur'), kw('DefDate'), kw('DefDbl'),
          kw('DefDec'), kw('DefInt'), kw('DefLng'), kw('DefLngLng'), kw('DefLngPtr'),
          kw('DefObj'), kw('DefSng'), kw('DefStr'), kw('DefVar'),
        ),
        commaSep1($.letter_range),
      ),

    letter_range: ($) =>
      seq(
        field('start', $.identifier),
        optional(seq('-', field('end', $.identifier))),
      ),

    event_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        kw('Event'),
        field('name', $.identifier),
        field('parameters', $.parameter_list),
      ),

    // ─── Preprocessor directives ──────────────────────────────────────
    //
    // VBA's conditional compilation directives (`#If` / `#ElseIf` / `#Else`
    // / `#End If`) and `#Const`. They appear at the same syntactic level
    // as declarations and statements, and may wrap either, so the inner
    // body is a synthetic `_preprocessor_body_item` choice covering both
    // module-level items and procedure-level statements.

    preprocessor_directive: ($) => choice($.preprocessor_const, $.preprocessor_if),

    preprocessor_const: ($) =>
      seq(kwSharp('Const'), field('name', $.identifier), '=', field('value', $._expression)),

    preprocessor_if: ($) =>
      seq(
        kwSharp('If'),
        field('condition', $._expression),
        kw('Then'),
        $._terminator,
        repeat(seq($._preprocessor_body_item, $._terminator)),
        repeat($.preprocessor_elseif),
        optional($.preprocessor_else),
        kwSharp('End'),
        kw('If'),
      ),

    preprocessor_elseif: ($) =>
      seq(
        kwSharp('ElseIf'),
        field('condition', $._expression),
        kw('Then'),
        $._terminator,
        repeat(seq($._preprocessor_body_item, $._terminator)),
      ),

    preprocessor_else: ($) =>
      seq(
        kwSharp('Else'),
        $._terminator,
        repeat(seq($._preprocessor_body_item, $._terminator)),
      ),

    // Preprocessor bodies can appear at both module scope (wrapping Sub /
    // Function / Property declarations) and procedure scope (wrapping
    // statements). `_module_item` is tried first so that module-level
    // declarations like `Sub Foo()` are recognised as `sub_declaration`
    // rather than falling back to `paren_less_call` via `_statement`.
    _preprocessor_body_item: ($) => choice($._module_item, $._statement),

    // ─── Procedure declarations ────────────────────────────────────────

    _visibility: ($) => $.visibility,

    visibility: (_) => choice(kw('Public'), kw('Private'), kw('Friend')),

    accessor: (_) => choice(kw('Get'), kw('Let'), kw('Set')),

    sub_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        optional(kw('Static')),
        kw('Sub'),
        field('name', $.identifier),
        optional(field('parameters', $.parameter_list)),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('End'),
        kw('Sub'),
      ),

    function_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        optional(kw('Static')),
        kw('Function'),
        field('name', $.identifier),
        optional(field('parameters', $.parameter_list)),
        optional(seq(kw('As'), field('return_type', $._type_name))),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('End'),
        kw('Function'),
      ),

    property_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        optional(kw('Static')),
        kw('Property'),
        field('accessor', $.accessor),
        field('name', $.identifier),
        optional(field('parameters', $.parameter_list)),
        optional(seq(kw('As'), field('return_type', $._type_name))),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('End'),
        kw('Property'),
      ),

    declare_statement: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        kw('Declare'),
        optional(field('ptr_safe', $.ptr_safe)),
        choice(kw('Sub'), kw('Function')),
        field('name', $.identifier),
        kw('Lib'),
        field('lib', $.string_literal),
        optional(seq(kw('Alias'), field('alias', $.string_literal))),
        optional(field('parameters', $.parameter_list)),
        optional(seq(kw('As'), field('return_type', $._type_name))),
      ),

    ptr_safe: (_) => kw('PtrSafe'),

    parameter_list: ($) => seq('(', optional(commaSep1($.parameter)), ')'),

    parameter: ($) =>
      seq(
        optional(kw('Optional')),
        optional(choice(kw('ByVal'), kw('ByRef'))),
        optional(kw('ParamArray')),
        field('name', $.identifier),
        optional(seq('(', ')')),
        optional(seq(kw('As'), field('type', $._type_name))),
        optional(seq('=', field('default', $._expression))),
      ),

    // ─── Variable / const / type / enum ───────────────────────────────

    variable_declaration: ($) =>
      seq(
        choice(kw('Dim'), kw('Public'), kw('Private'), kw('Static'), kw('Global')),
        optional(kw('WithEvents')),
        commaSep1($.variable_declarator),
      ),

    variable_declarator: ($) =>
      seq(
        field('name', $.identifier),
        optional($._array_bounds),
        optional(seq(kw('As'), optional(kw('New')), field('type', $._type_name))),
      ),

    _array_bounds: ($) =>
      seq(
        '(',
        optional(commaSep1($.array_bound)),
        ')',
      ),

    array_bound: ($) =>
      choice(
        seq(field('lower', $._expression), kw('To'), field('upper', $._expression)),
        $._expression,
      ),

    const_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        kw('Const'),
        commaSep1(
          seq(
            field('name', $.identifier),
            optional(seq(kw('As'), field('type', $._type_name))),
            '=',
            field('value', $._expression),
          ),
        ),
      ),

    type_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        kw('Type'),
        field('name', $.identifier),
        $._terminator,
        repeat(seq($.type_field, $._terminator)),
        kw('End'),
        kw('Type'),
      ),

    type_field: ($) =>
      seq(
        field('name', $.identifier),
        optional($._array_bounds),
        kw('As'),
        field('type', $._type_name),
      ),

    enum_declaration: ($) =>
      seq(
        optional(field('visibility', $._visibility)),
        kw('Enum'),
        field('name', $.identifier),
        $._terminator,
        repeat(seq($.enum_member, $._terminator)),
        kw('End'),
        kw('Enum'),
      ),

    enum_member: ($) =>
      seq(field('name', $.identifier), optional(seq('=', field('value', $._expression)))),

    // ─── Types ─────────────────────────────────────────────────────────

    _type_name: ($) =>
      choice(
        $.builtin_type,
        $.qualified_name,
        $.identifier,
      ),

    builtin_type: ($) =>
      choice(
        kw('Boolean'),
        kw('Byte'),
        kw('Currency'),
        kw('Date'),
        kw('Double'),
        kw('Integer'),
        kw('Long'),
        kw('LongLong'),
        kw('LongPtr'),
        kw('Object'),
        kw('Single'),
        kw('String'),
        kw('Variant'),
      ),

    // ─── Statements ────────────────────────────────────────────────────

    statement_block: ($) =>
      seq(
        $._statement,
        repeat(seq($._terminator, $._statement)),
        optional($._terminator),
      ),

    _statement: ($) =>
      choice(
        $.if_statement,
        $.for_statement,
        $.for_each_statement,
        $.do_statement,
        $.while_statement,
        $.select_statement,
        $.with_statement,
        $.on_error_statement,
        $.resume_statement,
        $.goto_statement,
        $.gosub_statement,
        $.exit_statement,
        $.return_statement,
        $.redim_statement,
        $.set_statement,
        $.let_statement,
        $.call_statement,
        $.variable_declaration,
        $.const_declaration,
        $.label,
        $.assignment,
        $.paren_less_call,
        $._expression_statement,
        $.preprocessor_directive,
      ),

    paren_less_call: ($) =>
      prec(
        -1,
        seq(
          field('function', choice($.identifier, $.member_access, $.leading_dot_member_access)),
          field('arguments', $.paren_less_argument_list),
        ),
      ),

    paren_less_argument_list: ($) => namedOrPositional($.identifier, $._expression),

    _expression_statement: ($) => $._expression,

    if_statement: ($) =>
      choice($._if_block, $._if_inline),

    _if_inline: ($) =>
      prec.right(
        seq(
          kw('If'),
          field('condition', $._expression),
          kw('Then'),
          field('consequence', $._statement),
          optional(seq(kw('Else'), field('alternative', $._statement))),
        ),
      ),

    _if_block: ($) =>
      seq(
        kw('If'),
        field('condition', $._expression),
        kw('Then'),
        $._terminator,
        field('consequence', optional($.statement_block)),
        repeat(
          seq(
            kw('ElseIf'),
            field('elseif_condition', $._expression),
            kw('Then'),
            $._terminator,
            field('elseif_body', optional($.statement_block)),
          ),
        ),
        optional(seq(kw('Else'), $._terminator, field('alternative', optional($.statement_block)))),
        kw('End'),
        kw('If'),
      ),

    for_statement: ($) =>
      seq(
        kw('For'),
        field('variable', $.identifier),
        '=',
        field('start', $._expression),
        kw('To'),
        field('end', $._expression),
        optional(seq(kw('Step'), field('step', $._expression))),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('Next'),
        optional($.identifier),
      ),

    for_each_statement: ($) =>
      seq(
        kw('For'),
        kw('Each'),
        field('variable', $.identifier),
        kw('In'),
        field('collection', $._expression),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('Next'),
        optional($.identifier),
      ),

    do_statement: ($) =>
      seq(
        kw('Do'),
        optional(
          seq(choice(kw('While'), kw('Until')), field('condition', $._expression)),
        ),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('Loop'),
        optional(
          seq(choice(kw('While'), kw('Until')), field('trailing_condition', $._expression)),
        ),
      ),

    while_statement: ($) =>
      seq(
        kw('While'),
        field('condition', $._expression),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('Wend'),
      ),

    select_statement: ($) =>
      seq(
        kw('Select'),
        kw('Case'),
        field('subject', $._expression),
        $._terminator,
        repeat($.case_clause),
        optional($.case_else_clause),
        kw('End'),
        kw('Select'),
      ),

    case_clause: ($) =>
      seq(
        kw('Case'),
        commaSep1($._case_match),
        $._terminator,
        field('body', optional($.statement_block)),
      ),

    case_else_clause: ($) =>
      seq(
        kw('Case'),
        kw('Else'),
        $._terminator,
        field('body', optional($.statement_block)),
      ),

    _case_match: ($) =>
      choice(
        seq($._expression, kw('To'), $._expression),
        seq(kw('Is'), choice('=', '<>', '<', '>', '<=', '>='), $._expression),
        $._expression,
      ),

    with_statement: ($) =>
      seq(
        kw('With'),
        field('object', $._expression),
        $._terminator,
        field('body', optional($.statement_block)),
        kw('End'),
        kw('With'),
      ),

    on_error_statement: ($) =>
      seq(
        kw('On'),
        kw('Error'),
        choice(
          seq(kw('GoTo'), choice($.integer_literal, $.identifier, '0')),
          seq(kw('Resume'), kw('Next')),
        ),
      ),

    resume_statement: ($) =>
      prec.right(seq(kw('Resume'), optional(choice(kw('Next'), $.integer_literal, $.identifier)))),

    goto_statement: ($) =>
      seq(kw('GoTo'), field('target', choice($.integer_literal, $.identifier))),

    gosub_statement: ($) =>
      seq(kw('GoSub'), field('target', choice($.integer_literal, $.identifier))),

    exit_statement: ($) =>
      seq(
        kw('Exit'),
        choice(kw('Sub'), kw('Function'), kw('Property'), kw('For'), kw('Do')),
      ),

    return_statement: ($) => kw('Return'),

    redim_statement: ($) =>
      seq(
        kw('ReDim'),
        optional(field('preserve', $.preserve)),
        commaSep1($.variable_declarator),
      ),

    preserve: (_) => kw('Preserve'),

    set_statement: ($) =>
      seq(
        kw('Set'),
        field('target', choice($._expression, $.leading_dot_member_access)),
        '=',
        optional(kw('New')),
        field('value', $._expression),
      ),

    let_statement: ($) =>
      seq(kw('Let'), field('target', $._expression), '=', field('value', $._expression)),

    assignment: ($) =>
      prec.right(
        100,
        seq(
          field('target', choice($._expression, $.leading_dot_member_access)),
          '=',
          field('value', $._expression),
        ),
      ),

    call_statement: ($) =>
      seq(
        kw('Call'),
        field('call', $._expression),
      ),

    label: ($) => prec(1, seq(field('name', $.identifier), ':')),

    // ─── Expressions ──────────────────────────────────────────────────

    _expression: ($) =>
      choice(
        $.binary_expression,
        $.unary_expression,
        $.new_expression,
        $.addressof_expression,
        $._primary_expression,
      ),

    _primary_expression: ($) =>
      choice(
        $.parenthesized_expression,
        $.call_expression,
        $.member_access,
        $.literal,
        $.identifier,
        $.me_expression,
      ),

    me_expression: (_) => kw('Me'),

    parenthesized_expression: ($) => seq('(', $._expression, ')'),

    new_expression: ($) => prec.right(PREC.unary, seq(kw('New'), $._type_name)),

    addressof_expression: ($) =>
      prec.right(PREC.unary, seq(kw('AddressOf'), field('target', $._expression))),

    call_expression: ($) =>
      prec.left(
        PREC.call,
        seq(
          field('function', $._primary_expression),
          token.immediate('('),
          optional(field('arguments', $.argument_list)),
          ')',
        ),
      ),

    argument_list: ($) => namedOrPositional($.identifier, $._expression),

    member_access: ($) =>
      prec.left(
        PREC.member,
        seq(
          field('object', $._primary_expression),
          '.',
          field('property', $.identifier),
        ),
      ),

    leading_dot_member_access: ($) =>
      prec(PREC.member, seq('.', field('property', $.identifier))),

    qualified_name: ($) =>
      prec.left(
        PREC.member,
        seq(
          field('library', $.identifier),
          repeat1(seq('.', field('name', $.identifier))),
        ),
      ),

    unary_expression: ($) =>
      prec.right(
        PREC.unary,
        seq(field('operator', choice('-', '+', kw('Not'))), field('operand', $._expression)),
      ),

    binary_expression: ($) => {
      const table = [
        ['^', PREC.power, 'right'],
        ['*', PREC.mul, 'left'],
        ['/', PREC.mul, 'left'],
        ['\\', PREC.int_div, 'left'],
        [kw('Mod'), PREC.mod, 'left'],
        ['+', PREC.add, 'left'],
        ['-', PREC.add, 'left'],
        ['&', PREC.concat, 'left'],
        [kw('Like'), PREC.compare, 'left'],
        [kw('Is'), PREC.compare, 'left'],
        ['=', PREC.compare, 'left'],
        ['<>', PREC.compare, 'left'],
        ['<', PREC.compare, 'left'],
        ['>', PREC.compare, 'left'],
        ['<=', PREC.compare, 'left'],
        ['>=', PREC.compare, 'left'],
        [kw('And'), PREC.and, 'left'],
        [kw('Or'), PREC.or, 'left'],
        [kw('Xor'), PREC.xor, 'left'],
        [kw('Eqv'), PREC.eqv, 'left'],
        [kw('Imp'), PREC.imp, 'left'],
      ];
      return choice(
        ...table.map(([op, p, assoc]) => {
          const rule = seq(
            field('left', $._expression),
            field('operator', op),
            field('right', $._expression),
          );
          return assoc === 'right' ? prec.right(p, rule) : prec.left(p, rule);
        }),
      );
    },

    // ─── Literals ─────────────────────────────────────────────────────

    literal: ($) =>
      choice(
        $.integer_literal,
        $.float_literal,
        $.hex_literal,
        $.octal_literal,
        $.string_literal,
        $.date_literal,
        $.boolean_literal,
        $.nothing_literal,
        $.null_literal,
        $.empty_literal,
      ),

    integer_literal: (_) => token(/[0-9]+[%&^]?/),

    float_literal: (_) =>
      token(choice(/[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?[!#@]?/, /[0-9]+[eE][+-]?[0-9]+[!#@]?/)),

    hex_literal: (_) => token(/&[hH][0-9a-fA-F]+[%&^]?/),

    octal_literal: (_) => token(/&[oO]?[0-7]+[%&^]?/),

    string_literal: (_) => token(seq('"', repeat(choice(/[^"\r\n]/, '""')), '"')),

    date_literal: (_) => token(seq('#', /[^#\r\n]+/, '#')),

    boolean_literal: (_) => choice(kw('True'), kw('False')),

    nothing_literal: (_) => kw('Nothing'),
    null_literal: (_) => kw('Null'),
    empty_literal: (_) => kw('Empty'),

    // ─── Lexical ──────────────────────────────────────────────────────

    identifier: (_) => /[A-Za-z_][A-Za-z0-9_]*/,

    comment: (_) =>
      token(
        choice(
          seq("'", /[^\r\n]*/),
          seq(/[rR][eE][mM]/, /[ \t][^\r\n]*/),
        ),
      ),

    _terminator: ($) => repeat1($._nl),

    _nl: (_) => choice(/\r?\n/, ':'),

    _line_continuation: (_) => token(/ _\r?\n/),
  },
});

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

function namedOrPositional(id, expr) {
  return commaSep1(
    choice(
      seq(field('name', id), ':=', field('value', expr)),
      expr,
    ),
  );
}
