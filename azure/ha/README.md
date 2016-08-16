# <img align="center" src="../azure.png" height="70">&nbsp;&nbsp;F5 High Availability in Microsoft Azure

In a regular F5 Device Service Clustering working in High Availability mode, cluster members use Gratuitous ARP or MAC Masquerade during normal operation and when cluster failover occurs.

However, in Azure this is implemented by making RESTful API calls to Azure Resource Manager.

<br>
## [azure_ad_app.ps1](azure_ad_app.ps1)

To be able to make API calls automatically, the two HA members must be provided with Azure Active Directory credentials ([`azure_ha.json`](azure_ha.json)) using the Azure Role-Based Access Control (RBAC).

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

# Select the resource group where the Azure Load Balancer (LBAZ) resides
$rgName = "rgPAPERSTSOAP"

# Encode the password
$adaPass = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($adaPass))

# JSON IDs
@{ "subID" = $subsID; "tenantID" = $tenantID; "appID" = $appID; "pass" = $adaPass; "rgName" = $rgName } | ConvertTo-Json
```

<br>
This will result in a [`JSON`](azure_ha.json) file, similar to the following:
```json
{
	"appID": "a3e3cf25-2db0-432e-a122-8224cd46215a",
	"tenantID": "6a0a327e-6612-424d-bb4d-5420ca02b9a7",
	"pass": "U2ViYXN0aWFu",
	"rgName": "rgPAPERSTSOAP",
	"subID": "b3481899-362a-4121-9355-1c4fa3e14b3d"
}
```

The file should be placed at the following location on both HA BIG-IPs: `/shared/tmp/scripts/azure/azure_ha.json`. This is controlled by the `strCFile` attribute of the `clsAREA` class.

<br>
## [emon_AZURE_HA.py](emon_AZURE_HA.py)

This external monitor is the actual HA / failover logic. It's under heavy development and isn't fully functional yet.
