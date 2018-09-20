# <img align="center" src="f5.svg" height="64">&nbsp;&nbsp;F5 Networks
[![Releases](https://img.shields.io/github/release/ArtiomL/f5networks.svg)](https://github.com/ArtiomL/f5networks/releases)
[![Commits](https://img.shields.io/github/commits-since/ArtiomL/f5networks/v1.0.2.svg?label=commits%20since)](https://github.com/ArtiomL/f5networks/commits/master)
[![Maintenance](https://img.shields.io/maintenance/yes/2018.svg)](https://github.com/ArtiomL/f5networks/graphs/code-frequency)
[![Issues](https://img.shields.io/github/issues/ArtiomL/f5networks.svg)](https://github.com/ArtiomL/f5networks/issues)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)

&nbsp;&nbsp;

## Table of Contents
- [Description](#description)
- [Code](#code)
- [Solutions](#solutions)
	- [Platforms](#platforms)
	- [Network](#network)
	- [Service Provider](#service-provider)
	- [Security](#security)
	- [Cloud](#cloud)
	- [Containers](#containers)
	- [Management and Automation](#management-and-automation)
- [Licensing](#licensing)
- [Training](#training)
- [Videos](#videos)

&nbsp;&nbsp;

## Description

This project is dedicated to developing and sharing useful code for various F5 products and solutions.

&nbsp;&nbsp;

## Code

This repository:

| Path | Content |
| :--- | :--- |
| [/azure](/azure) | Code related to Microsoft's cloud computing **IaaS** |
| [/iapps](/iapps) | **iApps** is a declarative framework for deploying services-based, template-driven configurations |
| [/icontrol](/icontrol) | **iControl** is an open REST API that allows complete, dynamic and programmatic control |
| [/irules](/irules) | **iRules** is a highly customized scripting language allowing complete programmatic access to application traffic in real time |
| [/iruleslx](/iruleslx) | **iRules LX** is the next generation of iRules extending the functionality with Node.js and npm |
| [/monitors](/monitors) | The ability to effectively monitor the health of any application by writing custom scripts to interact with the servers |
| [/scripts](/scripts) | Scripts for various tasks |

Additional [repositories](https://github.com/ArtiomL?tab=repositories&q=f5).

&nbsp;&nbsp;

## Solutions

### `Platforms`

**BIG-IP System Hardware**  
https://www.f5.com/pdf/products/big-ip-platforms-datasheet.pdf

**VIPRION Modular Hardware**  
https://www.f5.com/pdf/products/viprion-overview-ds.pdf

**BIG-IP Virtual Editions**  
https://www.f5.com/pdf/products/big-ip-virtual-editions-datasheet.pdf

&nbsp;&nbsp;

### `Network`

**Local Traffic Manager (LTM)**  
Intelligent LB and Optimization, TLS Orchestration, Application Visibility and Analytics, Programmability  
https://www.f5.com/pdf/products/big-ip-local-traffic-manager-ds.pdf

**Global Traffic Manager (GTM/DNS)**  
Geographic and DNS LB, WAN Link (ISP) LB, DR Management, DNS Caching and Analytics, DNSSEC, DNS FW  
https://www.f5.com/pdf/products/big-ip-dns-datasheet.pdf

&nbsp;&nbsp;

### `Service Provider`

**Carrier-Grade NAT (CGNAT)**  
NAT44, NAT64, 464XLAT, PCP, DNS64, Application Layer Gateway, Tunneling  
https://www.f5.com/pdf/products/big-ip-cgnat-datasheet.pdf

**Policy Enforcement Manager (PEM)**  
Intelligent Traffic Classification and Steering, Dynamic Service Chaining, Bandwidth and Congestion Control  
https://www.f5.com/pdf/products/big-ip-policy-enforcement-manager-datasheet.pdf

&nbsp;&nbsp;

### `Security`

**Advanced Firewall Manager (AFM)**  
Full-Proxy FW, L3/4 DDoS Protection, Protocol Anomaly Detection, IP Reputation, SSH Proxy  
https://www.f5.com/pdf/products/big-ip-advanced-firewall-manager-datasheet.pdf

**Application Security Manager (ASM)**  
WAF, API and WebSocket Security, L7 DDoS and Bot Protection, Web Scraping and Brute-force Prevention  
https://www.f5.com/pdf/products/big-ip-application-security-manager-ds.pdf

**Advanced WAF (aWAF)**  
ASM, Behavioral DDoS, Credential Application-level Encryption, Anti-Bot Mobile SDK, Credential Stuffing Protection  
https://f5.com/products/security/advanced-waf

**Access Policy Manager (APM)**  
Context-aware Secure Access Control, Granular MFA, Identity Management and Federation, SSO, SSL VPN, SWG  
https://www.f5.com/pdf/products/big-ip-access-policy-manager-ds.pdf

**WebSafe**  
Clientless Application-level Encryption, Phishing and Pharming Detection, Advanced Fraud and Transaction Protection  
https://www.f5.com/pdf/products/websafe-datasheet.pdf

**MobileSafe**  
Client-side Mobile Threat Protection, Device Detection, Application-level Encryption  
https://www.f5.com/pdf/products/mobilesafe-datasheet.pdf

&nbsp;&nbsp;

### `Cloud`

**Silverline DDoS**  
Cloud-based L3–L7 DDoS Protection, Hybrid Signaling, Volumetric DDoS Mitigation, Security Operations Center (SOC)  
https://www.f5.com/pdf/products/silverline-ddos-datasheet.pdf

**Silverline WAF**  
Cloud-based Managed WAF-as-a-Service, Hybrid Policy Management and Deployment, Security Operations Center (SOC)  
https://www.f5.com/pdf/products/f5-silverline-web-application-firewall-datasheet.pdf

**Microsoft Azure**  
Azure Resource Manager Templates  
https://github.com/F5Networks/f5-azure-arm-templates

**Amazon Web Services**  
AWS CloudFormation Templates  
https://github.com/F5Networks/f5-aws-cloudformation

**Google Cloud Platform**  
Cloud Deployment Manager Templates  
https://github.com/F5Networks/f5-google-gdm-templates

&nbsp;&nbsp;

### `Containers`

**BIG-IP Controller for Kubernetes**  
https://github.com/F5Networks/k8s-bigip-ctlr

&nbsp;&nbsp;

### `Management and Automation`

**BIG-IQ Centralized Management**  
Fine-Grained Management with RBAC, Central Logging, Reporting and Auditing  
https://www.f5.com/pdf/products/big-iq-datasheet.pdf

&nbsp;&nbsp;

## Licensing

**Compare Product Bundles**    
https://www.f5.com/pdf/licensing/good-better-best-licensing-overview.pdf
 
**BIG-IP VE License and Throughput Limits**    
https://support.f5.com/csp/article/K14810
 
**vCMP**  
https://f5.com/resources/white-papers/virtual-clustered-multiprocessing-vcmp
 
&nbsp;&nbsp;
 
## Training
 
Free online training (you'll need to create a free account):  
https://university.f5.com

**Super-NetOps**  
A free, on-demand training covering DevOps methodologies and the concepts of automation, orchestration and IaC  
https://f5.com/SuperNetOps

**Training Courses and Classes (Tel Aviv)**  

| Course | Date | Length |
| :--- | :--- | :--- |
| [Configuring BIG-IP LTM: Local Traffic Manager](https://f5.com/education/training/courses/configuring-big-ip-local-traffic-manager-ltm) | 06/11/18 | 3 days |
| [Configuring BIG-IP ASM: Application Security Manager](https://f5.com/education/training/courses/configuring-big-ip-asm-application-security-manager) | 14/01/19 | 4 days |
| [Configuring BIG-IP APM: Access Policy Manager](https://f5.com/education/training/courses/configuring-big-ip-apm-access-policy-manager) | 04/02/19 | 3 days |
| [Configuring BIG-IP LTM: Local Traffic Manager](https://f5.com/education/training/courses/configuring-big-ip-local-traffic-manager-ltm) | 11/03/19 | 3 days |
| [Developing iRules for BIG-IP](https://f5.com/education/training/courses/developing-irules-for-big-ip) | 08/04/19 | 3 days |
| [Configuring BIG-IP ASM: Application Security Manager](https://f5.com/education/training/courses/configuring-big-ip-asm-application-security-manager) | 03/06/19 | 4 days |
| [Configuring BIG-IP APM: Access Policy Manager](https://f5.com/education/training/courses/configuring-big-ip-apm-access-policy-manager) | 22/07/19 | 3 days |
| [Configuring BIG-IP LTM: Local Traffic Manager](https://f5.com/education/training/courses/configuring-big-ip-local-traffic-manager-ltm) | 16/09/19 | 3 days |
| [Configuring BIG-IP ASM: Application Security Manager](https://f5.com/education/training/courses/configuring-big-ip-asm-application-security-manager) | 11/11/19 | 4 days |

&nbsp;&nbsp;

## Videos
 
https://www.youtube.com/playlist?list=UUSa_Fvtiv5i6NZiJAMhIJ9Q
