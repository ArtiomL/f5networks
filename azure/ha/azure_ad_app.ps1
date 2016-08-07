# F5 Networks - Register Azure RM AD App for OAuth2 API Access
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0, 07/08/2016

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
$adaPass = "<Password>"

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

# Select the resource group where the Azure Load Balancer (LBAZ) resides
$rgName = "rgPAPERSTSOAP"

# JSON IDs
@{ "subID" = $subsID; "tenantID" = $tenantID; "appID" = $appID; "pass" = $adaPass; "rgName" = $rgName } | ConvertTo-Json
