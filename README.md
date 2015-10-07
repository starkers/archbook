# Overview
Install arch onto an HP chromebook 11

Kudos to @omgmog https://github.com/omgmog/archarm-usb-hp-chromebook-11

Loosely this is based off the steps here: http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

## Pre-work
on chromeos ensure you have
- developer mode **enabled**
- you have run: ```dev_install```
- you installed parted: ```emerge parted```
- USB boot enabled: ```crossystem dev_boot_usb=1 dev_boot_signed_only=0```

## grab script and go

```
wget http://git.io/vnD1l -O splat.sh
bash splat.sh $DEVICE
```

where ```$DEVICE``` is normally one of these:

 1. **/dev/sda** (from chromeos)

 2. **/dev/mmcblk0** (once booted off said USB stick)


# notes
This script is currently only supported on the chromebook itself, it should work on an x86 computer but ensure you have the usual criminals installed (```cgpt```, ```parted``` ```mkfs.ext4```, ```tar```, ```wget``` ...coffee ...beer)
