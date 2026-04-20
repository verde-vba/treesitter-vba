#Const DEBUG_MODE = 1
'^ @keyword.directive
'      ^ @variable
'                 ^ @operator
'                   ^ @number
#If VBA7 Then
'^ @keyword.directive
'   ^ @constant
'        ^ @keyword
#ElseIf Win64 Then
'^ @keyword.directive
'       ^ @constant
'             ^ @keyword
#Else
'^ @keyword.directive
#End If
'^ @keyword.directive
'    ^ @keyword
