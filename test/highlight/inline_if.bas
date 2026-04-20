Sub InlineIf()
' <- @keyword
    If x > 0 Then x = 1
'   ^ @keyword
'            ^ @keyword
    If x > 0 Then x = 1 Else x = 2
'   ^ @keyword
'            ^ @keyword
'                        ^ @keyword
End Sub
' <- @keyword
'   ^ @keyword
