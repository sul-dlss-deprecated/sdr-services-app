#!/bin/bash

if [ "$1" != "" ]; then
	repo_path=$1
else
	repo_path='/services-disk/sdr2objects/druid /services-disk02/sdr2objects /services-disk03/sdr2objects /services-disk04/sdr2objects'
fi

DRUID_PATH_REGEX='[[:lower:]]{2}/[[:digit:]]{3}/[[:lower:]]{2}/[[:digit:]]{4}'
DRUID_FOLDER_REGEX='[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'

for disk in $repo_path ; do
        disk_name=$(echo $disk | sed s#^/## | sed s#/#_#g)
        echo "Searching $disk_name ..."
        # Find and save all the DRUID folders
        find $disk -type d | grep -E "$DRUID_PATH_REGEX" > ${disk_name}_druid_folders.txt
        # Report summary of DRUID counts
        grep -c -E "${DRUID_FOLDER_REGEX}$" ${disk_name}_druid_folders.txt
done

