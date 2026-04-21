Sub Foo()
    GoTo Done
'        ^ @label
    On Error GoTo ErrorHandler
'             ^ @keyword.exception
'                  ^ @label
    On Error Resume Next
Done:
' <- @label
ErrorHandler:
' <- @label
End Sub
