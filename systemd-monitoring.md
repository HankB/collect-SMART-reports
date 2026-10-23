# Systemd monitoring

## Recorder

```text
systemctl status smart-drive-stats-recorder.timer
systemctl status smart-drive-stats-recorder.service
```

## Recorder example

```text
root@ester:~# systemctl status smart-drive-stats-recorder.timer smart-drive-stats-recorder.service
● smart-drive-stats-recorder.timer - Weekly SMART drive statistics recording
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-recorder.timer; enabled; preset: enabled)
     Active: active (waiting) since Thu 2026-10-22 20:48:42 CDT; 19h ago
 Invocation: d3d62df84422449d9efb4c539efb94c0
    Trigger: Fri 2026-10-30 10:20:00 CDT; 6 days left
   Triggers: ● smart-drive-stats-recorder.service

Oct 22 20:48:42 ester systemd[1]: Started smart-drive-stats-recorder.timer - Weekly SMART drive statistics recording.

○ smart-drive-stats-recorder.service - Record SMART drive statistics
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-recorder.service; static)
     Active: inactive (dead) since Fri 2026-10-23 13:44:59 CDT; 2h 44min ago
 Invocation: 284c863dca374ba9ab0121e17821de42
TriggeredBy: ● smart-drive-stats-recorder.timer
    Process: 75761 ExecStart=/usr/local/sbin/record-drive-stats.sh --directory /var/local/drive-stats/ (code=exited, status=0/SUCCESS)
   Main PID: 75761 (code=exited, status=0/SUCCESS)
   Mem peak: 4.4M
        CPU: 83ms

Oct 23 13:44:59 ester systemd[1]: Starting smart-drive-stats-recorder.service - Record SMART drive statistics...
Oct 23 13:44:59 ester sudo[75769]:     root : PWD=/ ; USER=root ; COMMAND=/usr/sbin/smartctl --scan-open
Oct 23 13:44:59 ester sudo[75769]: pam_unix(sudo:session): session opened for user root(uid=0) by (uid=0)
Oct 23 13:44:59 ester sudo[75769]: pam_unix(sudo:session): session closed for user root
Oct 23 13:44:59 ester record-drive-stats.sh[75761]: processing /dev/nvme0 -d nvme
Oct 23 13:44:59 ester sudo[75845]:     root : PWD=/ ; USER=root ; COMMAND=/usr/sbin/smartctl -a -d nvme /dev/nvme0
Oct 23 13:44:59 ester sudo[75845]: pam_unix(sudo:session): session opened for user root(uid=0) by (uid=0)
Oct 23 13:44:59 ester sudo[75845]: pam_unix(sudo:session): session closed for user root
Oct 23 13:44:59 ester systemd[1]: smart-drive-stats-recorder.service: Deactivated successfully.
Oct 23 13:44:59 ester systemd[1]: Finished smart-drive-stats-recorder.service - Record SMART drive statistics.
root@ester:~# 
```

## Collector

Includes the units above if it is also a recorder and in addition:

```text
systemctl status smart-drive-stats-collector.timer
systemctl status smart-drive-stats-collector.service
```

## Collector (and recorder) example

