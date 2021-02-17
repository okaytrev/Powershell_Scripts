Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


$FontPath = $PSScriptRoot + "\fonts.zip"

Unzip "$FontPath" "$PSScriptRoot"

$InstallFont = $PSScriptRoot +"\fonts" 

$FontReg = $PSScriptRoot + "\FontReg.exe"


Get-ChildItem $installFont | Copy-Item -Destination "C:\Windows\Fonts"

& $FontReg