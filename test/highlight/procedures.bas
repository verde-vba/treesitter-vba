Public Sub Pub()
' <- @keyword
'       ^ @keyword
End Sub
' <- @keyword
Private Sub Priv()
' <- @keyword
'        ^ @keyword
End Sub
Friend Sub Fri()
' <- @keyword
End Sub
Function F(ByVal x As Long) As Long
'          ^ @keyword
'                   ^ @keyword
'                            ^ @keyword
End Function
' <- @keyword
'   ^ @keyword
Sub G(ByRef y As String)
'     ^ @keyword
End Sub
Sub H(Optional z As Integer)
'     ^ @keyword
End Sub
' <- @keyword
