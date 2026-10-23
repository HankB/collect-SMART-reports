#!/bin/bash

# Tests for drive-func.sh.

set -e
set -u


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR"

# shellcheck source=drive-func.sh
. ./drive-func.sh


fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}


assert_equals() {
    local expected=$1
    local actual=$2
    local description=$3

    if [[ "$expected" != "$actual" ]]; then
        fail "$description: expected <$expected>, got <$actual>"
    fi

    printf 'PASS: %s\n' "$description"
}


# Test parsing of an ordinary SATA device.
test_scan_sata() {
    local line="/dev/sda -d sat # /dev/sda [SAT], ATA device"

    assert_equals "/dev/sda" \
        "$(get_scan_device "$line")" \
        "parse SATA device"

    assert_equals "sat" \
        "$(get_scan_type "$line")" \
        "parse SATA device type"

    if is_megaraid_scan "sat"; then
        fail "sat incorrectly identified as MegaRAID"
    fi

    printf 'PASS: SATA device is not MegaRAID\n'
}


# Test parsing of a MegaRAID device.
test_scan_megaraid() {
    local line="/dev/bus/0 -d sat+megaraid,3 # /dev/bus/0 [megaraid_disk_03] [SAT], ATA device"

    assert_equals "/dev/bus/0" \
        "$(get_scan_device "$line")" \
        "parse MegaRAID device"

    assert_equals "sat+megaraid,3" \
        "$(get_scan_type "$line")" \
        "parse MegaRAID device type"

    if ! is_megaraid_scan "sat+megaraid,3"; then
        fail "sat+megaraid,3 not identified as MegaRAID"
    fi

    printf 'PASS: MegaRAID device recognized\n'
}


# Test a scan entry with no -d option.
test_scan_without_type() {
    local line="/dev/sda"

    assert_equals "/dev/sda" \
        "$(get_scan_device "$line")" \
        "parse device without type"

    assert_equals "" \
        "$(get_scan_type "$line")" \
        "empty type when -d is absent"
}


# Test get_drive_id() against the actual /dev/disk/by-id tree when
# possible.  This is deliberately a lightweight integration test.
test_existing_device_id() {
    local device
    local id

    for device in /dev/sda /dev/sdb /dev/nvme0n1; do
        if [[ -b "$device" ]]; then
            id=$(get_drive_id "$device")

            if [[ -z "$id" ]]; then
                fail "get_drive_id returned an empty ID for $device"
            fi

            printf 'PASS: get_drive_id %s -> %s\n' "$device" "$id"
            return 0
        fi
    done

    printf 'SKIP: no test block device available\n'
}


test_scan_sata
test_scan_megaraid
test_scan_without_type
test_existing_device_id

printf 'All tests passed.\n'
