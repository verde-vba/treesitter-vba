Type MyPoint
' <- @keyword
'    ^ @variable
    X As Long
'   ^ @variable
'     ^ @keyword
'        ^ @type.builtin
    Y As String
'        ^ @type.builtin
End Type
' <- @keyword
'   ^ @keyword

Enum Direction
' <- @keyword
    North = 1
'   ^ @variable
'           ^ @number
End Enum
' <- @keyword
'   ^ @keyword

Sub UseCustomTypes()
    Dim p As MyPoint
'            ^ @variable
End Sub
