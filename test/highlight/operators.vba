Sub Ops()
'^ @keyword
'   ^ @function
    Dim x As Long
'^ @keyword
'            ^ @type.builtin
    x = 1 + 2 * 3
'     ^ @operator
'       ^ @number
'         ^ @operator
    Dim f As Double
'^ @keyword
'            ^ @type.builtin
    f = 3.14
'     ^ @operator
'       ^ @number.float
    If x > 0 And Not (x Mod 2 = 0) Then
'^ @keyword
'            ^ @keyword.operator
'                ^ @keyword.operator
'                       ^ @keyword.operator
        Dim b As Boolean
'^ @keyword
'                ^ @type.builtin
        b = True
'^ @variable
'         ^ @operator
'           ^ @constant.builtin
    End If
'^ @keyword
End Sub
'^ @keyword
