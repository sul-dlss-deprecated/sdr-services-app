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

tmp_file="/tmp/sdr_app_tmp_$$.log"

regex_ip='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'

#regex_druid='[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}'
regex_druid='[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'

for f in ${LOG_FILES}; do
    echo -e "\n\n********************************************************************************"
    echo -e "LOGS on $today for $f\n"
    grep "$today" ${f} > ${tmp_file}
    if [ -s ${tmp_file} ]; then
        echo "HOST IPs today:"
        for ip in $(cat ${tmp_file} | sed -n -r -e "s/(${regex_ip}).*/\1/p" | sort -u); do
            name=$(nslookup ${ip} | grep name | sed -e 's/.*name = //')
            echo "$ip  $name"
        done
        # Stats on DRUIDS
        cat ${tmp_file} | sed -n -r -e "/$regex_druid/s/.*($regex_druid).*/\1/p" | sort -u > /tmp/sdr_app_druids.log
        druid_count=$(cat /tmp/sdr_app_druids.log | wc -l)
        echo
        echo "DRUID count: $druid_count"
        echo
        echo "Log tail:"
        tail -n${tailN} ${tmp_file}
        echo
    else
        echo
        echo "No activity today; latest activity was:"
        echo
        tail -n${tailN} ${f}
    fi
done

rm /tmp/sdr_app*
echo
echo

