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

#region EXPORTFUNCTIONS

#Export function member
export-modulemember -function DeployResourceGroup
export-modulemember -function DeployResources
export-modulemember -function DeployDynamicResources
export-modulemember -function AddResourceGroupTags
export-modulemember -function LockResourceGroup

#endregion EXPORTFUNCTIONS