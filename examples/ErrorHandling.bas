Attribute VB_Name = "ErrorHandling"
Option Explicit

Public Sub DoWork()
    Dim i As Long
    Dim total As Double
    On Error GoTo ErrHandler
    total = 0
    For i = 1 To 10
        total = total + (100 / i)
    Next i
    Debug.Print "Total: " & total
    Exit Sub
ErrHandler:
    MsgBox "Error: " & Err.Description
    Resume Next
End Sub

Public Sub Retry()
    On Error Resume Next
    Dim x As Long
    x = 1 / 0
    If Err.Number <> 0 Then
        Debug.Print "Caught: " & Err.Number
    End If
End Sub
