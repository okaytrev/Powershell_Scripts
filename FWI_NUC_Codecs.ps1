function enable-privilege {
 param(
  ## The privilege to adjust. This set is taken from
  ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
  [ValidateSet(
   "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
   "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
   "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
   "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
   "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
   "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
   "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
   "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
   "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
   "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
   "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
  $Privilege,
  ## The process on which to adjust the privilege. Defaults to the current process.
  $ProcessId = $pid,
  ## Switch to disable the privilege, rather than enable it.
  [Switch] $Disable
 )

 ## Taken from P/Invoke.NET with minor adjustments.
 $definition = @'
 using System;
 using System.Runtime.InteropServices;
  
 public class AdjPriv
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
   ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
  {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable)
   {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@

 $processHandle = (Get-Process -id $ProcessId).Handle
 $type = Add-Type $definition -PassThru
 $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

function ChangePermission {
    Param([string]$key)
    
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($key,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::takeownership)

    echo $key | get-member -MemberType Properties
    # You must get a blank acl for the key b/c you do not currently have access
    $acl = $regKey.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
    $owner = [System.Security.Principal.NTAccount]"Administrators"
    $acl.SetOwner($owner)
    $regKey.SetAccessControl($acl)

    # After you have set owner you need to get the acl with the permissions so you can modify it.
    $acl = $regKey.GetAccessControl()
    $person = [System.Security.Principal.NTAccount]"Administrators"
    $access = [System.Security.AccessControl.RegistryRights]"FullControl"
    $inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit"
    $propagation = [System.Security.AccessControl.PropagationFlags]"None"
    $type = [System.Security.AccessControl.AccessControlType]"Allow"

    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person,$access,$inheritance,$propagation,$type)
    $acl.SetAccessRule($rule)
    $regKey.SetAccessControl($acl)
    $regKey.Close()
}

# Exit this script if the video controller is not Intel
$query = "select pnpdeviceid from Win32_VideoController"
$match = "pci\\ven_8086" # Intel vender ID including regex escape '\' character
if((Get-WmiObject -query $query).pnpdeviceid -match $match){
echo "Intel video found. Continuing"
} else {
echo "No Intel video. Exiting"
exit
}

# Changing ownership of registry keys.
ChangePermission -key "Software\Microsoft\DirectShow\Preferred"

# If running 64 bit OS...
ChangePermission -key "SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred"

echo "Administrators Group ownership privileges set."

# Begin registry modifications of newly available keys
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{000000FF-0000-0010-8000-00aa00389b71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{00000050-0000-0010-8000-00AA00389B71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{00000055-0000-0010-8000-00AA00389B71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{00001602-0000-0010-8000-00aa00389b71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{31435641-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{31435648-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{31435657-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{31564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{32564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{33564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{34363248-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{34363268-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{41564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{44495658-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{47504A4D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{5334504D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{5634504D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{58564944-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{64697678-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{64737664-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{7334706D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{7634706D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{78766964-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{e06d8026-db46-11cf-b4d1-00805f6cbbea}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{e06d802b-db46-11cf-b4d1-00805f6cbbea}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{e436eb80-524f-11ce-9f53-0020af0ba770}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectShow\Preferred" -Name "{e436eb81-524f-11ce-9f53-0020af0ba770}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
if(Test-Path "HKLM:\SOFTWARE\Wow6432Node"){
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{000000FF-0000-0010-8000-00aa00389b71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{00000050-0000-0010-8000-00AA00389B71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{00000055-0000-0010-8000-00AA00389B71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{00001602-0000-0010-8000-00aa00389b71}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{31435641-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{31435648-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{31435657-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    #Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{31564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    #Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{32564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    #Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{33564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{34363248-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{34363268-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{41564D57-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{44495658-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{47504A4D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{5334504D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{5634504D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{58564944-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{64697678-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{64737664-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{7334706D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{7634706D-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{78766964-0000-0010-8000-00AA00389B71}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{e06d8026-db46-11cf-b4d1-00805f6cbbea}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{e06d802b-db46-11cf-b4d1-00805f6cbbea}" -Value "{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{e436eb80-524f-11ce-9f53-0020af0ba770}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\DirectShow\Preferred" -Name "{e436eb81-524f-11ce-9f53-0020af0ba770}" -Value "{EE30215D-164F-4A92-A4EB-9D4C13390F9F}" -Force
}
# HKLM registry mods w/o ownership issues
New-Item -Path "HKLM:\Software" -Name "LAV" -Force
New-Item -Path "HKLM:\Software\LAV" -Name "Video" -Force
New-Item -Path "HKLM:\Software\LAV\Video" -Name "Formats" -Force
New-Item -Path "HKLM:\Software\LAV\Video\Formats" -Name "h264" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\LAV\Video\Formats" -Name "h264" -Value 1 -Type Dword -Force
if(Test-Path "HKLM:\SOFTWARE\Wow6432Node"){
    New-Item -Path "HKLM:\Software\Wow6432Node" -Name "LAV" -Force
    New-Item -Path "HKLM:\Software\Wow6432Node\LAV" -Name "Video" -Force
    New-Item -Path "HKLM:\Software\Wow6432Node\LAV\Video" -Name "Formats" -Force
    New-Item -Path "HKLM:\Software\Wow6432Node\LAV\Video\Formats" -Name "h264" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\LAV\Video\Formats" -Name "h264" -Value 1 -Type Dword -Force
}

# HKCU registry mods
Push-Location
Set-Location HKCU:
New-Item -Path ".\Software" -Name "LAV" -Force
New-Item -Path ".\Software\LAV" -Name "Video" -Force
New-Item -Path ".\Software\LAV\Video" -Name "Formats" -Force
New-Item -Path ".\Software\LAV\Video" -Name "HWAccel" -Force
New-Item -Path ".\Software\LAV\Video" -Name "Output" -Force
New-Item -Path ".\Software\LAV\Video\Formats" -Name "h264" -Force

Set-ItemProperty -Path ".\Software\LAV\Video" -Name "DeintFieldOrder" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "DeintMode" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "DitherMode" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "DVDVideo" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "MSWMV9DMO" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "NumThreads" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "ResetSettings" -Value 2170154807 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "RGBRange" -Value 2 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "StreamAR" -Value 2 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "SWDeintMode" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "SWDeintOutput" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video" -Name "TrayIcon" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "8bps" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "bink" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "camstudio" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "camtasia" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "cinepak" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "dirac" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "dnxhd" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "dvvideo" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "ffv1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "flash" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "flic" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "fraps" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "g2m" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "h261" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "h263" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "h263i" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "h264" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "hevc" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "huffyuv" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "icod" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "indeo3" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "indeo4" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "indeo5" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "jpeg2000" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "lagarith" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "loco" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "mjpeg" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "mpeg1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "mpeg2" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "mpeg4" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "msmpeg4" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "msrle" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "msvideo1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "png" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "prores" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "qpeg" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "qtrle" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "rpza" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "rv12" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "rv34" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "smackvid" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "snow" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "svq" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "theora" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "thp" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "truemotion" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "utvideo" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "v210/v410" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vc1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vcr1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vmnc" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vp6" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vp7" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vp8" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "vp9" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "wmv12" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "wmv3" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "zlib" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Formats" -Name "zmbv" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "dvd" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "h264" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "hevc" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "HWAccel" -Value 2 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "HWDeintHQ" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "HWDeintMode" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "HWDeintOutput" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "HWResFlags" -Value 7 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "mpeg2" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "mpeg4" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\HWAccel" -Name "vc1" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "ayuv" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "nv12" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "p010" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "p016" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "p210" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "p216" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "rgb24" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "rgb32" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "rgb48" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "uyvy" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "v210" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "v410" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "y416" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "yuy2" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "yv12" -Value 1 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "yv16" -Value 0 -Type Dword -Force
Set-ItemProperty -Path ".\Software\LAV\Video\Output" -Name "yv24" -Value 1 -Type Dword -Force

Remove-ItemProperty -Path ".\Software\LAV\Video" -Name "DeintFieldOrder" -Force
Remove-ItemProperty -Path ".\Software\LAV\Video" -Name "DeintForce" -Force
Remove-ItemProperty -Path ".\Software\LAV\Video" -Name "DeintTreatAsProgressive" -Force

Pop-Location

echo "Registry changes completed."