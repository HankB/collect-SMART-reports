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
# record-drive-stats.sh # default path to storage, all drives /dev/sd? and /dev/nvme0m?
# record-drive-stats.sh /path/to/storage # specify path to storage, all drives
# record-drive-stats.sh /path/to/storage sdX sdY ... sdN # specify path and drives 

# typical cron
# 15 21 * * * /usr/local/sbin/record-drive-stats.sh /srv/drive-stats  >/tmp/SMART-stats.log 2>&1

# source external code
. `dirname $0`/drive-func.sh || exit 1

DATE_STAMP=`date +%Y-%m-%d`

if [ $# -ge 1 ] ; then
  DESTDIR=$1
  shift
else
  DESTDIR=`pwd`
fi

# function to store SMART report in a disk file.
process_drive() {
  drive=$1 # e.g. sda, nvme0n1 etc.
  DISK_ID=`get_drive_id $i`
  echo "processing $i - /dev/disk/by-id/$DISK_ID"
  FILENAME="${DESTDIR}/${DISK_ID}.${DATE_STAMP}.SMART.txt"
    sudo smartctl -a /dev/disk/by-id/${DISK_ID} \
        >${FILENAME} 2>&1
}


if [ $# -ge 1 ] ; then
  for i in "$@"
  do
    process_drive "$i"
  done
else
  cd /dev
  for i in `echo sd? nvme0n?`
  do
    if [ "$i" != 'sd?' ] && [ "$i" != 'nvme0n?' ]
    then
      process_drive "$i"
    fi
  done
fi