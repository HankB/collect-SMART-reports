# collect-SMART-reports

Collect SMART drive reports to a central location. Happens in two steps.

1. Individual hosts execute `record-drive-stats.sh` to capture SMART reports.
1. Some host collects the stats to a central location.

By convention, drive stats are stored locally in `/var/local/drive-stats` and collected centrally in `/var/local/drive-stats` (and perhaps in the future, in `/var/local/drive-stats/<hostname>`.)

## Motivation

Drives go bad. Taking a snapshot of the SMART data describes only part of the condition. It is useful to know about changes in status over time and this package collects the SMART reports on a periodic basis so they can be examined for trends. Perhaps someday this can be automated.

## Requirements

* Linux. Will probably run on BSD too. No idea about Windows or Mac OS.

## Usage

* Copy `record-drive-stats.sh` and `drive-func.sh` to some convenient location. (e.g. `/usr/local/sbin`)
* Create a root cron entry such as

```text
13 15 * * 5  /usr/local/sbin/record-drive-stats.sh /var/local/drive-stats/  >/tmp/SMART-stats.log 2>&1
```

* Copy `collect-drive-stats.sh` to some convenient location on the host which will collect the reports from various hosts.

At present `record-drive-stats.sh` accepts arguments on the command line 

* First arg (if provided) is the location to which the reports will be saved. Default is `/var/local/drive-stats`.
* Second and subsequent arguments are the drives to be reported as their entries in `/dev/` (e.g. `sda` or `nvme0n1` etc.) Default is to report all drives found by `/dev/sd?` and `/dev/nvme0n?`. In order to specify drives to be scanned, the storage directory *must* pe provided.

<b>It would be *very* unwise to specify the first drive as `/dev/sda` and forget to include the storage directory when running as root.</b> Better command line arg  handling would reduce this risk.

`collect-drive-stats.sh` takes no command line arguments. It will look for a file `/srvpool/srv/drive-stats/hosts` that lists the hosts from which it will collect reports. Lines starting with `#` will be ignored. Reports will be stored in `/srvpool/srv/drive-stats/<hostname>`

## Deploying

Just some biolerplate to facilitate deploying to numerous hosts.

```text
user=someuser
remote=somehost
scp record-drive-stats.sh drive-func.sh $user@$remote:/home/$user
ssh-copy-id $user@$remote # if needed
ssh $user@$remote
sudo  mv record-drive-stats.sh drive-func.sh /usr/local/sbin
sudo mkdir -p /var/local/drive-stats
sudo chmod a+rwx /var/local/drive-stats
sudo record-drive-stats.sh /var/local/drive-stats
# add cron job (above)
sudo crontab -e
```

Or deploy using Ansible

```text
ansible-playbook deploy-recorder.yml -i $remote_hostname, -k --ask-become-pass
```

## Status

Working locally - please report any issues. Presently a work in progress moving from a private repo to a public repo and adding proper documentation (`README.md`.)

Some cleanup is needed to address `shellcheck` reported issues.

## Requirements

install the `smartmontools` package on hosts that generate the reports. `rsync` must be installed on all hosts.

```text
sudo apt install smartmontools
```

User requires `root` access on the hosts that will run `smartmontools`. User on the host that collects the reports requires passwordless `ssh` access to the other hosts. This requires appropriate permissions/ownership of files in `/srvpool/srv/drive-stats` on the remote hosts and `/srvpool/srv/drive-stats/` on the local host.

## Testing

Install `shunit2` and `shellcheck`

```text
sudo apt install shunit2 shellcheck
```

Execute unit tests

```text
./drive-func-test.sh
```

Lint scripts

```text
shellcheck record-drive-stats.sh
shellcheck collect-drive-stats.sh
shellcheck drive-func.sh
shellcheck drive-func-test.sh
```

Testing requires the `shunit2` package.

## Contributing

I generally appreciate contributions but reserve the right to reject any for any reason. I think it wise that contributors assign non-exclusive copyright to me so I retain full control of this repo. (Feel free to argue otherwise.) Some areas I would particularly appreciate contribuytions include:

* Better processing of command line arguments.
* Post collection analysis of data to highlight such things as growing defects or excess power on hours. Perhaps just summarize stats for individual drives over time.
* Pointing out typos, confusing instructions, etc.

## Errata

Drives raided on an LSI HBA require a special command option to report SMART statistics. This was accomplished using the `record-megaraid_drive-stats.sh` script. It is included as perhaps helpful but is no longer supported as I do not have any RAIDs hosted on one of these cards.
