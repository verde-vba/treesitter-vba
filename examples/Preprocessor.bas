Attribute VB_Name = "Preprocessor"
Option Explicit

' Compile-time constants shared across the module.
#Const DEBUG_MODE = 1
#Const VBA7_COMPAT = 1

' Module-level conditional declaration:
' pick a pointer-sized integer type based on host VBA version and bitness.
#If Win64 Then
    Public Const PLATFORM_LABEL As String = "Win64"
    Dim gHandle As LongPtr
#ElseIf VBA7 Then
    Public Const PLATFORM_LABEL As String = "Win32-VBA7"
    Dim gHandle As LongPtr
#Else
    Public Const PLATFORM_LABEL As String = "Legacy"
    Dim gHandle As Long
#End If

Public Sub Run()
    Dim total As Long
    total = 0

    ' Inside a Sub: toggle verbose logging at compile time.
    #If DEBUG_MODE Then
        Debug.Print "Run: entering with PLATFORM_LABEL=" & PLATFORM_LABEL
    #End If

    total = Compute(10)

    #If DEBUG_MODE Then
        Debug.Print "Run: total=" & total
    #Else
        ' no-op in release build
    #End If
End Sub

Public Function Compute(ByVal n As Long) As Long
    Dim i As Long
    Dim acc As Long
    acc = 0
    For i = 1 To n
        acc = acc + i
    Next i

    ' Branch on VBA version to pick the widest safe accumulator type.
    #If VBA7_COMPAT Then
        Compute = acc
    #Else
        Compute = CLng(acc)
    #End If
End Function
