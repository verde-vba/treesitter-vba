Sub TestFlow()
' <- @keyword
    If x > 0 Then
'   ^ @keyword
    ElseIf x < 0 Then
'   ^ @keyword
    Else
'   ^ @keyword
    End If
'   ^ @keyword
'       ^ @keyword
    For i = 1 To 10
'   ^ @keyword
'             ^ @keyword
    Next i
'   ^ @keyword
    Do While x > 0
'      ^ @keyword
    Loop
'   ^ @keyword
    Select Case x
'   ^ @keyword
'          ^ @keyword
    Case 1
    End Select
End Sub
' <- @keyword
'   ^ @keyword
