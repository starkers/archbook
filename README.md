# Overview
Install arch onto an HP chromebook 11


Kudos to @ https://github.com/omgmog/archarm-usb-hp-chromebook-11
but based off the steps here: http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

I got tired of all the typing so posting here

on chromeos ensure you have :
- developer mode enabled
- run ```dev_install```
- you installed parted: ```emerge parted```



## grab script and go

```
wget http://git.io/vnD1l -O splat.sh
chmod +x splat.sh
./splat.sh $DEVICE
```

where DEVICE is normally:

 1. /dev/sda (from chromeos)

 2. /dev/mmcblk0 (once booted of said USB stick)
