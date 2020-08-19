#!/bin/bash

#
# s3publish.sh
#
# This simple script uploads a file to a given S3 bucket and returns a
# presigned URL, that can be easily shared with peers while keping the file
# secure.
#
# Usage:
#
#	s3publish.sh -b <BUCKET_NAME> -f <FILE_PATH> [-d <DAYS_TO_EXPIRATION>] [-p <SIGNING_PROFILE>]
#

set -euo pipefail

BUCKET=''
DAYS=''
FILE=''
PROFILE=''

while getopts "b:d:f:p:" opt; do
	case ${opt} in
		b)
			BUCKET=$OPTARG
			;;
		d)
			DAYS=$OPTARG
			;;
		f)
			FILE=$OPTARG
			;;
		p)
			PROFILE=$OPTARG
			;;
		\?)
			echo "Usage: s3publish -b <bucket>" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

if [ -z $BUCKET ]; then
	echo "Please provide the target bucket" >&2
	exit 1
fi

if [ -z $FILE ]; then
	echo "Please provide the path to the file to be uploaded" >&2
	exit 1
fi

re='^[0-9]+$'
if [ -z $DAYS ]; then
	echo "No expiration days provided, defaulting to 7 days" >&2
	DAYS=7
elif ! [[ $DAYS =~ $re ]] ; then
   echo "Days must be an integer" >&2
   exit 1
fi

if [ -z $PROFILE ]; then
	echo "No profile provided, will use default profile as configured in current environment" >&2
fi

TIME=$(( DAYS * 86400 ))

# Determine the region where the bucket resides, as we'll need this when
# generating the pre-signed URL. (If we use the wrong region, the URL will
# reply with a permanent redirect, but no redirect can actually be followed.)
#
# GetBucketLocation returns null for us-east-1 (N. Virginia). We need to
# account for this.
REGION=$(aws s3api get-bucket-location --bucket "$BUCKET" | jq -r '.LocationConstraint // "us-east-1"')
echo "Bucket '$BUCKET' seems to be located in '$REGION'" >&2

TARGET=$(aws s3 --region "$REGION" cp "$FILE" "s3://$BUCKET/" | sed -n -e 's/^.*\(s3:\/\/.*\)/\1/p')

if [ -z $PROFILE ]; then
	SIGNED_URL=$(aws --region "$REGION" s3 presign --expires-in "$TIME" "$TARGET")
else
	SIGNED_URL=$(aws --region "$REGION" --profile "$PROFILE" s3 presign --expires-in "$TIME" "$TARGET")
fi

echo "$SIGNED_URL"
