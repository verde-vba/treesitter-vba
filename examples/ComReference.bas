Attribute VB_Name = "ComReference"
Option Explicit

' This module demonstrates library-qualified COM types.
' References required (Tools > References):
'   - Microsoft Excel Object Library
'   - Microsoft Scripting Runtime
'   - Microsoft ActiveX Data Objects Library

Public Sub UseExcel()
    ' Dim with library-qualified types.
    Dim app As Excel.Application
    Dim wb As Excel.Workbook
    Dim dict As Scripting.Dictionary
    Dim coll As VBA.Collection

    ' Set with New on a qualified type.
    Set app = New Excel.Application
    Set dict = New Scripting.Dictionary
    Set coll = New VBA.Collection

    app.Visible = True
    Set wb = app.Workbooks.Add

    dict.Add "first", 1
    dict.Add "second", 2

    coll.Add "alpha"
    coll.Add "beta"

    wb.Close SaveChanges:=False
    app.Quit

    Set wb = Nothing
    Set app = Nothing
    Set dict = Nothing
    Set coll = Nothing
End Sub

' Parameter and return types can also be library-qualified.
Public Function OpenConnection(ByVal cs As String) As ADODB.Connection
    Dim cn As ADODB.Connection
    Set cn = New ADODB.Connection
    cn.ConnectionString = cs
    cn.Open
    Set OpenConnection = cn
End Function

Public Sub LogDictionary(ByVal d As Scripting.Dictionary)
    Dim k As Variant
    For Each k In d.Keys
        Debug.Print k & "=" & d(k)
    Next k
End Sub
