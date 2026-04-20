Sub TestWith()
' <- @keyword
    With myObj
'   ^ @keyword
'        ^ @variable
        .Name = "Hello"
'        ^ @property
'                ^ @string
        .Count = 5
'        ^ @property
'                ^ @number
        .Enabled = True
'        ^ @property
'                   ^ @constant.builtin
    End With
'   ^ @keyword
'       ^ @keyword
End Sub
' <- @keyword
'   ^ @keyword
