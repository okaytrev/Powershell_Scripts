#***********************Stops CP and all of its services ***********

    $signid = get-process Signage | select -expand id
    Stop-Process $signid -Force
    $serviceid = get-service ContentPlayerService | select -expand id
    Stop-service $serviceid -Force
    $cpproid = get-process ContentPlayerService | select -expand id
    Stop-Process $cpproid -Force
    $monitorid = get-process ContentPlayerMonitor | select -expand id
    Stop-Process $monitorid -Force
#-----------------------------------------------------------------------


#Add in Hostname, username, and password for 5.2 deployments 



# ***********************DeploymentSettings****************
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentSettings.xml")

$xmlDoc.DeploymentSettings.IsRemote = "True" 
$xmlDoc.DeploymentSettings.ConnectionProperties.Name = "SftpConnectionProperties" 
$xmlDoc.DeploymentSettings.ConnectionProperties.Hostname = "https://goboard2.fwicloud.com/fwiservices"
$xmlDoc.DeploymentSettings.ConnectionProperties.Username = "goboard\goboard"
$xmlDoc.DeploymentSettings.ConnectionProperties.ExtendedProperties = "ZYFOQBOqvvRmCal0qt84oXbTn3eqC4zv0+/rdA83vEY="
$xmlDoc.DeploymentSettings.ConnectionProperties.Protocol = "Fwi"
$xmlDoc.DeploymentSettings.ConnectionProperties.Protocol = "80"
$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentSettings.xml")


# ***********************Device Settings****************
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\DeviceSettings.xml")

$xmlDoc.DeviceSettings.UseSeparateDesktop = "false"
$xmlDoc.DeviceSettings.UseWindowsTouch = "false"

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\DeviceSettings.xml")



# ***********************Deployment.xml****************
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\Deployment.xml")
 

$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Name = "SftpConnectionProperties"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Hostname = "https://goboard2.fwicloud.com/fwiservices"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Username = "goboard\goboard"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.ExtendedProperties = "ZYFOQBOqvvRmCal0qt84oXbTn3eqC4zv0+/rdA83vEY="

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\Deployment.xml")


# ***********************DeploymentLite****************
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentLite.xml")

$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Name = "SftpConnectionProperties" 
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Hostname = "https://goboard2.fwicloud.com/fwiservices"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Username = "goboard\goboard"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.ExtendedProperties = "ZYFOQBOqvvRmCal0qt84oXbTn3eqC4zv0+/rdA83vEY="

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentLite.xml")
