#!/bin/bash
# F5 Networks - BIG-IP Hardening Guide
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v2.1.2, 05/11/2017


# System Account Passwords
tmsh modify /auth password root
tmsh modify /auth user admin prompt-for-password
tmsh modify /sys db systemauth.disablerootlogin value true 	#Warning! Disables root login!
	# userdel admin 	#Warning! Disables admin! Create an alternative administrative user first!
tmsh modify /sys db users.strictpasswords value enable
tmsh modify /auth password-policy minimum-length 13 required-lowercase 3 required-numeric 3 required-special 2 required-uppercase 3
tmsh modify /auth password-policy policy-enforcement enabled


# System
tmsh modify /sys db ui.system.preferences.advancedselection value advanced
tmsh modify /sys db ui.system.preferences.recordsperscreen value 100
tmsh modify /sys db ui.advisory.color value red
tmsh modify /sys db ui.advisory.text value `tmsh list /sys global-settings hostname | grep hostname | cut -d" " -f6`
tmsh modify /sys db ui.advisory.enabled value true
tmsh modify /sys diags ihealth user <\\'str_iUSER'\\>
tmsh modify /sys diags ihealth password <\\'str_iPASS'\\>
tmsh create /ltm eviction-policy evpol_REAPER slow-flow { enabled true } strategies { bias-bytes { enabled true delay 10 } low-priority-geographies { countries add { CN EG } enabled true } }


# Naming Conventions and Defaults
# Please choose and use a consistent naming convention across all configuration objects: pool_HTTP_APACHE, mon_HTTP_HEAD, prof_HTTP_XFF, virt_EXAMPLE.COM_80 etc.
# Additionally, please avoid using the default settings (e.g. monitors, profiles, methods, certificates etc.) except where intentionally needed
mkdir /var/tmp/scripts/ 	#Put all your shell scripts here


# NTP
tmsh modify /sys ntp servers replace-all-with { <\\'addr_NTP1_IP'\\> <\\'addr_NTP2_IP'\\> } timezone Israel


# DNS
tmsh modify /sys dns name-servers replace-all-with { <\\'addr_DNS1_IP'\\> <\\'addr_DNS2_IP'\\> } search replace-all-with { <\\'str_DOMAIN1'\\> <\\'str_DOMAIN2'\\> }
tmsh modify /sys db dnssec.maxnsec3persec value 10
tmsh modify /sys db dnssec.signaturecachensec3 value false
tmsh create /ltm profile dns dns_prof_DDoS enable-rapid-response yes rapid-response-last-action drop enable-hardware-query-validation yes enable-hardware-response-cache yes unhandled-query-action drop use-local-bind no


# AFM
tmsh create /security firewall rule-list afm_rl_DROP_UDP { rules add { afm_rule_DROP_UDP { action drop ip-protocol udp place-after first } } }
tmsh create /security dns profile afm_prof_DNS { query-type-inclusion yes query-type-filter replace-all-with { a aaaa cname mx ptr txt } }
tmsh create /security dos profile afm_dprof_DNS protocol-dns add { afm_dprof_DNS { dns-query-vector add { a aaaa cname mx ptr txt { enforce enabled rate-threshold 3000 rate-limit 5000 } } } }
tmsh create /security ip-intelligence policy afm_ipol_TIER1 blacklist-categories add { botnets denial_of_service infected_sources phishing proxy scanners spam_sources web_attacks windows_exploits }


# TCP Profiles
tmsh create /ltm profile tcp prof_F5_TCP_WAN_DDoS defaults-from f5-tcp-wan deferred-accept enabled syn-cookie-enable enabled zero-window-timeout 10000 idle-timeout 180 reset-on-timeout disabled
tmsh modify /sys db tm.maxrejectrate value 100
tmsh modify /ltm global-settings traffic-control reject-unmatched disabled
tmsh modify /ltm global-settings connection vlan-keyed-conn enabled 	#Default


