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
    ARCHIVE_FOLDER="$GROUP,eod,$(date -u +%Y%m%dT%H%M%S),D,now-epoch,24x7,none"
    mkdir -p $ARCHIVE_FOLDER
    declare -a SYMBOLS
    for PATCH_FILE in $PATCH_FILES;
    do
        # copy patch files to the folder, adding a header
        LINES=$(cat $PATCH_FILE | wc -l)
        ARCHIVE_PATCH_FILE=$(basename ${PATCH_FILE%".patch"})
        echo "# series; $LINES; c" > $ARCHIVE_FOLDER/$ARCHIVE_PATCH_FILE
        cat $PATCH_FILE >> $ARCHIVE_FOLDER/$ARCHIVE_PATCH_FILE
        SYMBOLS+=(${ARCHIVE_PATCH_FILE%".csv"})
    done
    PATCH_ARCHIVE=$ARCHIVE_FOLDER.tar.gz
    tar -czvf $PATCH_ARCHIVE $ARCHIVE_FOLDER
    # TODO: upload archive to S3 bucket
    S3_COPY_CMD="aws s3 cp \"${PATCH_ARCHIVE}\" \"${HEATER_BUCKET}/${PATCH_ARCHIVE}\""
    echo copy command: $S3_COPY_CMD
    SYMBOL_PARAM=$( IFS=$','; echo "${SYMBOLS[*]}" )
    HEATER_SEND_CMD="udf heater send --task-queue-name hub-heater-tasks-dev2.fifo \
    --type=Put --get=archive \
    --source=$PATCH_ARCHIVE \
    -g=$GROUP -s=$SYMBOL_PARAM -r=D --session=24x7 --task-name=upload-eod-data-for-$GROUP --log -"
    # TODO: send task to heater
    echo heater command: $HEATER_SEND_CMD
done

ls -l *.tar.gz

