#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
TargetDir := "C:\Users\Public\Documents\Four Winds Interactive\Plugins\"

Progress, 10, Unpacking Content Player, Unpacking, Fonts Install
FileInstall, C:\Users\trevar.hupf\Documents\ProgramTeam\FontsForJosh\FontReg.exe, %A_WorkingDir%\FontReg.exe, 1
Progress, 30, Unpacking Desaware Fic, Unpacking, Fonts Install
FileInstall, C:\Users\trevar.hupf\Documents\ProgramTeam\FontsForJosh\ExtractAndInstallFonts.ps1, %A_WorkingDir%\ExtractAndInstallFonts.ps1, 1
Progress, 60, Unpacking setup files, Unpacking, Fonts Install
FileInstall, C:\Users\trevar.hupf\Documents\ProgramTeam\FontsForJosh\Fonts.zip, %A_WorkingDir%\Fonts.zip, 1


Progress, 80, Installing GoBoard Fonts, Installing Fonts, GoBoard Install Progress
RunWait, cmd.exe /c "PowerShell.exe -executionpolicy remotesigned -File ExtractAndInstallFonts.ps1" , %A_WorkingDir%, Hide

Progress, Off

ExitApp
