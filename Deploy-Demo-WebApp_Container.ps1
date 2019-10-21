##Deployment Script

# Defines variable names
$RGName = "AHD-LabRG01"



# Create Resource Group
$LabRG = New-AzResourceGroup -Name $RGName -Location 'Central US'

# Create ACR
New-AzResourceGroupDeployment -Name "AHD-Lab-ACR" `
    -TemplateUri https://github.com/jf781/AZ-ACR/blob/master/acr-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Push docker image to ACR
$ACR = Get-AzContainerRegistry -ResourceGroupName $RGName
$Creds = Get-AzContainerRegistryCredential -Registry $ACR
$creds.Password | docker login $ACR.LoginServer -u $creds.Username 

# Create AppService Plan

# Create Web App

