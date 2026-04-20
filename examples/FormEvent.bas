Attribute VB_Name = "FormEvent"
Option Explicit

Private Sub UserForm_Initialize()
    Me.Caption = "Hello"
    With Me.TextBox1
        .Text = ""
        .Enabled = True
    End With
End Sub

Private Sub CommandButton1_Click()
    If Me.TextBox1.Text = "" Then
        MsgBox "Please enter a value"
    Else
        MsgBox "Clicked: " & Me.TextBox1.Text
    End If
End Sub

Private Sub CommandButton2_Click()
    Unload Me
End Sub
