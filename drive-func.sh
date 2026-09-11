#!/bin/bash

# Functions used by record-drive-stats.sh

# Return the output of smartctl device discovery.
get_smartctl_scan()
{
    sudo smartctl --scan-open
}

# Extract the device name from a smartctl --scan-open line.
#
# Example:
#   /dev/sda -d sat
# becomes:
#   /dev/sda
get_scan_device()
{
    echo "$1" | awk '{print $1}'
}

# Extract the device type from a smartctl --scan-open line.
#
# Example:
#   /dev/sda -d sat
# becomes:
#   sat
#
# If no -d option is present, return an empty string.
get_scan_type()
{
    echo "$1" | awk '
        $2 == "-d" { print $3; exit }
    '
}

# Return true if a smartctl scan entry uses a MegaRAID device type.
is_megaraid_scan()
{
    case "$1" in
        *megaraid*) return 0 ;;
        *)          return 1 ;;
    esac
}

# Return the persistent ID associated with a device.
#
# For ordinary block devices, look for a persistent /dev/disk/by-id
# symlink pointing at the device.
#
# NVMe is slightly different: smartctl --scan-open reports the controller
# (/dev/nvme0), while /dev/disk/by-id points to its namespace
# (/dev/nvme0n1). Resolve the controller to its first namespace before
# looking for the persistent ID.
#
# For NVMe, prefer the human-readable nvme-<model>_<serial> identifier
# over the nvme-eui.* identifier.
get_drive_id()
{
    if [ "$#" -ne 1 ]; then
        (>&2 echo "usage: get_drive_id /dev/???")
        return 1
    fi

    local device=$1
    local target_device=$device
    local link
    local link_target
    local id
    local nvme_eui_id=""

    # smartctl reports NVMe controllers (/dev/nvme0), but persistent
    # by-id links point to namespaces (/dev/nvme0n1).
    case "$device" in
        /dev/nvme[0-9])
            for link in /dev/"$(basename "$device")"n[0-9]*; do
                if [ -e "$link" ]; then
                    target_device=$link
                    break
                fi
            done
            ;;
    esac

    # Examine persistent by-id links.
    #
    # We deliberately make the identifier selection deterministic rather
    # than depending on the directory ordering returned by the shell.
    for link in /dev/disk/by-id/*; do
        [ -L "$link" ] || continue

        case "$(basename "$link")" in
            *-part[0-9]*)
                continue
                ;;
            *_1)
                continue
                ;;
        esac

        link_target=$(readlink -f "$link") || continue

        if [ "$link_target" != "$target_device" ]; then
            continue
        fi

        id=$(basename "$link")

        case "$id" in
            nvme-eui.*)
                # Save the EUI identifier in case no nvme-* identifier
                # is available.
                nvme_eui_id=$id
                ;;
            nvme-*)
                # Prefer the model/serial identifier.
                echo "$id"
                return 0
                ;;
            ata-*|wwn-*)
                echo "$id"
                return 0
                ;;
        esac
    done
        
    if [ -n "$nvme_eui_id" ]; then
        echo "$nvme_eui_id"
        return 0
    fi

    # If no persistent ID was found, retain the original device name.
    basename "$device"
}

# Return the identifier used for the SMART report filename.
#
# Keep this as a separate function so report naming can evolve without
# changing the underlying device-identification function.
get_report_id()
{
    get_drive_id "$1"
}
