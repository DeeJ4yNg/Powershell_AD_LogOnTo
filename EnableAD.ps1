#----------------------------------------------
#region Application Functions
#----------------------------------------------


$GLOBAL:PackageName = "Batch Enable AD Computers"
# get the absolut path of the script ! do not change !
$GLOBAL:criptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -parent
# include needed support functions ! do not change !
$global:LastExitCode 

."$criptRoot\support\spprtfnctns_.ps1"

$objShell = New-Object -ComObject Shell.Application


Import-Module ActiveDirectory


function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}

function Read-FolderBrowserDialog([string]$Message, [string]$InitialDirectory)
{
    $app = New-Object -ComObject Shell.Application
    $folder = $app.BrowseForFolder(0, $Message, 0, $InitialDirectory)
    if ($folder) { return $folder.Self.Path } else { return '' }
}


################################################
###### Get Content ######
################################################

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#$Selected_file = Read-OpenFileDialog "KPMG SCCM Installation Service - User Name" "Please enter User Name list file `(text file`) path `n`nLike: c:\temp\list.txt" "All files (*.*)|*.*" $false
#$Selected_file2 = Read-OpenFileDialog "KPMG SCCM Installation Service - Ticket Number" "Please enter Ticket Number list file `(text file`) path `n`nLike: c:\temp\list.txt" "All files (*.*)|*.*" $false
$Selected_file3 = Read-OpenFileDialog "KPMG SCCM Installation Service - Computer Name" "Please enter Computer Name list file `(text file`) path `n`nLike: c:\temp\list.txt" "All files (*.*)|*.*" $false
#$Ticket_Number = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter TICKET NUMBER of batch limitition of LogOnTo", "KPMG SCCM Installation Service", "")
$New_Description = "Missing security patches and restrict logon to"

#Write-Host `n$Selected_file
#$selected_file = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter list file `(text file`) path `n`nLike: c:\temp\list.txt", "Ping Script", "")

#$target_path = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter ping batch file path `n`nLike: c:\temp\", "Ping Script", "")
#$target_path = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter ping batch file path `n`nLike: c:\temp\", "Remote reinstall SCCM client", $criptRoot)
#$target_path = Join-Path $criptRoot software_List

#$content = Get-Content -Path $selected_file
#$content -is [Array]
#$content_length = $content.length
#Write-Host $content_length

#$content2 = Get-Content -Path $selected_file2
#$content2 -is [Array]
#$content_length2 = $content2.length

$content3 = Get-Content -Path $selected_file3
$content3 -is [Array]
$content_length3 = $content3.length

#Write-Host $selected_file
#Write-Host $selected_file2
Write-Host $selected_file3
#Write-Host $target_path


if (-not (Test-Path $selected_file3))
{
	[windows.forms.messagebox]::show("The text file `'$selected_file`' is not exist.","KPMG SCCM Installation Service","OK","Warning")
	Exit 99
}

#if ($content_length -ne $content_length2)
#{
	#[windows.forms.messagebox]::show("The User Name file is not match with Ticket Number file.","KPMG SCCM Installation Service","OK","Warning")
	#Exit 99
#}



#$DiagResult = [windows.forms.messagebox]::show("User Name file:`n$selected_file`n`n","KPMG SCCM Installation Service",1,"Warning") #'OK','Information') 
#$DiagResult2 = [windows.forms.messagebox]::show("Ticket Number file:`n$selected_file2`n`n","KPMG SCCM Installation Service",1,"Warning") #'OK','Information')
$DiagResult3 = [windows.forms.messagebox]::show("Ticket Number file:`n$selected_file3`n`n","KPMG SCCM Installation Service",1,"Warning") #'OK','Information')
Start-Sleep -Milliseconds 300	
if ($DiagResult -eq	[Windows.Forms.DialogResult]::Cancel)
{
	IW-LogEntry "User Cancel pics tidy up"
	IW-LogEntry "End Main program."
	Exit 99
}

#$count_file = [Microsoft.VisualBasic.Interaction]::InputBox("The list file has $content_length rows, please enter number of batch file", "Remote checking", "")


#################################

for($i=0;$i -lt $content_length3;$i++)
{
	#$detail_content = $content[$i]
    #$Ticket_Number = $content2[$i]
	$Computer_Name = $content3[$i]
	
	$2 = Get-ADComputer -identity $Computer_Name
	
	if($2 -ne $null)
		{
			$1 = Get-ADComputer -identity $Computer_Name -Properties * | Select-Object Enabled
	
			$Now_Enable = $1.enabled
			$Now_Enable = $Now_Enable.ToString()
	
			if($Now_Enable -eq 'True')
				{
			#Write-Host "AD Computer $Computer_Name already Enabled."
				}
			else
				{
					Set-ADComputer $Computer_Name -Enabled $true
			#Write-Host "AD Computer $Computer_Name Enable Successful."
				}
		
		
			$1 = Get-ADComputer -identity $Computer_Name -Properties * | Select-Object Enabled
	
			$Now_Enable = $1.enabled
			$Now_Enable = $Now_Enable.ToString()
	
			if($Now_Enable -eq 'True')
				{
					Write-Host "AD Computer $Computer_Name Enable Successful."
				}
			else
				{
					Write-Host "AD Computer $Computer_Name Enable Failed."
				}
	
		}
	else
		{
			Write-Host "AD Computer $Computer_Name Not Exist."
		}
	
		
		
	
	
	
	







#[reflection.assembly]::loadfile( "C:\Windows\Microsoft.NET\Framework\v2.0.50727\System.Drawing.dll") 
#[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
#[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")


#$Global:Target_Computer = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter target computer or IP address.`n`nLike: CNPC0SKV8X or 10.166.177.xxx", "SCCM Client Manually Fix", "")



#start-process "wmic.exe" -ArgumentList "/node:$detail_content process call create `"wscript.exe c:\temp\SCCM_1806\installer(withoutversionchecking).vbs`""

}

	

