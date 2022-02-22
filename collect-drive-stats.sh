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
destination_dir="/srvpool/srv/drive-stats/" # to which the hostname will be appended.
hosts="$(grep -v "^#" < $destination_dir/hosts)"

for i in $hosts
do
    echo "pulling drive stats from $i"
    mkdir -p "${destination_dir}${i}"
    rsync --out-format='%n' --stats -az "${i}:${source_dir}*" "${destination_dir}${i}"
done

