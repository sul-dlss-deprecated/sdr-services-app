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
	echo -e "LOGS on $today for $f\n"
	#tail -n$tailN $f
	grep "$today" $f > /tmp/sdr_app_tmp.log
	echo "HOST IPs today:"
	for ip in $(grep -v "ERROR" /tmp/sdr_app_tmp.log | sed -r -e "$regex_ip" | sort -u); do
		name=$(nslookup $ip | grep name | sed -e 's/.*name = //')
		echo "$ip  $name"
	done
	# Stats on DRUIDS
	grep -v "ERROR" /tmp/sdr_app_tmp.log | sed -r -e "/$regex_druid/s/.*($regex_druid).*/\1/" | sort -u > /tmp/sdr_app_druids.log
	druid_count=$(cat /tmp/sdr_app_druids.log | wc -l)
	echo
	echo "DRUID count: $druid_count"
	echo
	echo "Log tail:"
	tail -n$tailN /tmp/sdr_app_tmp.log
	echo
done

rm /tmp/sdr_app_*.log
echo
echo

