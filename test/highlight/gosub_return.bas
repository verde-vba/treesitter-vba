Sub Main()
' <- @keyword
    GoSub CleanUp
'   ^ @keyword
'         ^ @variable
    Exit Sub
CleanUp:
' <- @variable
'      ^ @punctuation.delimiter
    Return
'   ^ @keyword
End Sub
' <- @keyword
