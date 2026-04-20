' single-quote comment
' <- @comment

Rem Rem comment
' <- @comment

Sub TestComments()
' <- @keyword
    ' indented comment
'   ^ @comment
    Rem Rem inside sub
'   ^ @comment
    x = 1 ' inline after code
'         ^ @comment
    Dim s As String ' trailing type comment
'                   ^ @comment
End Sub
' <- @keyword

' first block comment
' <- @comment
' second block comment
' <- @comment
' third block comment
' <- @comment
