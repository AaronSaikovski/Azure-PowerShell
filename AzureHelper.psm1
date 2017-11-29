#region DEPLOYRESOURCEGROUP
<#
  .SYNOPSIS
  Deploys a resource group and a given ARM template to the resource group

  .DESCRIPTION
  Deploys a resource group and a Azure Resource Manager template  

  .PARAMETER resourceGroupName
  The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

  .PARAMETER resourceGroupLocation
  Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.
  
  .NOTES
  Version:        1.0
  Author:         Aaron Saikovski
  Creation Date:  7th Sept 2016
  Purpose/Change: Initial script development  
#>
function DeployResourceGroup{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupName,

	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupLocation
	)

	Import-Module Azure -ErrorAction SilentlyContinue
	Set-StrictMode -Version 3
	$ErrorActionPreference = "Stop"

	# Create or update the resource group using the specified template file and template parameters file

	#check if the Resource group exists, if not create it
	$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
	if(!$resourceGroup)
	{
		#Create the resourcegroup
		Write-Host "Creating ResourceGroup - '$ResourceGroupName'"
		New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -ErrorAction Stop 
	}
	
}
#endregion DEPLOYRESOURCEGROUP

#region DEPLOYRESOURCES
<#
  .SYNOPSIS
  Deploys given ARM template to the resource group

  .DESCRIPTION
  Deploys a Azure Resource Manager template  

  .PARAMETER resourceGroupName
  The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

  .PARAMETER resourceGroupLocation
  Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

  .PARAMETER templateFilePath
   Path to the template file.

  .PARAMETER parametersFilePath
   Path to the parameters file. If file is not found, will prompt for parameter values based on template.
#>
function DeployResources{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupName,

	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupLocation,	 

	  [Parameter(Mandatory=$True)]
	  [string] $templateFile,

	  [Parameter(Mandatory=$True)]
	  [string] $parametersFile
	)

	Import-Module Azure -ErrorAction SilentlyContinue
	Set-StrictMode -Version 3
	$ErrorActionPreference = "Stop"

	# Create or update the resource group using the specified template file and template parameters file

	#Check for the ResourceGroup
	DeployResourceGroup -resourceGroupName $ResourceGroupName -resourceGroupLocation $resourceGroupLocation 
	
	#Add resources to the resource group
	Write-Host "Deploying Template - '$templateFile' - with parameters file '$parametersFile'" -ForegroundColor Yellow
	New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $templateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
									   -ResourceGroupName $ResourceGroupName `
									   -TemplateFile $templateFile `
									   -TemplateParameterFile $parametersFile #-debug

}
#endregion DEPLOYRESOURCES

#region DEPLOYDYNAMICRESOURCES
<#
  .SYNOPSIS
  Deploys given ARM template to the resource group

  .DESCRIPTION
  Deploys a Azure Resource Manager template  

  .PARAMETER resourceGroupName
  The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

  .PARAMETER resourceGroupLocation
  Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

  .PARAMETER templateFilePath
   Path to the template file.

  .PARAMETER parameters
   A hashtable of dynamic parameters
