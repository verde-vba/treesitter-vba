Sub TestGoSub()
' <- @keyword
    GoSub CleanUp
'   ^ @keyword
    Exit Sub
'   ^ @keyword
'        ^ @keyword.control.return
    Return
'   ^ @keyword
End Sub
' <- @keyword
'   ^ @keyword
