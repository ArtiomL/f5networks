# <img align="center" src="https://github.com/ArtiomL/storage/blob/master/img/azure.png" height="64">&nbsp;&nbsp;F5 High Availability in Microsoft Azure

In a regular F5 Device Service Clustering working in High Availability mode, cluster members use Gratuitous ARP or MAC Masquerade during normal operation and when cluster failover occurs.

In contrast, in Azure this is implemented by making RESTful API calls to Azure Resource Manager.
