# <img align="center" src="../azure.png" height="70">&nbsp;&nbsp;F5 High Availability in Microsoft Azure

In a regular F5 Device Service Clustering working in High Availability mode, cluster members use Gratuitous ARP or MAC Masquerade during normal operation and when cluster failover occurs.

However, in Azure this is implemented by making RESTful API calls to Azure Resource Manager.

<br>
## [azure_ad_app.ps1](azure_ad_app.ps1)

To be able to automatically make these API calls, the two HA members must be provided with Azure Active Directory credentials ([`azure_ha.json`](azure_ha.json)) using the Azure Role-Based Access Control (RBAC).

This PowerShell code ([`azure_ad_app.ps1`](azure_ad_app.ps1)) automates this **one-time** process, while some user input is still required:

```powershell
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
```

<br>
## [emon_AZURE_HA.py](emon_AZURE_HA.py)

This external monitor is the actual HA / failover logic. It's under heavy development and isn't fully functional yet.
