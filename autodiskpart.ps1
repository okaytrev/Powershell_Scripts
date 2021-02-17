$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent


$CMDProcess = Get-Process cmd | select -expand id

$MAX=65GB
$DISK0 = 0

$myfile = "listdisk.txt"
$path = $PSScriptPath + "\" + $myfile

$myfile2 = "diskpart-step0.text"
$path2=$PSScriptPath + "\" + $myfile2

$LISTDISK=(DISKPART /S $path)   

$test= $LISTDISK[-1]

$DiskID=$LISTDISK[-1].substring(7,5).trim()
$SIZE=$LISTDISK[-1].substring(25,9)

NEW-ITEM -Name detail.txt -ItemType file -force | OUT-NULL 
ADD-CONTENT -Path detail.txt “SELECT DISK $DISKID” 
ADD-CONTENT -Path detail.txt “DETAIL DISK”
$DETAIL=(DISKPART /S DETAIL.TXT)

$MODEL=$DETAIL[8] 
$TYPE=$DETAIL[10].substring(9) 
$DRIVELETTER=$DETAIL[-1].substring(15,1)
$SIZE=$LISTDISK[-1-$d].substring(25,9).replace(” “,””) 

NEW-ITEM -Name $myfile2 -ItemType file -force | OUT-NULL

ADD-CONTENT -Path $myfile2 “SELECT DISK $DISKID”

ADD-CONTENT -Path $myfile2 “CLEAN”
ADD-CONTENT -Path $myfile2 “CREATE PARTITION PRIMARY”
ADD-CONTENT -Path $myfile2 “SELECT PARTITION 1”
ADD-CONTENT -Path $myfile2 “ACTIVE”
ADD-CONTENT -Path $myfile2 “FORMAT FS=NTFS QUICK”
ADD-CONTENT -Path $myfile2 “ASSIGN LETTER=W”


$b = new-object -comobject wscript.shell 
if ($size -lt $MAX -AND $DISKID -eq $DISK0) {
$b.popup("QUITING SO YOU DON'T WIPE *******DISK: $DISKID - SIZE: $SIZE*******")
Stop-Process $CMDProcess -force
exit
}



$a = new-object -comobject wscript.shell 
$intAnswer = $a.popup("ARE YOU SURE YOU WANT TO ERASE - 
   *******DISK: $DISKID - SIZE: $SIZE******* ", ` 
0,"!!!!!!!",4) 
If ($intAnswer -eq 6) { 
    $a.popup("DISKPART WILL PREPARE YOUR USB")
    $DETAIL=(DISKPART /S $myfile2)
} else { 
    $a.popup("PROGRAM WILL QUIT")
    Stop-Process $CMDProcess -force
} 



#$DETAIL=(DISKPART /S $myfile2)

#$a = new-object -comobject wscript.shell
#$b = $a.popup("Diskpart has finished, press okay to finish copying files, this may take some time...",0,"MESSAGE BOX") 
 
