#!/bin/bash

# Capture drive statistics and save for historical reference
# save file will be <unique ID>.YYYY-MM-DD.SMART.txt
# The file will be highly compressible but intent is to store to a
# filesystem that compresses so will be convenient to store uncompressed
#
# Unique ID will be the first entry in /dev/disk/by-id/ that matches the
# device descriptor in /dev/sd?. (Note: this will only identify the first
# 26 drives on the system. Not an issue for me.
#
# This version of the script will
#  - store files in the directory where launched
#  - handle SSD/HDD and/or nvme drives (anything matching /dev/sd? and /dev/nvme0n?)
#  - not handle special arguments required by smartmontools (RAID)

# installation and usage
# sudo cp record-drive-stats.sh drive-func.sh /usr/local/sbin
# command line
# record-drive-stats.sh /path/to/storage
# cron
# 15 21 * * * /usr/local/sbin/record-drive-stats.sh /srv/drive-stats  >/tmp/SMART-stats.log 2>&1
# source external code
. `dirname $0`/drive-func.sh || exit 1

if [ $# -eq 1 ] ; then
  DESTDIR=$1
else
  DESTDIR=`pwd`
fi
DATE_STAMP=`date +%Y-%m-%d`

cd /dev
for i in `echo sd? nvme0n?`
do
  if [ "$i" != 'sd?' ] && [ "$i" != 'nvme0n?' ]
  then
    echo processing $i
    DISK_ID=`get_drive_id $i`
    echo $DISK_ID
    FILENAME="${DESTDIR}/${DISK_ID}.${DATE_STAMP}.SMART.txt"
    echo ${FILENAME} 
    sudo smartctl -a /dev/disk/by-id/${DISK_ID} \
        >${FILENAME} 2>&1
  fi
done
