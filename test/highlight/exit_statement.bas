Sub TestExit()
    Exit Sub
'   ^ @keyword
'        ^ @keyword.control.return
    Exit For
'   ^ @keyword
'        ^ @keyword.control.loop
    Exit Do
'   ^ @keyword
'        ^ @keyword.control.loop
End Sub

Function TestExitFn() As Integer
    Exit Function
'   ^ @keyword
'        ^ @keyword.control.return
    Exit Property
'   ^ @keyword
'        ^ @keyword.control.return
End Function
