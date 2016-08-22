# F5 Networks - Register Azure RM AD App for OAuth2 API Access
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.2, 21/08/2016

# Login to Azure RM
Login-AzureRmAccount

# Show all subscriptions
Get-AzureRmSubscription

# Select the subscription where the AD resides
$adSub = Get-AzureRmSubscription -SubscriptionName "Paper Street Soap"
$adSub | Select-AzureRmSubscription

# Record IDs
$subsID = $adSub.SubscriptionId
$tenantID = $adSub.TenantId

# AD application password
$adaPass = Read-Host 'Azure AD App Password:' -AsSecureString
$adaPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adaPass))

# Create a new AAD application
$armADApp = New-AzureRmADApplication -DisplayName "adappREST" -HomePage "https://paperstsoap.com/adapprest" -IdentifierUris "https://paperstsoap.com/adapprest" -Password $adaPass

# Record the application ID
$appID = $armADApp.ApplicationId.Guid

# Create a new SPN
New-AzureRmADServicePrincipal -ApplicationId $appID

# Assign a new role
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $appID

# Show all resource groups
Get-AzureRmResourceGroup

# Select the resource group where the Azure Load Balancer (LBAZ), F5 VMs and their availability set reside
$rgName = "rgPAPERSTSOAP"

# Record F5 VMs' NICs
$nicF5A = ((Get-AzureRmVM -ResourceGroupName $rgName -Name ((Get-AzureRmAvailabilitySet -ResourceGroupName $rgName).VirtualMachinesReferences[0].Id -split 'virtualMachines/')[1]).NetworkInterfaceIDs -split 'networkInterfaces/')[1]
$nicF5B = ((Get-AzureRmVM -ResourceGroupName $rgName -Name ((Get-AzureRmAvailabilitySet -ResourceGroupName $rgName).VirtualMachinesReferences[1].Id -split 'virtualMachines/')[1]).NetworkInterfaceIDs -split 'networkInterfaces/')[1]

# Encode the password
$adaPass = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($adaPass))

# JSON values
@{ "subID" = $subsID; "tenantID" = $tenantID; "appID" = $appID; "pass" = $adaPass; "rgName" = $rgName; "nicF5A" = $nicF5A; "nicF5B" = $nicF5B } | ConvertTo-Json
