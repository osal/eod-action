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

[ -z "$CHANGED_DATA_FILES" ] && exit 0

# for each file get the range of changed bars
for F in $CHANGED_DATA_FILES; do
    echo processing file $F
    # !!! ugly, needs refactoring
    git diff --unified=0 $PREVIOUS_HASH..HEAD $F
    FIRST_LINE=$(git diff --unified=0 $PREVIOUS_HASH..HEAD $F | grep @@ | head -n1 | cut -f2 -d" "| cut -c2- | cut -f1 -d,)
    PATCH_FILE=$F.patch
    tail -n +$FIRST_LINE $F > $PATCH_FILE
    echo patch for $F
    cat $PATCH_FILE
done

for GROUP in $(ls data); 
do
    # check if there are patch files for the group
    PATCH_FILES=$(ls data/$GROUP/*.patch)
    [ -z "$PATCH_FILES" ] && continue
    # create a folder for archive
    ARCHIVE_FOLDER="archives/$GROUP,eod,$(date -u +%Y%m%dT%H%M%S),D,now-epoch,reg"
    mkdir -p $ARCHIVE_FOLDER
    for PATCH_FILE in $PATCH_FILES;
    do
        # copy patch files to the folder, adding a header
        LINES=$(wc -l $PATCH_FILE)
        ARCHIVE_PATCH_FILE=$(basename ${PATCH_FILE%".patch"})
        echo "# series; $LINES; c" > $ARCHIVE_FOLDER/$ARCHIVE_PATCH_FILE
        cat $PATCH_FILE >> $ARCHIVE_FOLDER/$ARCHIVE_PATCH_FILE
    done
    # TODO: upload archive to S3
    # TODO: create a task description for heater (JSON)
    # TODO: send task to heater
done

ls -lR archives
cd archives && zip -r ../patch.zip .
