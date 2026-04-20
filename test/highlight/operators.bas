Sub TestOps()
' <- @keyword
    Dim x As Long
'   ^ @keyword
    x = 10 - 3
'          ^ @operator
    x = 10 / 5
'          ^ @operator
    x = 10 \ 3
'          ^ @operator
    x = 2 ^ 3
'         ^ @operator
    Dim b As Boolean
    b = x <> 0
'         ^ @operator
    b = x < 10
'         ^ @operator
    b = x >= 5
'         ^ @operator
    b = x <= 5
'         ^ @operator
    x = x Or 1
'         ^ @keyword.operator
    x = x Xor 2
'         ^ @keyword.operator
End Sub
' <- @keyword
'   ^ @keyword
