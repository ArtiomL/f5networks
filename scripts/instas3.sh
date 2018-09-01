#!/bin/bash
# F5 Networks - Install Latest AS3 Package
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.3, 01/09/2018

# Download and unzip
cd /var/tmp/
curl -fLOs https://github.com/F5Networks/f5-appsvcs-extension/archive/master.zip
unzip -qqo master.zip
cd f5-appsvcs-extension-master/dist/

# Integrity verification
sha2Repo=$(cat f5-appsvcs-*.sha256.txt | awk '{print $1}')
strFile=$(cat f5-appsvcs-*.sha256.txt | awk '{print $2}')
sha2Real=$(sha256sum $strFile | awk '{print $1'})

# RPM install
if [ "$sha2Real" == "$sha2Repo" ] ; then
	mv $strFile /var/config/rest/downloads/
	strData="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$strFile\"}"
	restcurl -X POST "shared/iapp/package-management-tasks" -d $strData
fi

# Cleanup
rm -rf /var/tmp/master.zip /var/tmp/f5-appsvcs-extension-master/ /var/config/rest/downloads/$strFile
