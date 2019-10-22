<# 
Deployment Script that will push create the following items in the Azure subscription

    - Resource Group defined in the "RGName" variable
    - Azure Container Registry (ACR)
    - App Service Plan
    - Web App

It will push a local docker image that you have defined in the "DockerName" variable to the ACR and set that as the
containered used in the webapp

AHEAD - Joe Fecht - October 2019

#>

# Defines variable names
$RGName = "AHD-LabRG01"
$DockerImage = "privatebin/ahead"

# Create Resource Group
$LabRG = New-AzResourceGroup -Name $RGName -Location 'Central US'

# Create Azure Container Registry (ACR)
New-AzResourceGroupDeployment -Name "AHD-Lab-ACR" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Getting credentials and logging docker into ACR
$ACR = Get-AzContainerRegistry -ResourceGroupName $RGName
$Creds = Get-AzContainerRegistryCredential -Registry $ACR
$Creds.Password | docker login $ACR.LoginServer -u $creds.Username --password-stdin

# Storing creds in secure string variable
$ACRPwd = $creds.Password | ConvertTo-SecureString -AsPlainText -Force

#Clear creds variable stored in plain text
$Creds = $null

# Push docker image to ACR
$TagName = $acr.LoginServer + "/ahead/demo"
docker tag $DockerImage $TagName
docker push $TagName

# Create AppService Plan
New-AzResourceGroupDeployment -Name "AHD-Lab-AppSvc" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Copy ARM template JSON files to temp directory
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jf781/AZ-AppService/master/WebApp/az-webapp-acr-template.json | Select-Object -ExpandProperty content | out-file /tmp/webapp-template.json -Force
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jf781/AZ-AppService/master/WebApp/az-webapp-acr-template-parameters.json | Select-Object -ExpandProperty content | out-file /tmp/webapp-template-parameters.json -Force

# Deploy WebApp
New-AzResourceGroupDeployment -Name "AHD-Lab-WebApp" `
    -TemplateFile /tmp/webapp-template.json `
    -TemplateParameterFile /tmp/webapp-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName `
    -registryPassword (ConvertTo-SecureString -AsPlainText -Force -String $ACRPwd)

# Clean up temp files
rm /tmp/webapp-template.json
rm /tmp/webapp-template-parameters.json

# Restart Aheaddemo Web App
Get-AzWebApp -ResourceGroupName $labrg.ResourceGroupName | Restart-AzWebApp