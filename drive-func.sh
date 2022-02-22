# Various functions related to system drives.
# Hopefully written in a testable way.
# see also drive-func-test.sh

# function to read directory and return results. Can be mocked 
# for unit testing
get_file_list() {
    ls $*
}

# Fetch a drive identifier given the /dev entry (e.g. for /dev/sda
# use sda)
# Some systems list the drive more than once in /dev/disk/by-id
# and the first will be returned. If none are found, the argument
# passed in will be returned.
# return value is by writing the result to STDOUT.


get_drive_id() {
    if [ $# -ne 1 ] ; then
        (>&2 echo "usage get_drive_id /dev/???")
        exit 1
    fi
    ID=`(get_file_list -l /dev/disk/by-id) | grep -v -- -part|grep $1 \
    | awk '{print $9;}' | head -1 `
    if [ "$ID" = "" ] ; then
        echo $1
    else
        echo $ID
    fi
}
