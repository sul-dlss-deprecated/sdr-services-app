#!/bin/bash

if [ "$1" != "" ]; then
    tailN=$1
else
    tailN=40
fi

cd

LOG_PATH="${HOME}/sdr-services-app/shared/log"
LOG_FILES="${LOG_PATH}/sdr.log"

today=$(date +%d/%b/%Y)

for f in ${LOG_FILES}; do
    echo -e "\n\n********************************************************************************"
    echo -e "ERRORS on $today for $f\n"
    grep "$today" ${f} | grep -v 'ObjectNotFoundException' | grep -B1 -A2 'ERROR.*message'
done
echo
echo

