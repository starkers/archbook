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
- SanDisk Ultra Fit™ CZ43 32GB USB 3.0 Low-Profile Flash Drive - SDCZ43-032G-G46 - https://www.sandisk.com/home/usb-flash/ultra-fit-usb

## non-working memory sticks
- SanDisk 64GB Cruzer Extreme
- Pretec i-Disk Bullet 3.0


## execution variables
**Note** plug in a USB stick.. it should hopefully come up as ```/dev/sda```
In theory you can prepare a memory stick even on an x86 computer however:

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
This script is currently only supported on the armv7l chromebook itself, it should work on an x86 computer but ensure you have the usual criminals installed (```cgpt```, ```parted``` ```mkfs.ext4```, ```tar```, ```wget``` ...coffee ...beer)

# Changes in shdriesner fork (https://github.com/shdriesner/archbook/tree/revise_parted_handling)
- Changed root to /tmp/root (for mounting the root partition)
- Removed parted and its libraries from the repo in favor of performing dev_install+emerge to install parted when in ChromeOS, and using pacman to install parted when in Arch.  This also reduced the amount of cleanup needed at the end of the script.
- Revised lots of variable usage and naming to be a bit more explicit and clear.
- Revised cgpt handling such that PATH contains /usr/local/bin, and existing cgpt in the active install is now copied to the new install's root partition in path /usr/local/bin to make downloading cgpt from the repo during the install (and the need to check for MACHINE type) unnecessary.  The intention is to make this script more compatible with non-ARM7 chromebooks.
- Changed exit due to failed MD5 from 'exit' to 'exit 0' to prevent exiting the shell entirely.
- Added a bit more verbage to the exit text so the user know what to do when the script completes.
- For USB install, the AchLinux ARM tarball, its MD5, and the currently executing script are now copied to the new install's root partition at /root (i.e. root's home directory) so that these are already available to the user for installation to eMMC once the user reboots to the new USB install and logs in as root.
