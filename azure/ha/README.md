# <img align="center" src="https://github.com/ArtiomL/storage/blob/master/img/azure.png" height="70">&nbsp;&nbsp;F5 High Availability in Microsoft Azure

In a regular F5 Device Service Clustering working in High Availability mode, cluster members use Gratuitous ARP or MAC Masquerade during normal operation and when cluster failover occurs.

However, in Azure this is implemented by making RESTful API calls to Azure Resource Manager.

### azure_ad_app.ps1
To be able to automatically make these API calls, the two members must be provided with Azure Active Directory credentials using the Azure Role-Based Access Control (RBAC).
