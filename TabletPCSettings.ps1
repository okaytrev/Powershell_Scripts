# Check if "Tablet and PC Settings" control panel object is listed

# Try/Catch will catch exception in Powershell v2.0 - Windows 7
# Try/Catch/Finally will accomodate non-terminating error in Powershell v5.0 - Windows 10

try
{
    $result = Get-ControlPanelItem -Name "Tablet PC Settings"
}
catch
{
    # If the query causes an exception, it's assumed no results were found and this is Powershell v2.0
}
finally
{
    if ($result -eq $null)
    {
        # Register a duplicate control panel item for Tablet PC Settings
    
        # Variables
        $scriptpath = $MyInvocation.MyCommand.Path | Split-Path
        $OSVersion = [System.Environment]::OSVersion.Version
        $arch = If (Test-Path "C:\Program Files (x86)") { "x64" } Else { "x86" }

        # Check for tested OS
        if ($OSVersion.Major -eq 10 -and $OSVersion.Minor -eq 0) { <# do nothing #> } # Ok to proceed
        else { exit } # Exit if it is not a tested OS

        $path = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}"
        $path2 = "HKLM:SOFTWARE\Classes\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}"

        #Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /ve /t REG_SZ /d "Tablet PC Settings 2" /f
        New-Item -Path $path -Value “Tablet PC Settings 2” -Type String –Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /ve /t REG_SZ /d "Tablet PC Settings Control Panel" /f
        New-Item -Path $path2 -Value "Tablet PC Settings Control Panel" -Type String –Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "InfoTip" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\System32\tabletpc.cpl,-10102" /f
        New-ItemProperty -Path $path2 -Name "InfoTip" -Type ExpandString -Value "@%SystemRoot%\System32\tabletpc.cpl,-10102" -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "LocalizedString" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\System32\tabletpc.cpl,-10100" /f
        New-ItemProperty -Path $path2 -Name "LocalizedString" -Type ExpandString -Value "@%SystemRoot%\System32\tabletpc.cpl,-10100" -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "System.ApplicationName" /t REG_SZ /d "Microsoft.TabletPCSettings" /f
        New-ItemProperty -Path $path2 -Name "System.ApplicationName" -PropertyType String -Value "Microsoft.TabletPCSettings" -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "System.ControlPanel.Category" /t REG_SZ /d "2,11" /f
        New-ItemProperty -Path $path2 -Name "System.ControlPanel.Category" -PropertyType String -Value "2,11" -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "System.ControlPanel.EnableInSafeMode" /t REG_DWORD /d "3" /f
        New-ItemProperty -Path $path2 -Name "System.ControlPanel.EnableInSafeMode" -PropertyType DWord -Value 3 -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}" /v "System.Software.TasksFileUrl" /t REG_SZ /d "Internal" /f
        New-ItemProperty -Path $path2 -Name "System.Software.TasksFileUrl" -PropertyType String -Value "Internal" -Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\tabletpc.cpl,-10200" /f
        New-Item -Path ($path2 + "\DefaultIcon") -Value "%SystemRoot%\System32\tabletpc.cpl,-10200" -Type ExpandString –Force

        #Reg.exe add "HKCR\CLSID\{EF080A13-FF4A-4A1A-949F-69F976A64E8A}\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe %%SystemRoot%%\System32\shell32.dll,Control_RunDLL %%SystemRoot%%\System32\tabletpc.cpl @1" /f
        New-Item -Path ($path2 + "\Shell") –Force
        New-Item -Path ($path2 + "\Shell\Open") –Force
        New-Item -Path ($path2 + "\Shell\Open\Command") -Value "%SystemRoot%\System32\rundll32.exe %SystemRoot%\System32\shell32.dll,Control_RunDLL %SystemRoot%\System32\tabletpc.cpl @1" -Type ExpandString –Force
    }
}

<# Powershell propertytypes for registry keys
String. Specifies a null-terminated string. Equivalent to REG_SZ.
ExpandString. Specifies a null-terminated string that contains unexpanded references to environment variables that are expanded when the value is retrieved. Equivalent to REG_EXPAND_SZ.
Binary. Specifies binary data in any form. Equivalent to REG_BINARY.
DWord. Specifies a 32-bit binary number. Equivalent to REG_DWORD.
MultiString. Specifies an array of null-terminated strings terminated by two null characters. Equivalent to REG_MULTI_SZ.
Qword. Specifies a 64-bit binary number. Equivalent to REG_QWORD.
Unknown. Indicates an unsupported registry data type, such as REG_RESOURCE_LIST.
#>