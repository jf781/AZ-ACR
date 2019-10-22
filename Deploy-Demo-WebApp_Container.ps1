##Deployment Script

# Defines variable names
$RGName = "AHD-LabRG03"
$DockerImage = "privatebin/ahead"




# Create Resource Group
$LabRG = New-AzResourceGroup -Name $RGName -Location 'Central US'

# Create Azure Container Registry (ACR)
New-AzResourceGroupDeployment -Name "AHD-Lab-ACR" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Push docker image to ACR
$ACR = Get-AzContainerRegistry -ResourceGroupName $RGName
$Creds = Get-AzContainerRegistryCredential -Registry $ACR
$ACRPwd = $creds.Password | ConvertTo-SecureString -AsPlainText -Force
$Creds.pw | docker login $ACR.LoginServer -u $creds.Username --password-stdin
$TagName = $acr.LoginServer + "/ahead/demo"
docker tag $DockerImage $TagName
docker push $TagName

# Create AppService and AppService Plan
New-AzResourceGroupDeployment -Name "AHD-Lab-AppSvc" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Copy files to temp directory
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-acr-template.json | Select-Object -ExpandProperty content | out-file /tmp/webapp-template.json
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-acr-template-parameters.json | Select-Object -ExpandProperty content | out-file /tmp/webapp-template-parameters.json

# Deploy WebApp
New-AzResourceGroupDeployment -Name "AHD-Lab-WebApp" `
    -TemplateFile /tmp/webapp-template.json `
    -TemplateParameterFile /tmp/webapp-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName `
    -registryPassword (ConvertTo-SecureString -AsPlainText -Force -String $ACRPwd)

# Clean up temp files
rm /tmp/webapp-template.json
rm /tmp/webapp-template-parameters.json