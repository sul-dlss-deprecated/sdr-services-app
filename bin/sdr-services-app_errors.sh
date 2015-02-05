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

regex_ip='s/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/'

#regex_druid='[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'
regex_druid='[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}'

for f in $LOG_FILES; do
	echo -e "\n\n********************************************************************************"
	echo -e "ERRORS on $today for $f\n"
	grep "$today" $f | grep -v 'ObjectNotFoundException' | grep -B1 -A2 'ERROR.*message'
done
echo
echo