```text
root@piserver:~# systemctl status smart-drive-stats-recorder.timer smart-drive-stats-recorder.service
● smart-drive-stats-recorder.timer - Weekly SMART drive statistics recording
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-recorder.timer; enabled; preset: enabled)
     Active: active (waiting) since Mon 2026-10-19 08:23:03 CDT; 4 days ago
 Invocation: ad776b3331d041b69afcea85281f75b2
    Trigger: Fri 2026-10-30 10:20:00 CDT; 6 days left
   Triggers: ● smart-drive-stats-recorder.service

Notice: journal has been rotated since unit was started, output may be incomplete.

○ smart-drive-stats-recorder.service - Record SMART drive statistics
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-recorder.service; static)
     Active: inactive (dead) since Fri 2026-10-23 10:20:14 CDT; 6h ago
 Invocation: 2c128825741f41308aa7dae48fb6a698
TriggeredBy: ● smart-drive-stats-recorder.timer
    Process: 2033185 ExecStart=/usr/local/sbin/record-drive-stats.sh --directory /var/local/drive-stats/ (code=exited, status=0/SUCCESS)
   Main PID: 2033185 (code=exited, status=0/SUCCESS)
   Mem peak: 4.5M
        CPU: 482ms

Oct 23 10:20:12 piserver sudo[2033225]: pam_unix(sudo:session): session opened for user root(uid=0) by (uid=0)
Oct 23 10:20:12 piserver sudo[2033225]: pam_unix(sudo:session): session closed for user root
Oct 23 10:20:12 piserver record-drive-stats.sh[2033185]: record-drive-stats.sh: smartctl reported SMART findings for /dev/sda (exit 64)
Oct 23 10:20:13 piserver record-drive-stats.sh[2033185]: processing /dev/sdb -d sat
Oct 23 10:20:13 piserver sudo[2033270]:     root : PWD=/ ; USER=root ; COMMAND=/usr/sbin/smartctl -a -d sat /dev/sdb
Oct 23 10:20:13 piserver sudo[2033270]: pam_unix(sudo:session): session opened for user root(uid=0) by (uid=0)
Oct 23 10:20:13 piserver sudo[2033270]: pam_unix(sudo:session): session closed for user root
Oct 23 10:20:13 piserver record-drive-stats.sh[2033185]: record-drive-stats.sh: smartctl reported SMART findings for /dev/sdb (exit 32)
Oct 23 10:20:14 piserver systemd[1]: smart-drive-stats-recorder.service: Deactivated successfully.
Oct 23 10:20:14 piserver systemd[1]: Finished smart-drive-stats-recorder.service - Record SMART drive statistics.
root@piserver:~# systemctl status smart-drive-stats-collector.timer smart-drive-stats-collector.service
● smart-drive-stats-collector.timer - SMART drive statistics collection
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-collector.timer; enabled; preset: enabled)
     Active: active (waiting) since Mon 2026-10-19 08:23:03 CDT; 4 days ago
 Invocation: 1c5214fe3ea249a88f253d310db8e10f
    Trigger: Fri 2026-10-30 03:02:12 CDT; 6 days left
   Triggers: ● smart-drive-stats-collector.service

Notice: journal has been rotated since unit was started, output may be incomplete.

○ smart-drive-stats-collector.service - Collect SMART drive statistics
     Loaded: loaded (/etc/systemd/system/smart-drive-stats-collector.service; static)
     Active: inactive (dead) since Fri 2026-10-23 12:08:21 CDT; 4h 23min ago
 Invocation: 48640670b1d84b68971566ecfb705f5e
TriggeredBy: ● smart-drive-stats-collector.timer
    Process: 2071340 ExecStart=/usr/local/sbin/collect-drive-stats.sh (code=exited, status=0/SUCCESS)
   Main PID: 2071340 (code=exited, status=0/SUCCESS)
   Mem peak: 4.1M
        CPU: 1.464s

Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: File list size: 150
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: File list generation time: 0.001 seconds
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: File list transfer time: 0.000 seconds
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: Total bytes sent: 20
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: Total bytes received: 161
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: sent 20 bytes  received 161 bytes  120.67 bytes/sec
Oct 23 12:08:21 piserver collect-drive-stats.sh[2071669]: total size is 11,652  speedup is 64.38
Oct 23 12:08:21 piserver systemd[1]: smart-drive-stats-collector.service: Deactivated successfully.
Oct 23 12:08:21 piserver systemd[1]: Finished smart-drive-stats-collector.service - Collect SMART drive statistics.
Oct 23 12:08:21 piserver systemd[1]: smart-drive-stats-collector.service: Consumed 1.464s CPU time, 4.1M memory peak.
root@piserver:~# 
```
