#!/bin/bash
# F5 Networks - Register Azure RM AD App for OAuth2 API Access
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.0, 06/09/2018

if [ -z "$1" ]; then
	echo; echo "Usage: ./ad_spn.sh {SUBSCRIPTION_NAME|SUBSCRIPTION_ID}"; echo
	exit
fi

az login

echo "List of subscriptions for the logged in account:"
az account list

echo "Setting active subscription: $1"
az account set --subscription="$1"

echo "Creating a service principal..."
strSubID=$(az account show | jq -r '.id')
strApp=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$strSubID")

echo "ARM_SUBSCRIPTION_ID=$strSubID"
echo "ARM_CLIENT_ID=$(jq -r '.appId' <<< $strApp)"
echo "ARM_CLIENT_SECRET=$(jq -r '.password' <<< $strApp)"
echo "ARM_TENANT_ID=$(jq -r '.tenant' <<< $strApp)"
