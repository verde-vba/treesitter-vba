Sub Greet()
' <- @keyword
'    ^ @function
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
'         ^ @function
'               ^ @keyword
'                  ^ @type.builtin
End Function
' <- @keyword
'   ^ @keyword
