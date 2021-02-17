#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Progress, 40, Disabling Mirror Driver, Disabling Mirror Driver, LMI Mirror Install Progres
FileInstall, C:\Users\trevar.hupf\Documents\Projects\LMI_Mirror_Driver\DisableMirrorDriver.ps1, %A_WorkingDir%\DisableMirrorDriver.ps1, 1

Progress, 80, Disabling Mirror Driver, Disabling Mirror Driver, LMI Mirror Install Progres
RunWait, cmd.exe /c "PowerShell.exe -executionpolicy remotesigned -File DisableMirrorDriver.ps1" , %A_WorkingDir%, Hide

FileDelete, %A_WorkingDir%\DisableMirrorDriver.ps1

Progress, Off

msgbox Restart required to complete 