Type MyPoint
' <- @keyword
'    ^ @type
    X As Long
'   ^ @property
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
'   ^ @constant
'           ^ @number
End Enum
' <- @keyword
'   ^ @keyword

Sub UseCustomTypes()
    Dim p As MyPoint
'            ^ @variable
End Sub
