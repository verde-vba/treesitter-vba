Sub TestErr()
' <- @keyword
    On Error GoTo ErrHandler
'   ^ @keyword
'      ^ @keyword
'             ^ @keyword
'                  ^ @variable
    Exit Sub
'   ^ @keyword
ErrHandler:
' <- @variable
'         ^ @punctuation.delimiter
    Resume Next
'   ^ @keyword
'          ^ @keyword
End Sub
' <- @keyword
'   ^ @keyword
