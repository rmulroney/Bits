Attribute VB_Name = "IsErrorSub"
'Instructions: Highlight Offending Cells and Execute


Public Sub IfErrorToIsError()
On Error GoTo getmeouttahere

' For each Cell selected loop through and remove the any IfError functions.


    Dim Start As Integer, comma As Integer, closeBracket As Integer, openBracket As Integer, bracketAt As Integer
    Dim booleanTest As String, result As String, currentFormula As String
    Dim flag As Integer
    
    For Each cl In Selection.Cells
    

        Do While InStr(LCase(cl.Formula), "iferror(") > 0
        
            
            result = ""
            currentFormula = cl.Formula
            bracketAt = 0
            flag = False
            
            Start = InStr(LCase(cl.Formula), "iferror(")
            bracketAt = Start + 8
            openBracket = Start + 9
            comma = InStr(bracketAt + 1, LCase(cl.Formula), ",")
            
            Do
                closeBracket = InStr(closeBracket + 1, cl.Formula, ")")
                openBracket = InStr(openBracket + 1, cl.Formula, "(")
                
                If openBracket <> 0 Then
                    comma = InStr(closeBracket + 1, LCase(cl.Formula), ",")
                End If
        
            Loop While (openBracket <> 0)
            
            'Debug.Print "Start: " & Start & " comma: " & comma & " bracketAt: " & bracketAt & " closeBracket: " & closeBracket & " openBracket: " & openBracket
            
            If Start > 0 And comma > 0 And closeBracket > 0 Then
            
                'Trim out the first param of the IFERROR, the test calc
                booleanTest = Mid(cl.Formula, Start + 8, comma - Start - 8) ' len("IFERROR(") = 8
                
                result = Left(cl.Formula, Start - 1)                            ' everything before the IFERROR(
                result = result + "if(iserror("                                 ' start  the if(iserror(
                result = result + booleanTest                                   ' iserror() param
                result = result + ")"                                           ' Close is error function
                result = result + Mid(cl.Formula, comma, closeBracket - comma)  ' IF() first Param -- error
                result = result + "," + booleanTest + ")"                       ' IF() last Param -- not error
                
                cl.Formula = result
                
                Debug.Print "Source Formula: " & cl.Formula
                Debug.Print "Result: " & result

            End If
            
        Loop
        
    Next cl
    
    Exit Sub
    
getmeouttahere:
    Debug.Print (Err)
    result = currentFormula
    Resume Next

End Sub

