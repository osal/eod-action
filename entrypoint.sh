#!/bin/sh -l

echo "Hello $1"
echo $(git version)
echo $(gh --version)
echo $(aws --version)
time=$(date)
echo "::set-output name=time::$time"
env
ls -lR
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_UDF}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_UDF}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION_UDF}
UDF_PATH=/usr/local/bin/udf
aws s3 cp ${UDF_RELEASE_BUCKET}/udf_r${UDF_RELEASE} ${UDF_PATH} --no-progress && chmod +x ${UDF_PATH}
udf version
# TODO: get the list of changed/added files
# TODO: for each file get the range of changed bars
# TODO: for each file and range generate the patch
# TODO: for each file and range upload patch to S3 bucket
# TODO: for each file and range create a task definition
# TODO: send created tasks to SQS
