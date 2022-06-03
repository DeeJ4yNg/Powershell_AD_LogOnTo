
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

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$New_Description = "xxxx"

$content3 = Get-Content -Path $selected_file3
$content3 -is [Array]
$content_length3 = $content3.length

if (-not (Test-Path $selected_file3))
{
	[windows.forms.messagebox]::show("The text file `'$selected_file`' is not exist.","KPMG SCCM Installation Service","OK","Warning")
	Exit 99
}
$DiagResult3 = [windows.forms.messagebox]::show("Ticket Number file:`n$selected_file3`n`n","ADTool",1,"Warning")
Start-Sleep -Milliseconds 300	
if ($DiagResult -eq	[Windows.Forms.DialogResult]::Cancel)
{
	Exit 99
}

for($i=0;$i -lt $content_length3;$i++)
{
	$Computer_Name = $content3[$i]
	$2 = Get-ADComputer -identity $Computer_Name
	if($2 -ne $null)
		{
			$1 = Get-ADComputer -identity $Computer_Name -Properties * | Select-Object Enabled
			$Now_Enable = $1.enabled
			$Now_Enable = $Now_Enable.ToString()
			if($Now_Enable -eq 'False')
				{
			Write-Host "AD Computer $Computer_Name already Enabled."
				}
			else
				{
					Set-ADComputer $Computer_Name -Enabled $False
			Write-Host "AD Computer $Computer_Name Enable Successful."
				}
		
		
			$1 = Get-ADComputer -identity $Computer_Name -Properties * | Select-Object Enabled
	
			$Now_Enable = $1.enabled
			$Now_Enable = $Now_Enable.ToString()
	
			if($Now_Enable -eq 'False')
				{
					Write-Host "AD Computer $Computer_Name Disable Successful."
				}
			else
				{
					Write-Host "AD Computer $Computer_Name Disable Failed."
				}
	
		}
	else
		{
			Write-Host "AD Computer $Computer_Name Not Exist."
		}
}

	

