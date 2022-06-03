$GLOBAL:PackageName = "Batch Enable AD Computers"
# get the absolut path of the script ! do not change !
$GLOBAL:criptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -parent
$global:LastExitCode 
."$criptRoot\supports.ps1"
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

$New_Description = "Missing security patches and restrict logon to"


$content3 = Get-Content -Path $selected_file3
$content3 -is [Array]
$content_length3 = $content3.length

if (-not (Test-Path $selected_file3))
{
	[windows.forms.messagebox]::show("The text file `'$selected_file`' is not exist.","ADTool","OK","Warning")
	Exit 99
}

$DiagResult3 = [windows.forms.messagebox]::show("Ticket Number file:`n$selected_file3`n`n","ADTool",1,"Warning")
Start-Sleep -Milliseconds 300	
if ($DiagResult -eq	[Windows.Forms.DialogResult]::Cancel)
{
	IW-LogEntry "User Cancel pics tidy up"
	IW-LogEntry "End Main program."
	Exit 99
}

for($i=0;$i -lt $content_length3;$i++)
{
	$Account = $content3[$i]
	$2 = get-aduser $Account	
	if($2 -ne $null)
		{
			add-adgroupmember -Identity "CN-SG Intune Android Users" -members $Account
			Write-Host "AD User $Account Added to CN-SG Intune Android Users."
			add-adgroupmember -Identity "CN-SG Intune Azure App Proxy Users" -members $Account
			Write-Host "AD User $Account Added to CN-SG Intune Azure App Proxy Users."
			add-adgroupmember -Identity "CN-SG Intune Exchange On-Prem Users" -members $Account
			Write-Host "AD User $Account Added to CN-SG Intune Exchange On-Prem Users."
			add-adgroupmember -Identity "CN-SG Intune iOS Users" -members $Account
			Write-Host "AD User $Account Added to CN-SG Intune iOS Users."
		}
	else
		{
			Write-Host "AD User $Account Not Exist."
		}
}


	

