<#
.SYNOPSIS
  Logs in to a given Azure subscription and sets the correct context for a selected subscription
.DESCRIPTION
  Sets the active powershell context for running scripts in the environment

.NOTES
  Version:        1.0
  Author:         Aaron Saikovski
  Creation Date:  29th November 2017
  Purpose/Change: Initial script development - Modified from an original script by Jim Britt from Microsoft Azure CAT team.
#>

# Import-Module -name Azure -RequiredVersion 5.0.0

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

#region UTILS
# Function used to build numbers in selection tables for menus
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}
#endregion UTILS

#region LOGIN

#Login to Azure and get the available subscriptions for a given user context
function DoLogin()
{

	$AzureLogin =$null
	[System.guid]$SubscriptionID = [guid]::Empty


	# Login to Azure - if already logged in, use existing credentials.
	Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
	try
	{
		$AzureLogin = Get-AzureRmSubscription
	}
	catch
	{
		$null = Login-AzureRmAccount
		$AzureLogin = Get-AzureRmSubscription
	}	

	# Authenticate to Azure if not already authenticated 
	# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
	If($AzureLogin -and !($SubscriptionID -ne [guid]::Empty))
	{
		[array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzureRmSubscription) 
		[int]$SelectedSub = 0

		# use the current subscription if there is only one subscription available
		if ($SubscriptionArray.Count -eq 1) 
		{
			$SelectedSub = 1
		}
		# Get SubscriptionID if one isn't provided
		while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
		{
			Write-host "Please select a subscription from the list below" 
			$SubscriptionArray | select "#", Id, Name | ft
			try
			{
				$SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
			}
			catch
			{
				Write-Warning -Message 'Invalid option, please try again.'
			}
		}
		if($($SubscriptionArray[$SelectedSub - 1].Name))
		{
			$SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
		}
		elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
		{
			$SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
		}
		write-verbose "You Selected Azure Subscription: $SubscriptionName"
		
		if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
		{
			[guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
		}
		if($($SubscriptionArray[$SelectedSub - 1].ID))
		{
			[guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
		}
	}
	Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
	$Null = Select-AzureRmSubscription -SubscriptionId $SubscriptionID.Guid

	#show the set context
	Get-AzureRmContext
}

#endregion LOGIN

#region EXPORTS
export-modulemember -function DoLogin
#endregion EXPORTS