Sub TestWith()
' <- @keyword
    With myObj
'   ^ @keyword
'        ^ @variable
        .Name = "Hello"
'        ^ @variable
'                ^ @string
        .Count = 5
'        ^ @variable
'                ^ @number
        .Enabled = True
'        ^ @variable
'                   ^ @constant.builtin
    End With
'   ^ @keyword
'       ^ @keyword
End Sub
' <- @keyword
'   ^ @keyword
