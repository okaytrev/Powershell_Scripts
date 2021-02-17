<######################################################################
Created by:
    Charles Wenger - charles.wenger@fourwindsinteractive.com
    Rob Heck - robert.heck@fourwindsinteractive.com
 

Description:
    This script has been developed to allow RS232 control of LG displays. 
    It will scan, log, and take corrective action if a display is off,
    not on the DVI input, or not on the correct picture setting. This code uses specific 
    LG RS-232 commands and will not work on any other variations of displays. 

Completed on: 7/7/16
Revision to add date/time constraints: 10/6/17 - Robert Heck

########################################################################>


#Global Variable
    $ScreenStatus = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Logs\ScreenStatus.txt”
    $ScreenHistory = "C:\Users\Public\Documents\Four Winds Interactive\Signage\Logs\ScreenHistory.txt”
    $time = Get-Date

workflow Get-IsWorkHours
{
    param (
        [int] $MyWeekDayStartHour = 07,
                        
        [int] $MyWeekDayEndHour = 01
    )
    
    # Convert the date to be in the local time zone
    # See http://msdn.microsoft.com/en-us/library/system.timezoneinfo.findsystemtimezonebyid(v=vs.110).aspx
    # for more information
    function ConvertDatetime {
        param(
            [DateTime]$DateTime,
            [String] $ToTimeZone
        )
    
        $oToTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($ToTimeZone)
        $UtcDateTime = $DateTime.ToUniversalTime()
        $ConvertedTime = [System.TimeZoneInfo]::ConvertTime($UtcDateTime, $oToTimeZone)
    
        return $ConvertedTime
    }
    
    #Set the dates 
    $Now = Get-Date 
    $Now = ConvertDatetime -Datetime $Now -ToTimeZone 'Eastern Standard Time'
    $TodayStart = Get-Date -Hour $MyWeekDayStartHour -Minute 00 -Day $Now.Day -Month $Now.Month
    $TodayEnd = Get-Date -Hour $MyWeekDayEndHour -Minute 01 -Day $Now.Day -Month $Now.Month

    # Check if the time is currently within work hours
    if ($Now -lt $TodayStart -or $Now -gt $TodayEnd) {
        Write-Verbose -Message "It is currently outside of work hours. Time: $Now" -Verbose
        return $false
    }   
    
    # Check if today is a weekend
    $Day = InlineScript {
     $using:Now.DayOfWeek
    }
        
    #Day 0 = Sunday, 1 = Monday, etc. 
    #See http://technet.microsoft.com/en-us/library/ff730960.aspx
    if ($Day -eq 0) {
        Write-Verbose -Message "It is a weekend: Today is the $Day of the week." -Verbose
        return $false

    }
     
    #Return true if none of the above hits
    return $true
}

$x = Get-IsWorkHours

if ($x -eq 'TRUE')
{
#set the number of screens here
    $screens = 9

#Clear ScreenStatus file for FWIRMM monitoring
    write-output "$time" | out-file "$ScreenStatus"

#COM Port Communication
    #get list of COM ports
    $COMport = [System.IO.Ports.SerialPort]::getportnames()

    #list status of COM ports
    $mode = mode $COMport

    #here we would have a statement that gets the results of the ?getportnames()? query and uses it to build the ?new-Object? command below
    $port= new-Object System.IO.Ports.SerialPort $COMport,9600,None,8,one
    
#######################
function checkPower
{
    #write-output $status1
    
    #Power Status
    if($status1 -ne "a 0"+$i+" OK01x")
        {  
            $output += "Screen $i is Off or in power save mode"
            Write-Output "$output"  | out-file -append -FilePath $ScreenStatus #-Force   
        }              
}


function checkInput
{
    #write-output $status3
    
    #Input Selected                                  
    if($status3 -ne "b 0"+$i+" OK70x")
        {
            #Input Select 
            $output += "Screen $i input not DVI"
            Write-Output "$output"  | out-file -append -FilePath $ScreenStatus #-Force     
        }
        
}

function checkPictureMode
{
    #write-output $status4
    
    if($status4 -ne "x 0"+$i+" OK01x")
        {
            #Picture Mode 
            $output += "Screen $i picture mode not Standard"
            Write-Output "$output"  | out-file -append -FilePath $ScreenStatus #-Force    
        }
                   
}

#######################

#Open COM Port, check statuses, and close COM port
for ($i = 1; $i -le $screens; $i++){

        $port.open()

            $port.WriteLine("ka 00"+$i+" ff")	#check power status
            start-sleep -m 1000
            $status1 = $port.ReadExisting()
            
            $port.WriteLine("xb 00"+$i+" ff")	#check input
            start-sleep -m 1000
            $status3 = $port.ReadExisting()

            $port.WriteLine("dx 00"+$i+" ff")	#check picture mode
            start-sleep -m 1000
            $status4 = $port.ReadExisting()
            
        $port.Close()

    #Functions to check status of screens
    checkPower
    
    checkInput
   
    checkPictureMode
  

    #Append status to text file - historical logging
    write-output "----------------------------------" | out-file -append "$ScreenHistory"
    write-output "$time" | out-file -append "$ScreenHistory"
    write-output "Power Status - $status1" | out-file -append "$ScreenHistory"
    write-output "Input Status - $status3" | out-file -append "$ScreenHistory"
    write-output "Picture Mode Status - $status4" | out-file -append "$ScreenHistory"
    write-output "----------------------------------" | out-file -append "$ScreenHistory"

} 

#Search Status.txt and apply corrective action
$result = Select-String -Path $ScreenStatus -pattern off
$result3 = Select-String -Path $ScreenStatus -pattern "input not"
$result4 = Select-String -Path $ScreenStatus -pattern "picture mode not"



if ($result3 -ne $null) {
        $port.open()
       $port.WriteLine("ka 00 01")	#turn on
        start-sleep -s 10 
        $port.WriteLine("xb 00 70")	#set input to DVI
        $port.Close()
    }

if ($result -ne $null) {
        $port.open()
        $port.WriteLine("ka 00 01")	#turn on
        $port.Close()
        Write-host "One or more screens are off"
    }              

if ($result4 -ne $null) {
        $port.open()
        $port.WriteLine("dx 00 01")	#set pic mode to Standard
        $port.Close()
    }
    }

    else {
        write-host 'It is the weekend or outside of hours, script will not run'
            }



