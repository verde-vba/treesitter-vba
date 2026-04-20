Sub Foo()
    GoTo Done
'        ^ @label
    On Error GoTo ErrorHandler
'                  ^ @label
    On Error Resume Next
Done:
' <- @label
ErrorHandler:
' <- @label
End Sub
