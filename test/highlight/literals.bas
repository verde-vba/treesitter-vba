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
End Sub
' <- @keyword
'   ^ @keyword
