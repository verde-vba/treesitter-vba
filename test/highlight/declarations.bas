Public x As Long
' <- @keyword
'           ^ @type.builtin

Private y As String
' <- @keyword
'            ^ @type.builtin

Const MAX_SIZE = 100
' <- @keyword
'     ^ @variable

Sub TestDecl()
' <- @keyword
    Dim a As Variant
'   ^ @keyword
'            ^ @type.builtin
    Static b As Boolean
'   ^ @keyword
'               ^ @type.builtin
    ReDim arr(10)
'   ^ @keyword
    Dim c As Long, d As Integer
'   ^ @keyword
End Sub
' <- @keyword
