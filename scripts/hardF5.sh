#!/bin/bash
# F5 Networks - BIG-IP Hardening Guide
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v2.1.0, 29/10/2017


# System Account Passwords
tmsh modify /auth password root
tmsh modify /auth user admin prompt-for-password
tmsh modify /sys db systemauth.disablerootlogin value true 	#Warning! Disables root login!
	# userdel admin 	#Warning! Disables admin! Create an alternative administrative user first!
tmsh modify /sys db users.strictpasswords value enable
tmsh modify /auth password-policy minimum-length 13 required-lowercase 3 required-numeric 3 required-special 2 required-uppercase 3
tmsh modify /auth password-policy policy-enforcement enabled


# System Preferences
tmsh modify /sys db ui.system.preferences.advancedselection value advanced
tmsh modify /sys db ui.system.preferences.recordsperscreen value 100


# Naming Conventions and Defaults
echo "Please choose and use a consistent naming convention across all configuration objects: pool_HTTP_APACHE, mon_HTTP_HEAD, prof_HTTP_XFF, virt_EXAMPLE.COM_80 etc."
echo "Additionally, please avoid using the default settings (e.g. monitors, profiles, methods, certificates etc.) except where intentionally needed."
mkdir /var/tmp/scripts/ 	#Put all your shell scripts here


# NTP
tmsh modify /sys ntp servers replace-all-with { <\\'addr_NTP1_IP'\\> <\\'addr_NTP2_IP'\\> } timezone Israel


# DNS
tmsh modify /sys dns name-servers replace-all-with { <\\'addr_DNS1_IP'\\> <\\'addr_DNS2_IP'\\> } search replace-all-with { <\\'str_DOMAIN1'\\> <\\'str_DOMAIN2'\\> }


# AFM
tmsh create /security firewall rule-list afm_rl_DROP_UDP { rules add { afm_rule_DROP_UDP { action drop ip-protocol udp place-after first } } }


# TCP Profiles
tmsh create /ltm profile tcp prof_F5_TCP_WAN_DDOS defaults-from f5-tcp-wan deferred-accept enabled syn-cookie-enable enabled zero-window-timeout 10000 idle-timeout 180 reset-on-timeout disabled
tmsh modify /sys db tm.maxrejectrate value 100
tmsh modify /ltm global-settings traffic-control reject-unmatched disabled
tmsh modify /ltm global-settings connection vlan-keyed-conn enabled 	#Default


# HTTP Profiles
tmsh modify /ltm profile http http server-agent-name aws
tmsh modify /ltm profile http http hsts { mode enabled } 	#Disable for HTTP Virtual Servers (New Child Profile)
# Designate a Login-Wall with ASM (Sessions and Logins > Login Enforcement) or an iRule:
# https://devcentral.f5.com/wiki/iRules.Simple-Login-Wall-iRule-Redirect-unauthenticated-users-back-to-login-page.ashx


# SSL Profiles
tmsh create /ltm profile client-ssl clientssl-hard secure-renegotiation require-strict
tmsh modify /ltm profile client-ssl clientssl-hard max-renegotiations-per-minute 3	#11.6 and on
tmsh modify /ltm profile client-ssl clientssl-hard ciphers 'NATIVE:!NULL:!LOW:!EXPORT:!RC4:!DES:!3DES:!ADH:!DHE:!EDH:!MD5:!SSLv2:!SSLv3:!DTLSv1:@STRENGTH'
tmsh modify /ltm profile client-ssl clientssl-hard options { dont-insert-empty-fragments no-dtls no-ssl }


# Persistence Profiles
tmsh modify /ltm persistence cookie cookie cookie-name "`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10`"


# Virtual Servers
echo "F5 recommends the use of Full Proxy (Standard) Virtual Servers when DDoS is a concern."
	# profiles: prof_TCP-WAN-OPT-DDOS { context clientside }, tcp-lan-optimized { context serverside }
tmsh modify /ltm virtual <\\'vs_NAME'\\> description <\\'vs_DESCRIPTION'\\>
tmsh modify /ltm virtual <\\'vs_NAME'\\> source-address-translation { type snat pool <\\'pool_SNAT'\\> }	#Use SNAT Pools to avoid Port Exhaustion
tmsh modify /ltm virtual <\\'vs_NAME'\\> vlans-enabled vlans replace-all-with { <\\'vlan_NAME'\\> }


# Network
tmsh modify /net self all allow-service none


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
#Use the following configuration for off-box logging:
tmsh create /ltm pool pool_HSL members add { <\\'addr_SYSLOG_IP'\\>:514 }
tmsh create /sys log-config destination remote-high-speed-log logd_HSL { protocol udp pool-name pool_HSL }
tmsh create /sys log-config destination remote-syslog logd_FORMAT_SYSLOG { format rfc5424 remote-high-speed-log logd_HSL }
tmsh create /sys log-config publisher logp_HSL { destinations replace-all-with { logd_HSL logd_FORMAT_SYSLOG } }
tmsh create /sys log-config filter logf_HSL { level info source all publisher logp_HSL }


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
echo "Please save the output of the following commands for documentation purposes:"
tmsh show /sys hardware
tmsh show /sys software
tmsh show /sys license detail
tmsh list /sys provision all-properties one-line
tmsh list /net all-properties
tmsh list /sys management-ip all-properties one-line
tmsh show /cm device all
tmsh show /sys performance all-stats historical
i #alias


# Archive
cat /var/spool/cron/root > /var/tmp/scripts/cron.txt
tmsh save /sys ucs `tmsh list /sys global-settings hostname | grep hostname | cut -d" " -f6` passphrase <\\'str_PASSPHRASE'\\>
echo "Please backup and document any additional scripts, external monitors, cli settings etc." 	#Backup /var/tmp/scripts/
