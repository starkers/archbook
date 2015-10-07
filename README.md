# Overview
Install arch onto an HP chromebook 11

Kudos to @omgmog https://github.com/omgmog/archarm-usb-hp-chromebook-11

Loosely this is based off the steps here: http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

## Pre-work
on chromeos ensure you have
- developer mode [enabled](https://blog.omgmog.net/post/installing-arch-linux-arm-on-the-hp-chromebook-11/)
- you have run: ```dev_install```
- you installed parted: ```emerge parted```
- USB boot enabled: ```crossystem dev_boot_usb=1 dev_boot_signed_only=0```

## grab script and go

**Note** plug in a USB stick.. it should hopefully come up as ```/dev/sda```

```
wget http://git.io/vnD1l -O splat.sh
bash splat.sh $DEVICE
```


where ```$DEVICE``` is normally one of these:

 1. **/dev/sda** (from chromeos)

 2. **/dev/mmcblk0** (once booted off said USB stick)

## Tips:
- The script stores the downloaded Arch image in your current directory.. If you run this under ```/home/root``` it should save you some bandwidth+time if running it multiple times.
- Install onto a USB stick first.. boot it.. then install onto your internal disk (```/dev/mmcblk0```)
- Its pretty easy to [encrypt](https://wiki.archlinux.org/index.php/EncFS) your home directory once you have Arch working.. (luks + loopback works too)
- wicd is wicd

# notes
This script is currently only supported on the chromebook itself, it should work on an x86 computer but ensure you have the usual criminals installed (```cgpt```, ```parted``` ```mkfs.ext4```, ```tar```, ```wget``` ...coffee ...beer)
