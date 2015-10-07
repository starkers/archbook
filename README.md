# TL;DR
Install arch onto an HP chromebook 11

Install steps:
- developer mode [enabled](https://blog.omgmog.net/post/installing-arch-linux-arm-on-the-hp-chromebook-11/)
- in chromebook open terminal.. ```ctrl```+```alt```+```t```

```
shell
sudo su -
```
- enable USB boot: ```crossystem dev_boot_usb=1 dev_boot_signed_only=0```
- plug in a memory stick
- splat it

```
wget http://git.io/vnD1l -O splat.sh
bash splat.sh
```

# Credits
- @omgmog - https://github.com/omgmog/archarm-usb-hp-chromebook-11
- ArchLinux.. this is based off the steps here: http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

# Pre-work
on chromeos ensure you have
- developer mode [enabled](https://blog.omgmog.net/post/installing-arch-linux-arm-on-the-hp-chromebook-11/)
- USB boot enabled: ```crossystem dev_boot_usb=1 dev_boot_signed_only=0```

You no longer need parted or to have run ```dev_install```
..the binaries and libs are grabbed from here

# Memory stick
I don't know why yet but most of my memory sticks don't "work"..
## working USB sticks
The following sticks are known to work: (Please report success)
- DataTraveler "G4" - http://www.kingston.com/datasheets/DTIG4_en.pdf

## non-working memory sticks
- SanDisk 64GB Cruzer Extreme
- Pretec i-Disk Bullet 3.0


## execution variables
**Note** plug in a USB stick.. it should hopefully come up as ```/dev/sda```
In theort you can prepare a memory stick even on an x86 computer however:

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

# erata
This script is currently only supported on the chromebook itself, it should work on an x86 computer but ensure you have the usual criminals installed (```cgpt```, ```parted``` ```mkfs.ext4```, ```tar```, ```wget``` ...coffee ...beer)
