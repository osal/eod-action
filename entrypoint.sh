#!/bin/sh -l

echo "Hello $1"
echo $(git version)
echo $(gh --version)
echo $(aws --version)
time=$(date)
echo "::set-output name=time::$time"
env
ls -lR
# TODO: get the list of changed/added files
# TODO: for each file get the range of changed bars
# TODO: for each file and range generate the patch
# TODO: for each file and range upload patch to S3 bucket
# TODO: for each file and range create a task definition
# TODO: send created tasks to SQS
