#!/bin/bash
# F5 Networks - Upload Files to an Amazon S3 Bucket
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.1, 31/07/2018

trap "echo; echo 'Exiting...'; exit" SIGINT

if [ "$#" -ne 2 ]; then
	echo; echo "Usage: ./s3put {BUCKET_NAME}[/PATH] {FILE_TO_UPLOAD} [REGION]"; echo
	exit
fi

HMAC-SHA256s() {
	KEY="$1"
	DATA="$2"
	shift 2
	printf "$DATA" | openssl dgst -binary -sha256 -hmac "$KEY" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//'
}

HMAC-SHA256h() {
	KEY="$1"
	DATA="$2"
	shift 2
	printf "$DATA" | openssl dgst -binary -sha256 -mac HMAC -macopt "hexkey:$KEY" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//'
}

AWS_ACCESS_KEY=${AWS_ACCESS_KEY_ID?}
AWS_SECRET_KEY=${AWS_SECRET_ACCESS_KEY?}

FILE_TO_UPLOAD="$2"
BUCKET=$(echo "$1" | cut -d'/' -f1)
DPATH=$(echo "$1" | cut -d'/' -f2 -s)
STARTS_WITH="$DPATH/$FILE_TO_UPLOAD"