#>
function DeployDynamicResources{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupName,

	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupLocation,	 

	  [Parameter(Mandatory=$True)]
	  [string] $templateFile,

	  [Parameter(Mandatory=$True)]
	  [System.Collections.Hashtable] $parameters
	)

	Import-Module Azure -ErrorAction SilentlyContinue
	Set-StrictMode -Version 3
	$ErrorActionPreference = "Stop"

	# Create or update the resource group using the specified template file and template parameters file

	#Check for the ResourceGroup
	DeployResourceGroup -resourceGroupName $ResourceGroupName -resourceGroupLocation $resourceGroupLocation 
	
	#Add resources to the resource group
	Write-Host "Deploying Template - '$templateFile' - with dynamic parameters" -ForegroundColor Yellow
	New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $templateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
									   -ResourceGroupName $ResourceGroupName `
									   -TemplateFile $templateFile `
									   -TemplateParameterObject $parameters `
									   -Force
}

#endregion DEPLOYDYNAMICRESOURCES

#region DEPLOYRESOURCEGROUPTAGS
<#
  .SYNOPSIS
  Adds Tags to a given resource group

  .DESCRIPTION
  Updates a resource group to add Tags

  .PARAMETER resourceGroupName
  The resource group where to use.

  .PARAMETER resourceGroupTags
  Tags to set on the resource group
#>
function AddResourceGroupTags{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupName,

	  [Parameter(Mandatory=$True)]
	  [hashtable] $resourceGroupTags
	)

	Import-Module Azure -ErrorAction SilentlyContinue
	Set-StrictMode -Version 3
	$ErrorActionPreference = "Stop"

	#check if the Resource group exists
	$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
	if($resourceGroup)
	{
		#Build Date
		$buildDate = get-date -format u

		#Append Build date to tags
		$resourceGroupTags.Add('BuildDate', $buildDate)		

		#Add Tags
		Set-AzureRmResourceGroup -Tag $resourceGroupTags -Name $resourceGroupName
	}
	
}
#endregion DEPLOYRESOURCEGROUPTAGS

#region LOCKRESOURCEGROUP
<#
  .SYNOPSIS
  Locks a resourcegroup from being accidentally being deleted

  .DESCRIPTION
  Locks a given resource group

  .PARAMETER resourceGroupName
  The resource group where to use.
#>
function LockResourceGroup{
	[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $resourceGroupName	  
	)

	Import-Module Azure -ErrorAction SilentlyContinue
	Set-StrictMode -Version 3
	$ErrorActionPreference = "Stop"

	#check if the Resource group exists
	$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
	if($resourceGroup)
	{
		#Lock resource group
		New-AzureRMResourceLock -LockName "Lock Resources" -LockLevel CanNotDelete -ResourceGroupName $resourceGroupName -Force
	}
	
}
#endregion LOCKRESOURCEGROUP

#region LOGIN
<#
  .SYNOPSIS
  Logs a user in to Azure

  .DESCRIPTION
  Logs a user in to Azure and saves the login token to a local profile
#>
function Login()
{
	$profilePath = "C:\Users\" + [Environment]::UserName + "\Documents\azureProfile.profile"

	# sign in
	if (Test-Path $profilePath)
	{
		Write-Output "Loading saved profile..."
		Select-AzureRmProfile -Path $profilePath
	}
	else {
		Write-Output "Logging in..."
		Login-AzureRmAccount
		Save-AzureRmProfile -Path $profilePath
	}
}
#endregion LOGIN

#region GETREGIONNAME
<#
  .SYNOPSIS
  Gets the region name given a region code

  .DESCRIPTION
  Gets the region name given a region code
#>
#>
function GetRegionName{
		[CmdletBinding()]
	param(
	  [Parameter(Mandatory=$True)]
	  [string] $region	  
	)
	$azureRegions = @(
	@{RegionCode='eus';RegionName='East US';RegionLocation='Virginia'}
	@{RegionCode='eus2';RegionName='East US 2';RegionLocation='Virginia'}
	@{RegionCode='cus';RegionName='Central US';RegionLocation='Iowa'}
	@{RegionCode='ncus';RegionName='North Central US';RegionLocation='Illinois'}
	@{RegionCode='scus';RegionName='South Central US';RegionLocation='Texas'}
	@{RegionCode='wcus';RegionName='West Central US';RegionLocation='West Central US'}
	@{RegionCode='wus';RegionName='West US';RegionLocation='California'}
	@{RegionCode='wus2';RegionName='West US 2';RegionLocation='California'}
	@{RegionCode='cae';RegionName='Canada East';RegionLocation='Quebec City'}
	@{RegionCode='cac';RegionName='Canada Central';RegionLocation='Toronto'}
	@{RegionCode='brs';RegionName='Brazil South';RegionLocation='Sao Paulo State'}
	@{RegionCode='neu';RegionName='North Europe';RegionLocation='Ireland'}
	@{RegionCode='weu';RegionName='West Europe';RegionLocation='Netherlands'}
	@{RegionCode='dec';RegionName='Germany Central';RegionLocation='Frankfurt'}
	@{RegionCode='dene';RegionName='Germany Northeast';RegionLocation='Magdeburg'}
	@{RegionCode='ukw';RegionName='UK West';RegionLocation='Cardiff'}
	@{RegionCode='uks';RegionName='UK South';RegionLocation='London'}
	@{RegionCode='sea';RegionName='Southeast Asia';RegionLocation='Singapore'}
	@{RegionCode='ea';RegionName='East Asia';RegionLocation='Hong Kong'}
	@{RegionCode='aue';RegionName='Australia East';RegionLocation='New South Wales'}
	@{RegionCode='ause';RegionName='Australia Southeast';RegionLocation='Victoria'}
	@{RegionCode='cin';RegionName='Central India';RegionLocation='Pune'}
	@{RegionCode='win';RegionName='West India';RegionLocation='Mumbai'}
	@{RegionCode='sin';RegionName='South India';RegionLocation='Chennai'}
	@{RegionCode='jpe';RegionName='Japan East';RegionLocation='Tokyo'}
	@{RegionCode='jpw';RegionName='Japan West';RegionLocation='Osaka'}
	@{RegionCode='cne';RegionName='China East';RegionLocation='Shanghai'}
	@{RegionCode='cnn';RegionName='China North';RegionLocation='Beijing'}
	@{RegionCode='krc';RegionName='Korea Central';RegionLocation='Seoul'}
	@{RegionCode='krs';RegionName='Korea South';RegionLocation='TBC'}
	)

	$returnRegion = "Unknown Region"

	$azureRegions | % {
		if ($_.RegionCode.ToLower() -eq $region.ToLower())
		{
			$returnRegion = $_.RegionName 
		}
	}

	return $returnRegion 
}
#endregion GETREGIONNAME

#region GETHOSTINGSKU
<#
  .SYNOPSIS
  Gets the sku of the hosting plan given the size

  .DESCRIPTION
  Gets the sku of the hosting plan given the size
#>
function GetHostingSku([string]$instanceSize)
{
	if ($instanceSize.ToLower() -eq "small")
	{
		return "S1"
	}
	if ($instanceSize.ToLower() -eq "medium")
	{
		return "S2"
	}
	if ($instanceSize.ToLower() -eq "large")
	{
		return "S3"
	}
}
#endregion GETHOSTINGSKU

#region GETHOSTINGSKUNAME
<#
  .SYNOPSIS
  Gets the sku of the hosting plan given the size

  .DESCRIPTION
  Gets the sku of the hosting plan given the size
#>
function GetHostingSkuCapacity([string]$instanceSize)
{
	return 2
}
#endregion GETHOSTINGSKUNAME

#region GETGROUPNAME
<#
  .SYNOPSIS
  Gets the groupname given a region code

  .DESCRIPTION
  Gets the groupname given a region code
#>
function GetGroupName([string]$regionCode)
{
    if ($regionCode.ToLower() -eq "jpe")
    {
        return "ASIA"
    }
    elseif ($regionCode.ToLower() -eq "aue")
    {
        return "ANZ"
    }
    elseif ($regionCode.ToLower() -eq "weu")
    {
        return "EUROPE"
    }
	else 
	{
		return "Unknown"
	}
}
#endregion GETGROUPNAME

#region EXPORTFUNCTIONS

#Export function member
export-modulemember -function DeployResourceGroup
export-modulemember -function DeployResources
export-modulemember -function DeployDynamicResources
export-modulemember -function AddResourceGroupTags
export-modulemember -function LockResourceGroup
export-modulemember -function Login
export-modulemember -function GetRegionName
export-modulemember -function GetHostingSku
export-modulemember -function GetHostingSkuCapacity
export-modulemember -function GetGroupName

#endregion EXPORTFUNCTIONS