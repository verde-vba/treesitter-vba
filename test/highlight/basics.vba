' This is a comment
'^ @comment
Sub HelloWorld()
'^ @keyword
'   ^ @function
'              ^ @punctuation.delimiter
    Dim msg As String
'^ @keyword
'       ^ @variable
'           ^ @keyword
'              ^ @type.builtin
    msg = "Hello"
'^ @variable
'       ^ @operator
'         ^ @string
    Debug.Print msg
'^ @variable
'        ^ @punctuation.delimiter
End Sub
'^ @keyword
'   ^ @keyword
