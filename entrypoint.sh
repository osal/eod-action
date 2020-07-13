#!/bin/sh -l

set -x

echo $(git version)
echo $(gh --version)
echo $(aws --version)
echo $(jq --version)

env
ls -lR

# download udf utility
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_UDF}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_UDF}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION_UDF}
UDF_PATH=/usr/local/bin/udf
aws s3 cp ${UDF_RELEASE_BUCKET}/udf_r${UDF_RELEASE} ${UDF_PATH} --no-progress && chmod +x ${UDF_PATH}
echo udf info: $(udf version)

# get the list of changed/added CSV files
git log | head
git status
BEFORE_HASH=$(cat $GITHUB_EVENT_PATH | jq .before)
git fetch $BEFORE_HASH
CHANGED_DATA_FILES=$(git diff --name-only $BEFORE_HASH | grep csv)
echo $CHANGED_DATA_FILES
# TODO: for each file get the range of changed bars
# TODO: for each file and range generate the patch
# TODO: for each file and range upload patch to S3 bucket
# TODO: for each file and range create a task definition
# TODO: send created tasks to SQS
