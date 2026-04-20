Sub Main()
' <- @keyword
    GoSub CleanUp
'   ^ @keyword
'         ^ @label
    Exit Sub
CleanUp:
' <- @label
'      ^ @punctuation.delimiter
    Return
'   ^ @keyword
End Sub
' <- @keyword
