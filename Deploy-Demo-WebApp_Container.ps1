##Deployment Script

# Defines variable names
$RGName = "AHD-LabRG01"
$DockerImage = "privatebin/ahead"



# Create Resource Group
$LabRG = New-AzResourceGroup -Name $RGName -Location 'Central US'

# Create ACR
New-AzResourceGroupDeployment -Name "AHD-Lab-ACR" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-ACR/master/acr-template-parameters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

# Push docker image to ACR
$ACR = Get-AzContainerRegistry -ResourceGroupName $RGName
$Creds = Get-AzContainerRegistryCredential -Registry $ACR
$ACRPwd = $creds.Password 
$ACRPwd | docker login $ACR.LoginServer -u $creds.Username --password-stdin
$TagName = $acr.LoginServer + "/ahead/demo"
docker tag $DockerImage $TagName
docker push $TagName

# Create AppService and AppService Plan
New-AzResourceGroupDeployment -Name "AHD-Lab-AppSvc" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-linux-template-paramters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

New-AzResourceGroupDeployment -Name "AHD-Lab-WebApp" `
    -TemplateUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-acr-template.json `
    -TemplateParameterUri https://raw.githubusercontent.com/jf781/AZ-AppService/master/AppSvc/az-appsvc-acr-template-paramters.json `
    -ResourceGroupName $LabRG.ResourceGroupName