# SSL Profiles
tmsh create /ltm profile client-ssl clientssl-hard secure-renegotiation require-strict
tmsh modify /ltm profile client-ssl clientssl-hard max-renegotiations-per-minute 3	#11.6 and on
tmsh modify /ltm profile client-ssl clientssl-hard ciphers 'NATIVE:!NULL:!LOW:!EXPORT:!RC4:!DES:!3DES:!ADH:!DHE:!EDH:!MD5:!SSLv2:!SSLv3:!DTLSv1:@STRENGTH'
tmsh modify /ltm profile client-ssl clientssl-hard options { dont-insert-empty-fragments no-dtls no-ssl }


# HTTP Profiles
tmsh modify /ltm profile http http server-agent-name aws
tmsh modify /ltm profile http http hsts { mode enabled } 	#Disable for HTTP Virtual Servers (New Child Profile)


# Persistence Profiles
tmsh modify /ltm persistence cookie cookie cookie-name "`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10`"


# ASM
tmsh create /security dos profile asm_dprof_L7DoS { application add { asm_dprof_L7DoS { bot-defense { mode always } bot-signatures { categories add { "Search Engine" { action report } } check enabled } stress-based { mode blocking } } } }
# L7 DDoS alternative: https://devcentral.f5.com/wiki/iRules.HTTP-URI-Request-Limiter.ashx
# Designate a Login-Wall with ASM (Sessions and Logins > Login Enforcement) or an iRule:
# https://devcentral.f5.com/wiki/iRules.Simple-Login-Wall-iRule-Redirect-unauthenticated-users-back-to-login-page.ashx


# Virtual Servers
# F5 recommends the use of Full Proxy (Standard) Virtual Servers when DDoS is a concern
	# profiles: prof_F5_TCP_WAN_DDoS { context clientside }, f5-tcp-lan { context serverside }
tmsh modify /ltm virtual <\\'vs_NAME'\\> description <\\'vs_DESCRIPTION'\\>
tmsh modify /ltm virtual <\\'vs_NAME'\\> source-address-translation { type snat pool <\\'pool_SNAT'\\> }	#Use SNAT Pools to avoid Port Exhaustion
tmsh modify /ltm virtual <\\'vs_NAME'\\> vlans-enabled vlans replace-all-with { <\\'vlan_NAME'\\> }


# Network
tmsh modify /net self all allow-service none
tmsh modify /net vlan <\\'vlan_NAME'\\> dag-round-robin enabled
tmsh modify /sys db dag.roundrobin.udp.portlist value 53


# Authentication
tmsh modify /auth password-policy max-login-failures 0 	#Default


# SSHD
tmsh modify /sys sshd inactivity-timeout 180
tmsh modify /sys sshd allow replace-all-with { <\\'addr_IP_SUBNET'\\>/<\\'addr_IP_MASK'\\> }


# Banners
tmsh modify /sys sshd banner enabled banner-text '"
 ******************************************************************************************
 *                                                                                        *
 *                                        WARNING!                                        *
 *                                                                                        *
 *             This is a private system. If you are not authorized to access              *
 *   this system, exit immediately. Unauthorized access to this system is forbidden by    *
 *                organization policies, national and international laws.                 *
 *                                                                                        *
 *             Unauthorized users are subject to criminal and civil penalties             *
 *              as well as organization initiated disciplinary proceedings.               *
 *                                                                                        *
 ******************************************************************************************
"'
tmsh modify /sys global-settings gui-security-banner enabled gui-security-banner-text '"WARNING!

This is a private system. If you are not authorized to access this system, exit immediately.

Unauthorized access to this system is forbidden by organization policies, national and international laws.

Unauthorized users are subject to criminal and civil penalties as well as organization initiated disciplinary proceedings.
"'


# HTTPD
tmsh modify /sys httpd max-clients 10 	#Default
tmsh modify /sys httpd auth-pam-idle-timeout 180
tmsh modify /sys httpd ssl-protocol "all -SSLv2 -SSLv3"
tmsh modify /sys httpd allow replace-all-with { <\\'addr_IP_SUBNET'\\>/<\\'addr_IP_MASK'\\> }


# SNMP
tmsh modify /sys snmp communities delete { comm-public }


