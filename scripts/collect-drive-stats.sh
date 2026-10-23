#!/usr/bin/env bash
# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset
############### end of Boilerplate

### Pull in drive stats from various hosts to a central location to
# 1. Make a copy on them should there be problems on the remote
# 2. Have them in a central location.
###

source_dir="/var/local/drive-stats/"
destination_dir="/var/local/drive-stats/"
hosts_file="/etc/drive-stats/hosts"

hosts="$(grep -v '^[[:space:]]*#' "$hosts_file")"


for i in $hosts
do
    mkdir -p "${destination_dir}${i}"
    if [ "$i" == "$HOSTNAME" ]
    then
        echo "linking drive stats for $i" ## no desire for rsync on local host
        for smart_report in ${destination_dir}*.SMART.txt
        do
            ln "${smart_report}" "${destination_dir}${i}/" || true # when already exist
        done
    else
        echo "pulling drive stats from $i"
        rsync --out-format='%n' --no-dirs --stats -z -lptgoD "${i}:${source_dir}*" "${destination_dir}${i}" \
            || true # 
    fi
done

