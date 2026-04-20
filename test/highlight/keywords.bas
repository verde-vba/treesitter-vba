Sub Greet()
' <- @keyword
'    ^ @variable
    Dim x As Integer
'   ^ @keyword
'       ^ @variable
'         ^ @keyword
'            ^ @type.builtin
End Sub
' <- @keyword
'   ^ @keyword
Function Calc() As Long
' <- @keyword
'         ^ @variable
'               ^ @keyword
'                  ^ @type.builtin
End Function
' <- @keyword
'   ^ @keyword
