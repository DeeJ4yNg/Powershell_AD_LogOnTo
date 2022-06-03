# Name: 		spprtfnctns_.ps1
# Purpose:   	support functions for use in InstallWrapper script
#
# VersionTracking:
#
# Ver   | Who              | Date       | What
# -----------------------------------------------
# 6.0.0 | JeffLau          | 7.5.2015 | Created


################# Initiate Logfiles #####################
$GLOBAL:PowerShellLogFileName = ($PackageName).Replace(" ","_") + "_" + (Get-Date -format yyyyMMdd_HH-mm-ss) + ".log"

$GLOBAL:PowerShellLogFilePath = "$ENV:PUBLIC\Logs\PowerShell"
$GLOBAL:PowerShellLogFile = Join-Path $PowerShellLogFilePath  $PowerShellLogFileName
If(!(Test-Path $PowerShellLogFilePath)){New-Item $PowerShellLogFilePath -Force -ItemType Directory}
If(!(Test-Path $PowerShellLogFile)){New-Item $PowerShellLogFile -Force -ItemType File}
$GLOBAL:InstallerLogFilePath = "$ENV:PUBLIC\KPMG\Logs\Installer"
If(!(Test-Path $InstallerLogFilePath)){New-Item $InstallerLogFilePath -Force -ItemType Directory}
$LogFileHeader = "KPMG SCCM Installation Service - Log created " + (Get-Date -format g) + " - Package Name: +++ " + $PackageName + " +++`n`n"
Out-File -FilePath $PowerShellLogFile -Append -Force -InputObject $LogFileHeader -NoClobber
$GLOBAL:LogCounter = 0
$GLOBAL:ourcePath = Join-Path $criptRoot sources
$GLOBAL:testPath = ""
$GLOBAL:Country = "HK"
$GLOBAL:Handle = "$criptRoot\Support\handle.exe /accepteula"
$GLOBAL:PleaseCloseAppMessage = 0
$GLOBAL:FUser = Gwmi Win32_Computersystem -Comp "." | Select UserName
$pos = $FUser.UserName.IndexOf("\")
$GLOBAL:User = $FUser.UserName.Substring($pos+1)
#$GLOBAL:User = $FUser.UserName.Substring(3)




####################GET SG#######################################
$strFilter = "(&(objectCategory=User)(samAccountName=$User))"
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter
$objPath = $objSearcher.FindOne()
$objUser = $objPath.GetDirectoryEntry()
$GLOBAL:usergroups = $objuser.memberof
$GLOBAL:ADdept = $objuser.departmentnumber
$GLOBAL:strGroup = ""

#$GLOBAL:Current_User = $FUser.UserName.Substring(3)
$GLOBAL:objUser = New-Object System.Security.Principal.NTAccount($User)
#$GLOBAL:strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$GLOBAL:SID = $strSID.Value

##################################################################
IF($LastExitCode){Remove-Variable LastExitCode}

################# END Initiate Logfiles #################

Function Global:IW-checkProgInstalled{
	Param($programName)
    $r1 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where {$_.DisplayName -match $programName}
	#$r1 = Get-WmiObject Win32_Product | Where {$_.Name -match $programName}
	If($r1 -eq $null){
        return $false
	}else{

		return $true
	}

}

Function Global:IW-checkFileVersion{
	Param($filePath, $fileVer)
	IW-LogEntry "Check File version -File path: $filePath -version: $fileVer"
 	WRITE-HOST [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath).FileVersion
	if($fileVer -eq [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath).FileVersion){
		return $true
	}else{
		return $false
	}

}


Function Global:IW-checkFileProductVersion{
	Param($filePath, $ProductVer)
	
	$fileinfo = Get-ItemProperty $filepath
	$CurrentProductVer = $fileinfo.VersionInfo.ProductVersion
	Write-Host $fileinfo.VersionInfo.ProductVersion
	Write-Host $ProductVer
	
	IW-LogEntry "Check target File Product version -File path: $filePath -Productversion: $ProductVer"
	IW-LogEntry "Check current File Product version -File path: $filePath -Productversion: $CurrentProductVer"
	
	if($ProductVer -eq $CurrentProductVer){
		IW-LogEntry "Check True"
		return $true
	}else{
		IW-LogEntry "Check False"
		return $false
	}

}
Function Global:IW-checkDept{
	Param($dept)
	$LastExitCode = $false
	IW-LogEntry "Check Department - $dept"

	    <#$strGroup = $usergroup.split(‘,’)[0]
	    $strGroup = $strGroup.split(‘=’)[1]
		#Write-Host $strGroup#>
	    if ($ADdept -eq $dept){ 
			$LastExitCode = $true
			IW-LogEntry "Check Dept - $ADdept - found"
	    }          


}

Function Global:IW-checkSG{
	Param($SGgroup)
	
	IW-LogEntry "Check SG - $SGgroup"
	foreach($usergroup in $usergroups)
	{
	    $strGroup = $usergroup.split(‘,’)[0]
	    $strGroup = $strGroup.split(‘=’)[1]
		#Write-Host $strGroup
	    if ($strGroup.Contains($SGgroup)){ 
			IW-LogEntry "Check SG - $SGgroup - found"
            Return $true
	    }else{
            IW-LogEntry "Check SG - $SGgroup - could not found"
            Return $false
        }           
	}   

}

Function Global:IW-checkEnvName{
	If($env:USERNAME.ToUpper() -eq $User.ToUpper()){
		IW-LogEntry "$User equal to $env:USERNAME`n"
		Return $true
	}else{
		IW-LogEntry "$User not equal to $env:USERNAME`n"
		Return $false
	}

}

Function Global:IW-GrantAdminRight{
IW-LogEntry "Granted admin right for $User`n"
$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
$group.add("WinNT://$env:USERDOMAIN/$User,user")

}

Function Global:IW-RemoveAdminRight{
IW-LogEntry "Removed admin right for $User`n"
$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
$group.Remove("WinNT://$env:USERDOMAIN/$User,user")

}

Function Global:IW-CheckAdminRight{
	IW-LogEntry "Checking admin right`n"
	$group =[ADSI]"WinNT://./Administrators" 
	$members = @($group.psbase.Invoke("Members")) 
	
	ForEach($obj in $members){
		$ab = $obj.GetType().InvokeMember("Name", 'GetProperty', $null, $obj, $null)
		$ab = $ab.ToUpper()
		$User = $User.ToUpper()
		if($ab -eq $User){
			IW-LogEntry "$User have admin right`n"
			Return $true
		}
	}
	IW-LogEntry "$User do not have admin right`n"
	Return $false
}



Function Global:IW-MergeRegFile{
	Param($RegFile)
	regedit /s ($RegFile)
	IW-LogEntry "Merge a Reg file - $RegFile"
}

################# Function definition block #####################
####################Revised by HK##############################################
Function Global:IW-LogEntry{
	Param($Entry)
	If($Entry -eq ""){$Entry = "function IW-LogEntry called without argument"}
	$LogEntry = "{0:D4}" -f $LogCounter + " - " + (Get-Date -format HH:mm:ss) + "." + "{0:D3}" -f [DateTime]::UtcNow.TimeOfDay.Milliseconds  + " - " +$Entry
	if ($LogLevel -ne 0){
		#Write-Host $LogEntry
	}
	Out-File -FilePath $PowerShellLogFile -Append -Force -InputObject $LogEntry -NoClobber
	$GLOBAL:LogCounter++
}
 
Function Global:IW-CheckRegistryExist {
param($keyPath, $name) 

	if(Get-ItemProperty -path $keyPath -Name $name -ErrorAction SilentlyContinue) {
		IW-LogEntry "Found Reg Key -path $keyPath -Name $name"
		Return $true
	}else{
		IW-LogEntry "Reg Key not found -path $keyPath -Name $name"
		Return $false
	}
}

Function Global:IW-CheckRegistrypathExist {
param($keyPath) 

	if(Test-Path -path $keyPath -ErrorAction SilentlyContinue) {
		IW-LogEntry "Found Reg Key -path $keyPath"
		Return $true
	}else{
		IW-LogEntry "Reg Key not found -path $keyPath"
		Return $false
	}
}

Function Global:IW-getRegistryValue {
param($keyPath, $name) 

	$val = Get-ItemProperty -path $keyPath -Name $name -ErrorAction SilentlyContinue  |%  {$_.Count} 
	if($val -eq $null) {
		Return $false
	}else{
		Return $val
	}
}


Function Global:IW-CheckRegistryValue {
param($keyPath, $name, $RegVal) 

	$val = Get-ItemProperty -path $keyPath -Name $name -ErrorAction SilentlyContinue  |%  {$_.$name} 
	if($val -ne $RegVal) {
		Return $False
	}else{
		Return $True
	}
}

Function Global:IW-RegSetValue{
	Param($RegPath, $RegName, $RegVal) 
	Set-ItemProperty -path $RegPath -name $RegName -value $RegVal -ErrorAction SilentlyContinue
	IW-LogEntry "Update a Reg key value -path $RegPath -name $RegName -PropertyType $RegType -value $RegVal"
}

Function Global:IW-CreateRegistry {
param($keyPath, $name, $value, $type) 
	MD $keyPath
	New-ItemProperty -Path $keyPath -Name $name -Value $value -PropertyType $type -ErrorAction SilentlyContinue
	IW-LogEntry "Create a Reg key value -path $keyPath -name $name -PropertyType $type -value $value"

}

Function Global:IW-RegSetValueHKU{
	Param($RegPath, $RegName, $RegType, $RegVal) 
	New-PSDrive -name HKU -psProvider Registry HKEY_USERS | out-null 
	Set-Location HKU:
	$JoinRegPath = "HKU:\$SID\$RegPath"
	Write-Host $JoinRegPath
	if(-not(Test-Path $JoinRegPath))
	{	New-Item -Path $JoinRegPath -ErrorAction SilentlyContinue	}
#	New-Item -path $JoinRegPath -name $RegName #-ErrorAction SilentlyContinue
	New-ItemProperty -path $JoinRegPath -name $RegName -PropertyType $RegType -value $RegVal -ErrorAction SilentlyContinue
	IW-LogEntry "Update a Reg key value -path $JoinRegPath -name $RegName -PropertyType $RegType -value $RegVal"
}



Function Global:IW-RemoveRegistry {
param($keyPath, $name) 
	Remove-ItemProperty -Path $keyPath -Name $name
	IW-LogEntry "Remove a Reg key value -path $keyPath -name $name"

}


function Show-MessageBox ($Title, $Message)
{
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[Windows.Forms.MessageBox]::Show($Message, $Title, [Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::DefaultDesktopOnly) | Out-Null
}
###################################################################################

Function Global:IW-CheckProcess{
    If (($args).count -eq 0){IW-LogEntry "Function Check-Process called without arguments - function skipped"; $GLOBAL:PleaseCloseAppMessage = 0;  Return }
    $ProcessCount = 0
    Foreach ($Option in $args){if($Option -ne ""){if (Get-Process *$Option -ea SilentlyContinue) {$ProcessCount++; $Process = $Option; $ProzessAbfrage = (Get-Process *$Option -ea SilentlyContinue); }}}
    If ($ProcessCount -gt 0) {
        $form1.visible = $false
    	$ApplicationDescription = ""
    	Foreach ($Option in $args){if (Get-Process *$Option -ea SilentlyContinue) {$ApplicationDescription += (Get-Process *$Option).Description + "`n"; $ApplicationDescriptionForLog += (Get-Process *$Option).Description + ", "}}    	
        Show-MessageBox("$PackageName")("Please close the following applications to continue:`n`n$ApplicationDescription")
    	IW-LogEntry "Function Check-Process - Initial Message - CountryCode: `"$Country`" - Applications to close: `"$ApplicationDescriptionForLog`""
    	Foreach ($Option in $args){
    		while ($true) {
    			$ApplicationName = (Get-Process *$Option).Description
    			if (Get-Process *$Option -ea SilentlyContinue) {
                    Show-MessageBox ("$PackageName")("The following application is still running, please close it to continue.`n`n$ApplicationName")
    				IW-LogEntry "Function Check-Process - CountryCode: `"$Country`" - PLease close `"$ApplicationName`""	
    				}
    			Else{
    				Break
    				}
    			}
    		}
    	$GLOBAL:PleaseCloseAppMessage = 1
#        $form1.visible = $true
		Return $true
    	}
    Else{
    	$GLOBAL:PleaseCloseAppMessage = 0
    	IW-LogEntry "Function Check-Process - none of the processes `"$args`" are running - nothing to close`n"
		Return $true
    }
}


Function Global:IW-CheckProcessIE{
$ProcessCount = 0
$ProcessCount = Get-Process IEXPLORE -ErrorAction SilentlyContinue

#	if($ProcessCount -ne $null )
#		{	
#		Show-MessageBox ("$PackageName")("Installation of $PackageName`n`nTo progress the installation it is necesssary to close the following applications:`n`nInternet Explorer")
#		IW-LogEntry "Function Check-Process IE"
#		}
		
while ($true) {
	if($ProcessCount -ne $null )
		{	
            Show-MessageBox ("$PackageName")("The following application is still running, please close it to continue.`n`nInternet Explorer")
			$ProcessCount = Get-Process IEXPLORE -ErrorAction SilentlyContinue
			IW-LogEntry "Function Check-Process: PLease close IE"
			if($ProcessCount -eq $null )
			{	return $false	}
		}
	else
		{	break	}
}
return $true
}


Function Global:IW-StopProcess{
If (($args).count -eq 0){IW-LogEntry "Function Stop-Process called without arguments - function skipped";  $GLOBAL:PleaseCloseAppMessage = 0;  Return }
$ProcessCount = 0
Foreach ($Option in $args){if (Get-Process *$Option -ea SilentlyContinue) {$ProcessCount++; $Process = $Option; $ProzessAbfrage = (Get-Process *$Option -ea SilentlyContinue); }}
If ($ProcessCount -gt 0) {
	IW-LogEntry "Function Stop-Process - Initial Message - CountryCode: `"$Country`" - Applications to close: `"$ApplicationDescriptionForLog`""
	Foreach ($Option in $args){
		while ($true) {
			$ApplicationName = (Get-Process *$Option).Description
			if (Get-Process *$Option -ea SilentlyContinue) {
				$process = Get-Process $Option	
                $process.kill()		
				IW-LogEntry "Function Stop-Process - CountryCode: `"$Country`" - Closed `"$ApplicationName`""	
			}
			Else{
				Break
				}
			}
		}	
	}
Else{
	IW-LogEntry "Function Stop-Process - none of the processes `"$args`" are running - nothing to close`n"
	}
}

Function Global:IW-StartProcess{
If (($args).count -eq 0){IW-LogEntry "Function Start-Process called without arguments - function skipped";    $GLOBAL:PleaseCloseAppMessage = 0;  Return }
$ProcessCount = 0
Foreach ($Option in $args){if (Get-Process *$Option -ea SilentlyContinue) {$ProcessCount++; $Process = $Option; $ProzessAbfrage = (Get-Process *$Option -ea SilentlyContinue); }}
	If ($ProcessCount -eq 0) {		
		IW-LogEntry "Function Start-Process - Initial Message - CountryCode: `"$Country`" - Applications to start: `"$ApplicationDescriptionForLog`""
		foreach ($Option in $args){
			while ($true) {
				
				if (Get-Process *$Option -ea SilentlyContinue) {
	                Break					
				}Else{
					start-Process $Option
				}
	            $ApplicationName = (Get-Process $Option).Description
				IW-LogEntry "Function Start-Process - CountryCode: `"$Country`" - Started `"$ApplicationName`""						
			}
		}
		
	}
	Else{
		IW-LogEntry "Function Start-Process - The processes `"$args`" are running - nothing to start`n"
	}
}

function Global:IW-SubCheckOpenFile {
Invoke-Expression "$handle $args"| Out-Null  # this function is need by IW-CheckOpenFile
If($LastExitCode -eq 0){Return $true}
Else {Return $False}
IF(!$LastExitCode){Remove-Variable LastExitCode}
}

Function Global:IW-CheckOpenFile{
If (($args).count -eq 0){IW-LogEntry "Function Check-OpenFile called without arguments - function skipped"; $GLOBAL:PleaseCloseAppMessage = 0;  Return }
$FileCloseCounter = 0
$FileToClose = ""
Foreach ($File in $args){Invoke-Expression "$handle $File" | Out-Null;  If($LastExitCode -eq 0){$FileCloseCounter++;$FileToClose = $FileToClose + $File + "`n"; $GLOBAL:PleaseCloseAppMessage = 1; $FilesForLog = $FilesForLog + $File + ", "}}
If ($FileCloseCounter -gt 0) {
#	Foreach($File in $args){
#		Invoke-Expression "$handle $File" | Out-Null
#		If($LastExitCode -eq 0){}
#	}

	Show-MessageBox ("KPMG SCCM Installation Service - $PackageName") ("Installation of $PackageName`n`nTo progress the installation it is necesssary to close the following files:`n`n$FileToClose")
	IW-LogEntry "Function Check-OpenFile - Initial Message - CountryCode: `"$Country`" - Files to close: `"$FilesForLog`""
foreach ($File in $args){
	while (IW-SubCheckOpenFile $File) {
		
		Show-MessageBox ("KPMG SCCM Installation Service - $PackageName") ("The file $File is still opened. Please close the file $File return to this dialog box and click OK to progress the installation!")
		IW-LogEntry "Function Check-OpenFile - CountryCode: `"$Country`" - PLease close `"$File`""	
	}
}
}
Write-Host "Check Open File - Line 148 - Last Exit Code: $LastExitCode"
IF(!$LastExitCode){Remove-Variable LastExitCode}
}


Function Global:IW-subCopyFile{
param($FileToCopy, $Destination) 
 $CopyTryCounter = 0;
 Do{
 Copy-Item -Path $FileToCopy -Destination $Destination -Force;$CopyTryCounter++;IW-LogEntry "Function Copy-File - Try number `"$CopyTryCounter`" - Source:`"$FileToCopy`" - Destination:`"$Destination`"";}
 Until ((Test-Path $Destination)-or($CopyTryCounter -eq 5))
		
 $Result = ((Test-Path $Destination));
 [System.Windows.Forms.Application]::DoEvents();
 IW-LogEntry "Function Copy-File - Result:`"$Result`" - TryCount:`"$CopyTryCounter`" - Source:`"$FileToCopy`" - Destination:`"$Destination`""  
 Return $Result;
  
   
}

Function Global:IW-CopyFile{
param($FileToCopy, $Destination, [Parameter(Mandatory=$false)][string]$addPath='') 


if ($FileToCopy -like '*\*') { 
$DestFileToCopy = Split-Path $FileToCopy -leaf;

}

Write-host " source:$FileToCopy"
Write-host " dest:$Destination" 
Write-host " destfiletocopy:$DestFileToCopy"
#Write-host " addpath:$addPath"
$ourcePath = Join-Path $criptRoot sources
$ourcePath = Join-Path $ourcePath $addPath
$testPath = Join-Path $ourcePath $FileToCopy
If($Destination -eq ""){IW-LogEntry "Function Copy-File called without Destination - function skipped"; Return}
ElseIf((Test-Path $testPath -PathType Container)){
    [System.Windows.Forms.Application]::DoEvents();
	IW-LogEntry "Function Copy-File called with directory - start copying all files in folder sources to `"$Destination`""
   
	Get-ChildItem $testPath -Exclude "Thumbs.db" | where{!$_.PsIsContainer} | Foreach-Object {$FileToCopy = ($_).PSChildName
	    $ourceFile = Join-Path $testPath $FileToCopy
		$DestinationFile = Join-Path $Destination $DestFileToCopy
		$DestinationPath = Split-Path $DestinationFile -Parent
		If (!(Test-Path $DestinationPath)){New-Item $DestinationPath -ItemType Directory -Force; [System.Windows.Forms.Application]::DoEvents();IW-LogEntry "Function Copy-File - necessary destination folder `"$DestinationPath`" created";}
		$CopyTryCounter = 0
		Do 
			{Copy-Item -Path $ourceFile -Destination $DestinationPath -Force; $CopyTryCounter++;[System.Windows.Forms.Application]::DoEvents();IW-LogEntry "Function Copy-File - Try number `"$CopyTryCounter`" - Source:`"$ourceFile`" - Destination:`"$DestinationFile`"";}
			Until ((Test-Path $DestinationFile)-or($CopyTryCounter -eq 5))
		$Result = ((Test-Path $DestinationFile))
		#if(!$Result){$LastExitCode = 1}
        
        [System.Windows.Forms.Application]::DoEvents();
		IW-LogEntry "Function Copy-File - Result:$Result - TryCount:`"$CopyTryCounter`" - Source:`"$ourceFile`" - Destination:`"$DestinationFile`""
		#Write-host "filedest: $DestinationFile"
        #Write-host "directory"
        Return $Result
	}
}Else{
	IW-LogEntry "Function Copy-File called - start copying `"$ourceFile`" to `"$Destination`""
    
		$ourceFile = Join-Path $ourcePath $FileToCopy
	$DestinationFile = Join-Path $Destination $DestFileToCopy
    #Write-host "filedest: $DestinationFile"
		$DestinationPath = Split-Path $DestinationFile -Parent
 
		If (!(Test-Path $DestinationPath)){New-Item $DestinationPath -ItemType Directory -Force;[System.Windows.Forms.Application]::DoEvents(); IW-LogEntry "Function Copy-File - necessary destination folder `"$DestinationPath`" created";$textboxResult.AppendText("Function Copy-File - necessary destination folder `"$DestinationPath`" created`n")}
	$CopyTryCounter = 0
	Do 
		{Copy-Item -Path $ourceFile -Destination $DestinationPath -Force; $CopyTryCounter++;[System.Windows.Forms.Application]::DoEvents();IW-LogEntry "Function Copy-File - Try number `"$CopyTryCounter`" - Source:`"$ourceFile`" - Destination:`"$DestinationFile`"";} #$textboxResult.AppendText("Function Copy-File - Try number `"$CopyTryCounter`" - Source:`"$ourceFile`" - Destination:`"$DestinationFile`"`n")}
		Until ((Test-Path $DestinationFile)-or($CopyTryCounter -eq 5))
		
		$Result = ((Test-Path $DestinationFile))
		#if(!$Result){$LastExitCode = 1}
    [System.Windows.Forms.Application]::DoEvents();
	IW-LogEntry "Function Copy-File - Result:`"$Result`" - TryCount:`"$CopyTryCounter`" - Source:`"$ourceFile`" - Destination:`"$DestinationFile`""  
        Return $Result
	#Write-host "file"
}


}




Function Global:IW-CopyFolder{
param($FolderToCopy, $Destination) 
#If(($args).Count -eq 0){IW-LogEntry "Function Copy-Folder called without arguments - function skipped"; Return}
If($Destination -eq ""){IW-LogEntry "Function Copy-Folder called without Destination - function skipped"; Return}
IW-LogEntry "Function Copy-Folder started - FolderToCopy: `"$FolderToCopy`" - Destination: `"$Destination`""
#$textboxResult.AppendText("Function Copy-Folder started - FolderToCopy: `"$FolderToCopy`" - Destination: `"$Destination`"`n")


    $from = "$criptRoot\sources\$FolderToCopy"
    $to =  $Destination

    Get-ChildItem -path $from -recurse | foreach-object{

    if ($_.PSIsContainer) {
             
                   $dest =  Join-Path $to $_.Parent.FullName.Substring($from.length)
                 
            } else {
                    
                   $dest =  Join-Path $to $_.FullName.Substring($from.length)
            }

    IW-subCopyFile $_.FullName $dest

    }

    IW-LogEntry "Function Copy-Folder finished - FolderToCopy: `"$FolderToCopy`" - Destination: `"$Destination`"`n"
}

Function Global:IW-ShowEndMessage{
If ($PleaseCloseAppMessage -eq 1){

	Show-MessageBox  ("KPMG SCCM Installation Service - $PackageName")("The installation of $PackageName has finished successfully.`n`nThank you for your cooperation.")
	IW-LogEntry "Function Show-EndMessage - CountryCode: `"$Country`" - `"$PackageName`" installation successful`n"
}
}

Function Global:IW-InstallMSP{
param($MSIFile) 
if ($MSIFile -eq ""){IW-LogEntry "Function Install-MSP called without argument MSP file - function skipped"; Return}
$MSILogFileName = ($PackageName).Replace(" ","_") + "_" + (Get-Date -format yyyyMMdd_HH-mm-ss) + ".log"
$MSILogFile = Join-Path $InstallerLogFilePath $MSILogFileName


$Result = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/p `"$criptRoot`\Sources`\$MSIFile`" REBOOT=ReallySuppress  /qn" -Wait -Passthru -WindowStyle Hidden).ExitCode
IW-LogEntry "Function Install-MSI started - MSI-Arguments: /p `"$criptRoot`\Sources`\$MSIFile`" REBOOT=ReallySuppress  /qn"


IW-LogEntry "Function Install-MSP finished - ExitCode: `"$Result`"`n"
$LastExitCode = $Result

}

Function Global:IW-InstallMSI{
param($MSIFile, $TransformsFile) 
IW-LogEntry "Start MSI installation"
if ($MSIFile -eq ""){IW-LogEntry "Function Install-MSI called without argument MSI file - function skipped"; Return}
If (($TransformsFile -eq "") -OR (!$TransformsFile)){$TransformsOption = ""}
Else{If ((Split-Path $TransformsFile -parent) -eq "") {$TransformsFile = Join-Path "$criptRoot\Sources" "$TransformsFile"}; $TransformsOption = "TRANSFORMS=`"" + $TransformsFile + "`""}
#$MSILogFileName = ($PackageName).Replace(" ","_") + "_" + (Get-Date -format yyyyMMdd_HH-mm-ss) + ".log"
#$MSILogFile = Join-Path $InstallerLogFilePath $MSILogFileName

$Result = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$criptRoot`\Sources`\$MSIFile`" $TransformsOption REBOOT=ReallySuppress  /qn" -Wait -Passthru -WindowStyle Hidden).ExitCode
IW-LogEntry "Function Install-MSI started - MSI-Arguments: /i `"$criptRoot`\Sources`\$MSIFile`" $TransformsOption REBOOT=ReallySuppress  /qn"
[System.Windows.Forms.Application]::DoEvents();

$global:LastExitCode = $Result
IW-LogEntry "Function Install-MSI finished - ExitCode: `"$Result`"`n"
if($result -ne 0){
Return $false
}else{
Return $true
}

}

Function Global:IW-UnInstallMSIByName{
param($ProductName) 
if ($ProductName -eq ""){IW-LogEntry "Function UnInstall-MSIByName called without arguments - function skipped";  Return }
$MSILogFileName = ($PackageName).Replace(" ","_") + "_" + (Get-Date -format yyyyMMdd_HH-mm-ss) + "_uninstall.log"
$MSILogFile = Join-Path $InstallerLogFilePath $MSILogFileName
$InstallationExists = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Where-Object -FilterScript {$_.GetValue("DisplayName") -match "$ProductName"})
if ($InstallationExists){
	$InstallationExists | ForEach-Object {
		$GUID = $_.Name.split("\\")[-1]
		
		# 1.1.5.1 | AM8            | 08.04.2011 | Changed for Global Powerpoint Toolbar Installation only with /qb-!
		$Result = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x$GUID REBOOT=ReallySuppress /l* `"$MSILogFile`" /qn" -Wait -Passthru).ExitCode
		IW-LogEntry "Function UnInstall-MSIByName started - MSI-Arguments: /x$GUID REBOOT=ReallySuppress /l* `"$MSILogFile`" /qn"
		
		IW-LogEntry "Function UnInstall-MSIByName finished - ExitCode: `"$Result`"`n"
		$LastExitCode = $Result
	}
}
Else {IW-LogEntry "Function UnInstall-MSIByName finished - Installation containing `"$ProductName`" does not exist`n"}
}

Function Global:IW-DeleteFile{
If (($args).Count -eq 0){IW-LogEntry "Function Delete-File called without argument - function skipped";  Return }
If (($args).Count -gt 1){IW-LogEntry "Function Delete-File called with too many arguments - function skipped";  Return }
If (!(Test-Path $args[0])){IW-LogEntry "Function Delete-File - File does not exist - function skipped";  Return }
If ((Get-ChildItem $args[0]).count -gt 1){IW-LogEntry "Function Delete-File - given argument fits more than 1 file - function skipped";  Return}
$FileDeleteTryCounter = 0
	Do 
		{Remove-Item -Path $args -Force; $FileDeleteTryCounter++;IW-LogEntry "Function Delete-File - Try number `"$FileDeleteTryCounter`" -- File to delete: `"$args`""}
		Until (!(Test-Path $args)-or($FileDeleteTryCounter -eq 5))
$Result = (!(Test-Path $$args))
IW-LogEntry "Function Delete-File - Result: $Result - TryCount: `"$FileDeleteTryCounter`" -- File to delete: `"$args`""
}

Function Global:IW-DeleteFolder{
param($FolderToDelete) 
If($Destination -eq ""){IW-LogEntry "Function Delete-Folder called without argument - function skipped"; Return}
If(!(Test-Path $FolderToDelete)){IW-LogEntry "Function Delete-Folder specified folder does not exist - function skipped"; Return}
IW-LogEntry "Function Delete-Folder started - Folder to delete: `"$FolderToDelete`""
Get-ChildItem $FolderToDelete -recurse | where{!$_.PsIsContainer} | Foreach-Object {$FileToDelete = ($_).FullName ; IW-DeleteFile $FileToDelete}
If (!(Get-ChildItem $FolderToDelete -recurse | where{!$_.PsIsContainer})){
IW-LogEntry "Function Delete-Folder - Folder contains no files anymore - deleting folder"
Remove-Item $FolderToDelete -recurse -force
If(!(Test-Path $FolderToDelete)){IW-LogEntry "Function Delete-Folder - `"$FolderToDelete`" successfully deleted`n"}
}
Else{
IW-LogEntry "Function Delete-Folder - not able to complete - `"$FolderToDelete`" still contains some files!`n"
}
}

Function Global:IW-CreateShortcut{
If (($args).Count -eq 0){IW-LogEntry "Function Create-Shortcut called without arguments - function skipped";  Return }
If (($args).Count -gt 5){IW-LogEntry "Function Delete-File called with too many arguments - function skipped";  Return }
If (!(Test-Path $args[0])){IW-LogEntry "Function Create-Shortcut - target file does not exist - function skipped";  Return }
If ((Get-ChildItem $args[0]).count -gt 1){IW-LogEntry "Function Create-Shortcut - given target file pattern fits more than 1 file - function skipped";  Return}
If ($args[2] -eq 1){$LinkLocation = "$ENV:PUBLIC\DESKTOP"}     										# All Users Desktop
ElseIf ($args[2] -eq 2){$LinkLocation = "$ENV:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs"}	# All Users Start Menu
ElseIf ($args[2] -eq 3){$LinkLocation = "$ENV:USERPROFILE\Desktop"}									# Users Desktop
ElseIf ($args[2] -eq 4){$LinkLocation = "$ENV:APPDATA\Microsoft\Windows\Start Menu\Programs"} 		# Users Start Menu
Else {IW-LogEntry "Function Create-Shortcut - given argument for link destination does not fir syntax - function skipped";  Return}
$LinkTarget = $args[0]
$LinkName = $args[1]
$LinkFileName = $LinkName + ".lnk"
$LinkFile = Join-Path $LinkLocation $LinkFileName
$LinkDestinationPath = Split-Path $LinkFile -Parent
$LinkArguments = $args[3]
$LinkIconLocation = $args[4]
IW-LogEntry "Function Create-Shortcut - Linkfile: `"$LinkFile`", LinkTarget: `"$LinkTarget`", LinkArguments: `"$LinkArguments`",  LinkIconLocation: `"$LinkIconLocation`""
If (!(Test-Path $LinkDestinationPath)){New-Item $LinkDestinationPath -ItemType Directory -Force; IW-LogEntry "Function Create-Shortcut - necessary destination folder `"$LinkDestinationPath`" created"}
$wshshell = New-Object -ComObject WScript.Shell
$lnk = $wshshell.CreateShortcut($LinkFile)
$lnk.TargetPath = $LinkTarget
$lnk.Arguments = $LinkArguments                                    
$lnk.WorkingDirectory = ""    
$lnk.Description = ""
If($args[4]){$lnk.IconLocation = $LinkIconLocation}
$lnk.Save()
$Result = ((Test-Path $LinkFile))
IW-LogEntry "Function Create-Shortcut - Result: `"$Result`" - Shortcut: `"$LinkFile`" - Target File: `"$LinkTarget`"`n"
}

Function Global:IW-ExecuteCommandline{
param([string]$Executable, [string]$Arguments, [Boolean]$WaitArguments)
	If (((Split-Path $Executable -parent) -eq "") -and (!($Executable -eq "%COMSPEC%")))  {$Executable = Join-Path $ourcePath $Executable}
	If ($Executable -eq "%COMSPEC%") {$Executable = $ENV:COMSPEC}
	If ($Arguments -eq ""){$Arguments = " "}
	If ($WaitArguments){
	IW-LogEntry "Function Execute-Commandline started - Executable: `"$Executable`", Arguments: `"$Arguments`" -wait"
	$Result = (Start-Process -FilePath "$Executable" -ArgumentList "$Arguments" -WindowStyle Hidden -wait -Passthru).ExitCode
	}else{
	IW-LogEntry "Function Execute-Commandline started - Executable: `"$Executable`", Arguments: `"$Arguments`" -not wait"
	$Result = (Start-Process -FilePath "$Executable" -ArgumentList "$Arguments" -WindowStyle Hidden -Passthru).ExitCode
	}
	IW-LogEntry "Function Execute-Commandline - Error Code: $Result`n"
	$LastExitCode = $Result
}






Function Global:IW-ParseRegFile{
$TempRegFile = $env:TEMP + "\" + ($PowerShellLogFileName).Replace(".log",".tmp")
$ourcePath = Join-Path $criptRoot sources
$RegFile = Join-Path $ourcePath $args[0]
IW-LogEntry "Function Parse-RegFile started - RegFile: `"$RegFile`" parsed RegFile: `"$TempRegFile`""
Get-ChildItem -Path Registry::HKEY_USERS\ -ea 0 -recurse -include "Volatile Environment" | ForEach-Object {
	(Get-Content $RegFile) -ireplace 'HKEY_CURRENT_USER', $_.PSParentPath.Split(":")[2] > $TempRegFile
}
IW-ExecuteCommandline "REG" "IMPORT $TempRegFile"
IW-DeleteFile $TempRegFile
}

Function Global:IW-GetLoggedOnUserProfile{
Get-Childitem -Path Registry::HKEY_USERS\ -ea 0 -Recurse -Include "Volatile Environment" | Get-ItemProperty  -Name Username | ForEach-Object {$InterActiveUser = $_.Username}
$InterActiveUserFilePath = Join-Path "C:\Users" $InterActiveUser
IW-LogEntry "Function Get-LoggedOnUserProfile started - Path: `"$InterActiveUserFilePath`"`n"
Return $InterActiveUserFilePath}

Function Global:IW-SetActiveSetup{
param($Path,$DisplayName,$tubPath,$Version)
$ActiveSetupPath = Join-Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components" "$Path"
IW-LogEntry "Function Set-ActiveSetup - Path: `"$Path`" - Display Name: `"$DisplayName`" - StubPath: `"$tubPath`" - Version: `"$Version`"`n"
If (!(Test-Path $ActiveSetupPath)){New-Item -Path $ActiveSetupPath}
Set-ItemProperty -path $ActiveSetupPath -name "(default)" -value $DisplayName 
Set-ItemProperty -path $ActiveSetupPath -name "StubPath" -value $tubPath -Type ExpandString
Set-ItemProperty -path $ActiveSetupPath -name "Version" -value $Version
}

Function Global:IW-CheckPendingReboot{
If ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" "PendingFileRenameOperations" -EA 0).PendingFileRenameOperations){
	IW-LogEntry "Function Check-PendingReboot - Reboot pending = `"$True`"`n"
	#If (!((Split-Path (IW-GetLoggedOnUserProfile) -leaf) -eq "k1_adm")){
	#	Show-MessageBox "The installation cannot be executed because a reboot from a previous installation is pending. Please restart your computer and try the installation of '$PackageName' again!"}
		#$LastExitCode = 3010
		Return $True
}
Else{IW-LogEntry "Function Check-PendingReboot - Reboot pending = `"$False`"`n"
	Return $False
	}
}

Function Global:IW-CheckACPower{
	$strComputer = "." 
	 
	 
	while ($true) {
		$colItems = get-wmiobject -class "Win32_Battery" -namespace "root\CIMV2" -computername $strComputer 
	 	foreach ($objItem in $colItems) { 			
			$tempstatus = $objItem.BatteryStatus 	  		
		}
		if($tempstatus -eq "1"){
			Show-MessageBox ("ITS Service Desk")("To continue the personalization for the first time, please connect to AC power and click `"OK`".")
    		IW-LogEntry "Function CheckACPower - Asking user connect to AC power"
	      		
		}else{
		  	Break
		}
	      
	} 
	
	
Function CheckVersion($softname, $softver)
{

	IW-LogEntry "Checking software exist or not"
    $r1 = Get-WmiObject Win32_Product | Where {$_.Name -match $softname -and $_.Version -eq $softver}
	#$r1 = Test-Path C:\Program Files (x86)\Adobe\Acrobat 2015\Acrobat\Acrobat.dll
	if ($r1	-ne $null) 
	{  
        Return $true   
    }else{
		Return $false
	}
}

	<#
	 Value - Meaning 
	 1 - The battery is discharging.
	 2 - The system has access to AC so no battery is being discharged. However, the battery is not necessarily charging.
	 3 - Fully Charged
	 4 - Low
	 5 - Critical
	 6 - Charging
	 7 - Charging and High
	 8 - Charging and Low
	 9 - Charging and Critical
	 10 - Undefined
	 11 - Partially Charged
	#>
}

################# End Of Function Definition Block #################


