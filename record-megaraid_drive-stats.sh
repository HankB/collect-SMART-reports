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
# first version of the script will
#  - store files in the directory where launched
#  - ignore nvme drives (not in /dev/sd?)
#  - not handle special arguments required by smartmontools (RAID)

# installation and usage
# sudo cp record-drive-stats.sh drive-func.sh /usr/local/sbin
# command line
# record-drive-stats.sh /path/to/storage
# cron
# 15 21 * * * /usr/local/sbin/record-drive-stats.sh /srv/drive-stats  >/tmp/SMART-stats.log 2>&1
# source external code

# modified from recored_drive_stats.sh to handle drives part of a RAID on a megaraid card.
# Format of smartctl command is 
# smartctl -a -d megaraid,nn  /dev/sda
# where 'nn; is some index that identifies the particular drive'
# for the present configuration IDs are 19 20 23 24
# For the stuff on olive, the invocation will be [-m|--megaraid] sda,19,20,23,24

# Bring in some functions
. `dirname $0`/drive-func.sh || exit 1

# read command line options
TEMP=`getopt -n $0 -o m: --long megaraid: -- "$@"`
# echo rc $? TEMP  "$TEMP"
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -m|--megaraid)
            megaraid_numbers=$2 ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [ "" != "$megaraid_numbers" ]; then
    DEV=`echo $megaraid_numbers | awk '{split($0, a, ","); print a[1];}'`
    DRIVES=`echo $megaraid_numbers | awk '{split($0, a, ",");  \
            for (i=2; i<=length(a); i++) print a[i];}'`
else
    echo "provide arguments like '-m sda,18,19,23,24 '"
    exit 1
fi

if [ $# -eq 1 ] ; then
  DESTDIR=$1
else
  DESTDIR=`pwd`
fi
DATE_STAMP=`date +%Y-%m-%d`

cd /dev
for i in $DRIVES
do
  echo processing /dev/${DEV},$i
  DISK_ID=`get_drive_id ${DEV}`
  echo $DISK_ID
  FILENAME="${DESTDIR}/${DISK_ID}_${i}.${DATE_STAMP}.SMART.txt"
  echo ${FILENAME} 
  sudo smartctl -a -d megaraid,${i} /dev/$DEV\
      >${FILENAME} 2>&1
done
