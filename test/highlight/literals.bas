Const X = 1
' <- @keyword
'         ^ @number
Sub TestLiterals()
' <- @keyword
    s = "hello"
'       ^ @string
    i = 42
'       ^ @number
    f = 2.5
'       ^ @number.float
    b = True
'       ^ @constant.builtin
    b = False
'       ^ @constant.builtin
    v = Nothing
'       ^ @constant.builtin
    v = Null
'       ^ @constant.builtin
    v = Empty
'       ^ @constant.builtin
    h = &HFF
'       ^ @number
    o = &O77
'       ^ @number
    d = #2023-12-31#
'       ^ @string.special
End Sub
' <- @keyword
'   ^ @keyword