# Logging
tmsh modify /sys log-rotate max-file-size 10240
tmsh modify /sys daemon-log-settings mcpd audit enabled 	#Default
tmsh modify /cli global-settings audit enabled 	#Default
tmsh modify /sys syslog remote-servers replace-all-with { rsrv_SYSLOG { host <\\'addr_SYSLOG_IP'\\> remote-port 514 } }		#Uses the legacy logging system (local-db-publisher)
# Use the following configuration for off-box logging:
tmsh create /ltm pool pool_HSL members add { <\\'addr_SYSLOG_IP'\\>:514 }
tmsh create /sys log-config destination remote-high-speed-log logd_HSL { protocol udp pool-name pool_HSL }
tmsh create /sys log-config destination remote-syslog logd_FORMAT_SYSLOG { format rfc5424 remote-high-speed-log logd_HSL }
tmsh create /sys log-config publisher logp_HSL { destinations replace-all-with { logd_HSL logd_FORMAT_SYSLOG } }
tmsh create /sys log-config filter logf_HSL { level info source all publisher logp_HSL }


# System Daemons
bigstart stop big3d gtmd named oauth ovsdb-server rmonsnmpd sflow_agent snmpd stpd vxland zrd zxfrd
bigstart remove big3d gtmd named oauth ovsdb-server rmonsnmpd sflow_agent snmpd stpd vxland zrd zxfrd
# Warning! Disables system services! Review https://support.f5.com/csp/article/K05645522 for your own daemon list 


# Aliases
echo -e "\n\n\n" >> ~/.bashrc
echo \#---------- hardF5 ---------- >> ~/.bashrc
echo alias lsl=\'ls -lFh\' >> ~/.bashrc
echo alias lsa=\'ls -AFh\' >> ~/.bashrc
echo alias bk=\'cd -\' >> ~/.bashrc
echo alias i=\"echo -e \'\\e[1m\'\; \(echo -e \'Name IP-Address Allow-Service Floating Traffic-Group VLAN\\033[0m\'\; tmsh list /net self all one-line all-properties \| sed \'s/{\\\|}//g\' \| sed \'s/fw-.* none//\' \| awk \'{print \\\$3,\\\$5,\\\$9,\\\$15,\\\$23,\\\$27}\' \| sort\) \| column -t\; echo\;\" >> ~/.bashrc
echo alias scr=\'cd /var/tmp/scripts\' >> ~/.bashrc
echo alias t=\'tailf /var/log/ltm\' >> ~/.bashrc
echo alias t1=\'tailf /var/log/apm\' >> ~/.bashrc
echo alias t2=\'tailf /var/log/gtm\' >> ~/.bashrc
echo alias t3=\'tailf /var/log/asm\' >> ~/.bashrc
echo alias td=\'tcpdump -v -i 0.0:nnn -s 0 -w /var/tmp/\`date +\"%Y.%m.%d_%H.%M.%S\"\`.pcap\' >> ~/.bashrc
echo alias ap=\'fun_APM_AP\' >> ~/.bashrc
echo alias cs=\'tmsh run /cm config-sync to-group dg_HA\' >> ~/.bashrc
echo fun_APM_AP\(\) \{ >> ~/.bashrc
echo "    tmsh modify /apm profile access \$1 generation-action increment" >> ~/.bashrc
echo \} >> ~/.bashrc
echo \#----------  EoF  -----------  >> ~/.bashrc
echo -e "\n\n\n" >> ~/.bashrc


# Documentation
# Please save the output of the following commands for documentation purposes:
tmsh show /sys hardware
tmsh show /sys software
tmsh show /sys license detail
tmsh list /sys provision all-properties one-line
tmsh list /net all-properties
tmsh list /sys management-ip all-properties one-line
tmsh show /cm device all
tmsh show /sys performance all-stats detail
tmsh show /sys performance all-stats historical
i #alias
ihealth -C -x all


# Archive
cat /var/spool/cron/root > /var/tmp/scripts/cron.txt
tmsh save /sys ucs `tmsh list /sys global-settings hostname | grep hostname | cut -d" " -f6` passphrase <\\'str_PASSPHRASE'\\>
# Backup /var/tmp/scripts/
# Please backup and document any additional scripts, external monitors, cli settings etc.
