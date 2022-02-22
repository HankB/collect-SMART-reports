#!/bin/bash

# Rudimentary (and later more automated) tests of drive-func.sh
# 
# run automated tests for no arguments.
# run rudimentary tests with arguments provided
# One useful test non-automated test is
# ./drive-func-test.sh $(cd /dev; echo sd?; echo sdx)
# which should ID all drives on a host (or at least the first 26)
# and one possibly non-existant drive

# exit on all errors
set -e
# undefined symbols are errors
set -u

# Source functions to test
. ./drive-func.sh



main() {
    for i in $* ; do
        echo For $i
        get_drive_id $i
    done
}

# Run main when arguments are provided, otherwise automated tests
if [ $# -ge 1 ] ; then
    main $*
else
    # mock get_file_list()
    get_file_list() {
    cat <<EOF
total 0
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-ST240HM000-1G5152_Z4N00RM1 -> ../../sdg
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-ST240HM000-1G5152_Z4N00RM1-part1 -> ../../sdg1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-ST240HM000-1G5152_Z4N00RM1-part2 -> ../../sdg2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2002FYPS-02W3B0_WD-WCAVY7272361 -> ../../sde
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2002FYPS-02W3B0_WD-WCAVY7272361-part1 -> ../../sde1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2002FYPS-02W3B0_WD-WCAVY7272361-part2 -> ../../sde2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY5836470 -> ../../sdd
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY5836470-part1 -> ../../sdd1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY5836470-part2 -> ../../sdd2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6142663 -> ../../sdc
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6142663-part1 -> ../../sdc1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6142663-part2 -> ../../sdc2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6148882 -> ../../sda
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6148882-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6148882-part2 -> ../../sda2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6466521 -> ../../sdb
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6466521-part1 -> ../../sdb1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6466521-part2 -> ../../sdb2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY7294152 -> ../../sdf
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY7294152-part1 -> ../../sdf1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY7294152-part2 -> ../../sdf2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x5000c5002ff22a4c -> ../../sdg
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x5000c5002ff22a4c-part1 -> ../../sdg1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x5000c5002ff22a4c-part2 -> ../../sdg2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee2052f74a0 -> ../../sdc
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2052f74a0-part1 -> ../../sdc1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2052f74a0-part2 -> ../../sdc2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee2056320c0 -> ../../sdb
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2056320c0-part1 -> ../../sdb1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2056320c0-part2 -> ../../sdb2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee2061d6639 -> ../../sdf
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2061d6639-part1 -> ../../sdf1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2061d6639-part2 -> ../../sdf2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee25b714e7c -> ../../sde
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee25b714e7c-part1 -> ../../sde1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee25b714e7c-part2 -> ../../sde2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee2afc04a72 -> ../../sdd
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2afc04a72-part1 -> ../../sdd1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2afc04a72-part2 -> ../../sdd2
lrwxrwxrwx 1 root root  9 Mar  1 10:46 wwn-0x50014ee2afdae114 -> ../../sda
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2afdae114-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Mar  1 10:46 wwn-0x50014ee2afdae114-part2 -> ../../sda2
EOF
    }

    # test ID for existing drive
    test_ID_existing_drive() {
        ID=`get_drive_id sda`
        assertEquals "did not find ID for sda" "$ID"\
            "ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6148882"

        ID=`get_drive_id sdb`
        assertEquals "did not find ID for sda" "$ID"\
            "ata-WDC_WD2003FYPS-27Y2B0_WD-WCAVY6466521"

        ID=`get_drive_id sdg`
        assertEquals "did not find ID for sda" "$ID"\
            "ata-ST240HM000-1G5152_Z4N00RM1"
        ID=`get_drive_id sdg`
        assertEquals "did not find ID for sda" "$ID"\
            "ata-ST240HM000-1G5152_Z4N00RM1"
    }

    # test ID for existing drive
    test_ID_non_existing_drive() {
        ID=`get_drive_id sdx`
        assertEquals "did not find ID for sdx" "$ID"\
            "sdx"
    }

    # Load shUnit2.
    . shunit2
fi