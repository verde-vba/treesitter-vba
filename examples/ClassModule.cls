Attribute VB_Name = "Shape"
Option Explicit

Private mName As String
Private mArea As Double

Public Property Get Name() As String
    Name = mName
End Property

Public Property Let Name(ByVal value As String)
    mName = value
End Property

Public Property Get Area() As Double
    Area = mArea
End Property

Public Sub Init(ByVal newName As String, ByVal newArea As Double)
    mName = newName
    mArea = newArea
End Sub

Public Function Describe() As String
    Describe = Me.Name & " (" & Me.Area & ")"
End Function
