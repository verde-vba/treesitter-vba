Attribute VB_Name = "Sample"
Option Explicit

Public Const MAX_ITEMS As Long = 100

Public Type Point
    X As Double
    Y As Double
End Type

Public Enum Color
    Red = 1
    Green
    Blue
End Enum

Public Function Distance(ByVal a As Point, ByVal b As Point) As Double
    Dim dx As Double, dy As Double
    dx = a.X - b.X
    dy = a.Y - b.Y
    Distance = Sqr(dx * dx + dy * dy)
End Function

Public Sub Main()
    Dim i As Long
    On Error GoTo Fail
    For i = 1 To MAX_ITEMS
        If i Mod 15 = 0 Then
            Debug.Print "FizzBuzz"
        ElseIf i Mod 3 = 0 Then
            Debug.Print "Fizz"
        ElseIf i Mod 5 = 0 Then
            Debug.Print "Buzz"
        Else
            Debug.Print i
        End If
    Next i
    Exit Sub
Fail:
    Debug.Print "error: " & Err.Description
End Sub
