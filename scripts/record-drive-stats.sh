#!/usr/bin/env bash
# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset
############### end of Boilerplate

# Capture drive statistics and save for historical reference.
#
# A report is saved as:
#
#   <unique ID>.<YYYY-MM-DD>.SMART.txt
#
# Device discovery is performed by smartctl --scan-open.  This allows
# smartctl to determine the appropriate device type, including USB,
# HBA, and MegaRAID devices.


umask 022 # files readable by ordinary user

PROGRAM=${0##*/}
DESTDIR="/var/local/drive-stats"
DATE_STAMP=$(date +%Y-%m-%d)
VERBOSE=false


usage() {
    cat <<EOF
Usage: $PROGRAM [OPTIONS]

Capture SMART reports for storage devices.

Options:
    -d, --directory DIR    Store reports in DIR. Default /var/local/drive-stats/
    -D, --device DEVICE    Process DEVICE instead of automatic discovery.
    -a, --all              Process all devices found by smartctl.
                          This is the default.
    -v, --verbose          Display additional information.
    -n, --dry-run          Show what would be done without collecting.
    -h, --help             Display this help.

Examples:
    $PROGRAM
    $PROGRAM --directory /srv/drive-stats
    $PROGRAM --device /dev/sda
    $PROGRAM --device /dev/nvme0n1
    $PROGRAM --directory /srv/drive-stats --all
EOF
}


log() {
    printf '%s\n' "$*"
}


verbose() {
    if [[ "$VERBOSE" == true ]]; then
        printf '%s\n' "$*"
    fi
}


die() {
    printf '%s: %s\n' "$PROGRAM" "$*" >&2
    exit 1
}


# Source external functions.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# shellcheck source=drive-func.sh
. "$SCRIPT_DIR/drive-func.sh" || exit 1


# Process one smartctl scan entry.
#
# The scan entry is passed intact so that both the device and the
# smartctl -d argument can be reconstructed.
process_scan_entry() {
    local scan_line=$1
    local device
    local device_type
    local report_id
    local filename
    local smartctl_rc

    device=$(get_scan_device "$scan_line")
    device_type=$(get_scan_type "$scan_line")

    if [[ -z "$device" ]]; then
        printf '%s: unable to parse scan entry: %s\n' \
            "$PROGRAM" "$scan_line" >&2
        return 1
    fi

    report_id=$(get_report_id "$device")

    filename="${DESTDIR}/${report_id}.${DATE_STAMP}.SMART.txt"

    if [[ -n "$device_type" ]]; then
        log "processing $device -d $device_type"
    else
        log "processing $device"
    fi

    verbose "  report: $filename"

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    if [[ -n "$device_type" ]]; then
        sudo smartctl -a -d "$device_type" "$device" \
            >"$filename" 2>&1
        smartctl_rc=$?
    else
        sudo smartctl -a "$device" \
            >"$filename" 2>&1
        smartctl_rc=$?
    fi

    if [[ $smartctl_rc -ne 0 ]]; then
        printf '%s: smartctl failed for %s (exit %d)\n' \
            "$PROGRAM" "$device" "$smartctl_rc" >&2
        return "$smartctl_rc"
    fi

    return 0
}


# Process an explicitly specified device.
#
# We let smartctl autodetect the device type.  This is intentionally
# separate from process_scan_entry(), because an explicit device is
# not necessarily one of the forms emitted by --scan-open.
process_explicit_device() {
    local device=$1
    local report_id
    local filename
    local smartctl_rc

    # Accept either /dev/sda or sda.
    if [[ "$device" != /dev/* ]]; then
        device="/dev/$device"
    fi

    if [[ ! -e "$device" ]]; then
        printf '%s: device does not exist: %s\n' \
            "$PROGRAM" "$device" >&2
        return 1
    fi

    report_id=$(get_report_id "$device")
    filename="${DESTDIR}/${report_id}.${DATE_STAMP}.SMART.txt"

    log "processing $device"
    verbose "  report: $filename"

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    sudo smartctl -a "$device" >"$filename" 2>&1
    smartctl_rc=$?

    if [[ $smartctl_rc -ne 0 ]]; then
        printf '%s: smartctl failed for %s (exit %d)\n' \
            "$PROGRAM" "$device" "$smartctl_rc" >&2
        return "$smartctl_rc"
    fi

    return 0
}


# Run automatic discovery.
#
# smartctl may report the same physical drive through more than one
# interface.  In particular, a MegaRAID controller may produce both:
#
#   /dev/sda -d sat
#   /dev/bus/0 -d sat+megaraid,1
#
# Prefer ordinary device paths.  MegaRAID entries are retained for
# devices which are not otherwise represented.
#
# We currently do this in two passes.  The first pass handles ordinary
# devices, and the second handles MegaRAID-only devices.  Physical-drive
# deduplication will be added once we have tested the scanner behavior
# on the target systems.
process_all_devices() {
    local scan_output
    local scan_line
    local device
    local device_type
    local rc=0

    scan_output=$(get_smartctl_scan)
    if [[ $? -ne 0 ]]; then
        printf '%s: smartctl --scan-open failed\n' "$PROGRAM" >&2
        return 1
    fi

    if [[ -z "$scan_output" ]]; then
        printf '%s: smartctl found no devices\n' "$PROGRAM" >&2
        return 1
    fi

    # First pass: ordinary device entries.
    while IFS= read -r scan_line; do
        [[ -z "$scan_line" ]] && continue

        device=$(get_scan_device "$scan_line")
        device_type=$(get_scan_type "$scan_line")

        if is_megaraid_scan "$device_type"; then
            continue
        fi

        process_scan_entry "$scan_line" || rc=1
    done <<< "$scan_output"

    # Second pass: MegaRAID entries.
    #
    # For the first iteration we intentionally do not collect these if
    # the same physical disks are already exposed as ordinary devices.
    # This behavior matches the observed dragohost configuration,
    # where every physical disk appears in both forms.
    #
    # If a future host exposes a MegaRAID disk only through /dev/bus/0,
    # we will add physical-drive identity/deduplication here.
    while IFS= read -r scan_line; do
        [[ -z "$scan_line" ]] && continue

        device_type=$(get_scan_type "$scan_line")

        if ! is_megaraid_scan "$device_type"; then
            continue
        fi

        verbose "skipping alternate MegaRAID path: $scan_line"
    done <<< "$scan_output"

    return "$rc"
}


# Defaults.
DRY_RUN=false
EXPLICIT_DEVICES=()


# Parse command line.
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            [[ $# -ge 2 ]] ||
                die "$1 requires an argument"
            DESTDIR=$2
            shift 2
            ;;

        -D|--device)
            [[ $# -ge 2 ]] ||
                die "$1 requires an argument"
            EXPLICIT_DEVICES+=("$2")
            shift 2
            ;;

        -a|--all)
            # Automatic discovery is the default.  Keep this option
            # for clarity and compatibility with scripts.
            shift
            ;;

        -v|--verbose)
            VERBOSE=true
            shift
            ;;

        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        --)
            shift
            while [[ $# -gt 0 ]]; do
                EXPLICIT_DEVICES+=("$1")
                shift
            done
            ;;

        -*)
            die "unknown option: $1 (use --help for usage)"

            ;;

        *)
            die "unexpected argument: $1 (use --help for usage)"
            ;;
    esac
done


# Validate destination.
if [[ ! -d "$DESTDIR" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        verbose "destination does not exist: $DESTDIR"
    else
        die "destination directory does not exist: $DESTDIR"
    fi
fi


# Explicit devices override automatic discovery.
if [[ ${#EXPLICIT_DEVICES[@]} -gt 0 ]]; then
    rc=0

    for device in "${EXPLICIT_DEVICES[@]}"; do
        process_explicit_device "$device" || rc=1
    done

    exit "$rc"
fi


process_all_devices
exit $?
