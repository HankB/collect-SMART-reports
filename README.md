# collect-SMART-reports

Collect SMART drive reports to a central location. Happens in two steps.

1. Individual hosts execute `record-drive-stats.sh` to capture SMART reports.
1. Some host collects the stats to a central location.

By convention, drive stats are stored locally in `/var/local/drive-stats` and collected centrally in `/var/local/drive-stats` (and perhaps in the future, in `/var/local/drive-stats/<hostname>`.)

## AI/LLM warning

I have been using ChatGPT heavily during the development of this upgrade. If you choose not to use projects that employ AI/LLMs, then move on. ChatGPT has been pretty rough in this effort. It continually produces results that are "almost correct." Perhaps I'm just not giving it sufficnent guidance or the free web version is intentionally weak. (That would be a bad strategy by OpenAI as my experience with the free version doesn't leave me inclined to send them money.) It seemed to do well with Ansible playbooks and those required minimal modifications.


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

### *DEPRECATED* Just some biolerplate to facilitate deploying to numerous hosts.

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

### Deploy using Ansible

There is a sister project in use to help manage a global inventory. <https://github.com/HankB/ansible-inventory> and the inventory for this playbook will include:

```text
# Ansible inventory for SMART drive statistics.

[smart_report_hosts]
oak
dragohost

[smart_collectors]
oak
```

If that facility is employed, the `ansible-playbook` invocation could look like:

```text
ansible-playbook -i /etc/ansible/inventory deploy-smart-drive-stats.yml -K
```

NB: If the inventory is updated and deployed, it is necessary to repeat this playbook as well.

The `collect-drive-stats.sh`

## Status

WIP to upgrade with the following goals:

* 2026-10-02 playbooks upgraded to install Systemd timer and service files to crive processing.
* as of 2026-10-01 the scripts are deployed to the two classes of host.
* as of 2026-10-01 Capture NVME as well as SATA drives.
* as of 2026-10-01 Streamline saving to a common host - eliminate the need to manually add new hosts to the list.
* 2026-09-11 `record-drive-stats.sh` has been modified to record SMART stats for NVME drives and has seen limited testing on local hosts.
* 2026-09-27 Presently working on the facility to collect scripts to a common location.

('as of' means I was slacking and not updating status to match progress.)

## Requirements

(These requirements are rewritten in the context of deployment using Ansible.)

The playbooks will generally take care of required applications, directories and Systemd timers and service units to manage operation. That leaves the requirement that the Ansible controller has passwordless SSH access to the collectors and recorders. Recorders and collectors are described below under Operation. (Not a hard requirement but it will be tiresome to enter the password for every connection.)

The Ansible controller need not be a recorder or collector.

The collectors require passwordless (non-root) acces to the recorders.

## Testing

*Testing is on the TODO list* At present only live 'in-situ' testing has been performed.

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

## Operation

The system consists of two operations.

* recorder - A process runs weekly on any host with NVME and SATA/SAS drives and records the results from `smartctl -a`. The recorder is scheduled in the wee hours but if the host is sleeping at that time (as certainly the operator will be) the process will run when it awakes (or reboots.)
* collector - This process runs on hosts which pull the reports to a central location for storage. The original reports remain on the recorders. The collector is scheduled to run a bit later in the wee hours with a random delay of up to 20 minutes to avoid all collectors hitting the recorders at the same instant. In order to accommodate the recorders that sleep through the night, the collector will run hourly (again with the random 20 minute delay) until just after 1200.

Multiple recorders are supported as well as multiple collectors.

## Contributing

I generally appreciate contributions but reserve the right to reject any for any reason. I think it wise that contributors assign non-exclusive copyright to me so I retain full control of this repo. (Feel free to argue otherwise.) Some areas I would particularly appreciate contribuytions include:

* Better processing of command line arguments.
* Post collection analysis of data to highlight such things as growing defects or excess power on hours. Perhaps just summarize stats for individual drives over time.
* Pointing out typos, confusing instructions, etc.

## Errata

Drives raided on an LSI HBA require a special command option to report SMART statistics. This was accomplished using the `record-megaraid_drive-stats.sh` script. It is included as perhaps helpful but is no longer supported as I do not have any RAIDs hosted on one of these cards. 2026-09-30 update: This may no longer be needed. Drives on various HBAs seem to be directly accessible to `smartctl`.
