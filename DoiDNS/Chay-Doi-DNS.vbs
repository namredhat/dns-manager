Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
currentDir = fso.GetParentFolderName(WScript.ScriptFullName)

Dim rc
rc = WshShell.Run("schtasks /query /tn ""DNSManagerPro_Elevated""", 0, True)
If rc = 0 Then
    WshShell.Run "schtasks /run /tn ""DNSManagerPro_Elevated""", 0, False
Else
    WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & currentDir & "\Doi-DNS.ps1""", 0, False
End If
