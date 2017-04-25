#!/bin/bash
# F5 Networks - CRL Auto-Update
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v3.3, 09/11/2016

# Add to cron and /config/failover/active on both systems in DSC

str_HA_STATUS=$(tmsh show /sys failover | cut -d" " -f2)
if [ "$str_HA_STATUS" == "standby" ] ; then
	exit 1
fi

cd /shared/tmp/scripts/
str_DG_URLS="dg_CRL_CURL"
str_SSL_CRL="crl_COMBINED_CAs"
str_DSC_DG="dg_HA"

tmsh list /ltm data-group internal $str_DG_URLS | grep http | awk -F'[<>]' '{print $2}' > crlist.txt
>new.crl
echo -ne "\nCRL Auto-Update Script Log: " > logs/autocrl.log
date >> logs/autocrl.log

while read par; do
	curl -o nget.unk -f -s -g $par > /dev/null
	if [ $? -eq 0 ]; then
		head -1 nget.unk | grep 'BEGIN X509 CRL' > /dev/null
		if [ $? != 0 ]; then
			openssl crl -inform DER -in nget.unk -out nget.crl
			echo -n "DER" >> logs/autocrl.log
		else
			cat nget.unk > nget.crl
			echo -n "PEM" >> logs/autocrl.log
		fi
		cat nget.crl >> new.crl
		openssl crl -inform PEM -in nget.crl -text | grep "Issuer\|date" | sed "s/\(Last\|Next\)/      \1/" >> logs/autocrl.log
	fi
done <crlist.txt

sha1_CUR=$(tmsh list /sys file ssl-crl "$str_SSL_CRL.crl" | grep SHA1 | cut -d":" -f3)
sha1_NEW=$(sha1sum new.crl | cut -d" " -f1)

if [ "$sha1_CUR" != "$sha1_NEW" ] ; then
	str_CS_STATUS=$(tmsh show /cm sync-status | grep "^Status" | awk '{print $2$3}')
	tmsh modify /sys file ssl-crl "$str_SSL_CRL.crl" source-path file:new.crl
	tmsh save /sys config partitions all >> logs/autocrl.log
	str_LOG_LINE="autocrl.sh - New CRL version detected. The CRL file was updated."
	if [ "$str_CS_STATUS" == "InSync" ] ; then
		ip_MGMT=$(tmsh list /sys management-ip one-line | awk -F'[ /]' '{print $3}')
		int_MGMT_CONS=$(netstat -np | grep "sshd\|httpd" | grep $ip_MGMT | wc -l)
		if [ $int_MGMT_CONS -eq 0 ]; then
			tmsh run /cm config-sync to-group $str_DSC_DG
			str_LOG_LINE="$str_LOG_LINE Config Synced."
		fi
	fi
else
	str_LOG_LINE="autocrl.sh - The CRL version has not changed."
fi

logger -p local0.info "$str_LOG_LINE"
echo -e "$str_LOG_LINE\n" >> logs/autocrl.log

rm -f nget.unk
rm -f nget.crl
rm -f new.crl
rm -f crlist.txt
