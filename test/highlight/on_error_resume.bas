Sub Test()
    On Error Resume Next
'   ^ @keyword
'      ^ @keyword
'             ^ @keyword
'                    ^ @keyword.exception
    Resume Next
'   ^ @keyword
'          ^ @keyword.exception
    Resume ErrHandler
'   ^ @keyword
'          ^ @label
End Sub
