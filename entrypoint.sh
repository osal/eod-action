#!/bin/sh -l

set -x

echo $(git version)
echo $(gh --version)
echo $(aws --version)
echo $(jq --version)

# download udf utility
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_UDF}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_UDF}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION_UDF}
UDF_PATH=/usr/local/bin/udf
aws s3 cp ${UDF_RELEASE_BUCKET}/udf_r${UDF_RELEASE} ${UDF_PATH} --no-progress && chmod +x ${UDF_PATH}
echo udf info: $(udf version)

# get the list of changed/added CSV files
PREVIOUS_HASH=$(cat $GITHUB_EVENT_PATH | jq .before | sed 's/"//g')
git pull --unshallow
CHANGED_DATA_FILES=$(git diff --name-only --diff-filter=AM $PREVIOUS_HASH..HEAD | grep csv)
# for each file get the range of changed bars
for F in $CHANGED_DATA_FILES; do
    echo processing file $F
    FIRST_LINE=$(git diff --unified=0 $PREVIOUS_HASH..HEAD $F | grep @@ | head -n1 | cut -f2 -d" "| cut -c2-)
    PATCH_FILE=$F.patch
    tail -n +$FIRST_LINE $F > $PATCH_FILE
    echo patch for $F
    cat $PATCH_FILE
    # TODO: generate the patch
    # TODO: upload patch to S3 bucket
    # TODO: create a task definition
    # TODO: send created tasks to SQS
done




