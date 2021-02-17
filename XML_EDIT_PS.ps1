#***********************Stops CP and all of its services ***********

    $signid = get-process Signage | select -expand id
    Stop-Process $signid -Force
    $serviceid = get-service ContentPlayerService | select -expand id
    Stop-service $serviceid -Force
    $cpproid = get-process ContentPlayerService | select -expand id
    Stop-Process $cpproid -Force
    $monitorid = get-process ContentPlayerMonitor | select -expand id
    Stop-Process $monitorid -Force

#Add in Hostname, username, and password for 5.2 deployments 



# *******DeploymentSettings
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentSettings.xml")

$xmlDoc.DeploymentSettings.IsRemote = "True" 
$xmlDoc.DeploymentSettings.ConnectionProperties.Name = "SftpConnectionProperties" 
$xmlDoc.DeploymentSettings.ConnectionProperties.Hostname = "http://papfwiwp01/fwiservicesdeploy/"
$xmlDoc.DeploymentSettings.ConnectionProperties.Username = "fwideployment"
# Password not used $xmlDoc.DeploymentSettings.ConnectionProperties.ExtendedProperties = "vnvCBO+4/0wEKNaM4b45g+SKM7BPUQ4BrjxOGg/Zadc="
$xmlDoc.DeploymentSettings.ConnectionProperties.Protocol = "Fwi"
$xmlDoc.DeploymentSettings.ConnectionProperties.Protocol = "80"
$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentSettings.xml")



# *******Deployment.xml
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\Deployment.xml")
 

$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Name = "SftpConnectionProperties"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Hostname = "http://papfwiwp01/fwiservicesdeploy/"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Username = "fwideployment"
#Password not used $xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.ExtendedProperties = "vnvCBO+4/0wEKNaM4b45g+SKM7BPUQ4BrjxOGg/Zadc="

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\Deployment.xml")


# *******DeploymentLite
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentLite.xml")

$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Name = "SftpConnectionProperties" 
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Hostname = "http://papfwiwp01/fwiservicesdeploy/"
$xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.Username = "fwideployment"
#Password not used $xmlDoc.DeploymentData.Company.Machines.Machine.SftpConnectionProperties.ExtendedProperties = "vnvCBO+4/0wEKNaM4b45g+SKM7BPUQ4BrjxOGg/Zadc="

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Channels\(default)\DeploymentLite.xml")



#**********DeviceSettings
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\DeviceSettings.xml")

$xmlDoc.DeviceSettings.UseFwiServices = "true"
$xmlDoc.DeviceSettings.FwiServicesConnectionProperties.Name = "SftpConnectionProperties"
$xmlDoc.DeviceSettings.FwiServicesConnectionProperties.Hostname = "http://PAPFWIWP02/fwiservicesreport" 
$xmlDoc.DeviceSettings.FwiServicesConnectionProperties.Username = "fwiadmin"

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\DeviceSettings.xml")



#  ProfileSettings - Set principal Application *****
[xml]$xmlDoc = (get-content "C:\Users\Public\Documents\Four Winds Interactive\Signage\Profiles\(default)\ProfileSettings.xml")
 
$xmlDoc.ProfileSettings.IsPrincipalApplicationOnDefaultDesktop = "true"

$xmlDoc.Save("C:\Users\Public\Documents\Four Winds Interactive\Signage\Profiles\(default)\ProfileSettings.xml")