#!/usr/bin/env bash
# Install Arch onto a USB stick for the HP Chromebook 11
# per:  http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

# It may be possible to do this on other samsung chromebooks, feedback welcome

# Notes for the HP chromebook 11:
# its a bit of a crapshoot whether or not a USB stick will work..
#
# I've personally only had 1/5 work... 

# The following sticks are known to work: (Please report success)
# - DataTraveler "G4" - http://www.kingston.com/datasheets/DTIG4_en.pdf

# Written and maintained by David Stark: https://github.com/starkers/archbook
#
# to download this script: http://git.io/vnD1l

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$@" ; "$@" 1>/dev/null 2>/dev/null || die "cannot $*"; }


if [ X$1 == X ]; then
  DISK=/dev/sda
else
  DISK=$1
fi


if grep -q /dev/sd <<<"$DISK" ; then
  TYPE=usb
elif grep -q /dev/mmcblk <<<"$DISK" ; then
  TYPE=mmc
else
  die "I'm sorry but I don't recognise the device: $DISK"
fi

# if [ ! -b "$DISK" ]; then
#   die "error.. $DISK is not a block device"
# fi

yell "Installing to [$DISK] in 5 seconds... ctrl+c to abort"
sleep 5

for a in ${DISK}* ; do
umount $a
done
set -e

FILE=ArchLinuxARM-peach-latest.tar.gz

check_md5(){
  MD5_CURRENT="$(curl -s http://os.archlinuxarm.org/os/${FILE}.md5 | cut -c 1-32 )"
  MD5_LOCAL="$(md5sum < "$FILE" | cut -c 1-32)"
  if [ "X$MD5_LOCAL" == "X$MD5_CURRENT" ]; then
    MD5_GOOD=1
    yell "Local copy of Arch tarball has the correct MD5 -yay"
  else
    MD5_GOOD=0
    yell "Local copy of Arch has wrong md5.. removing file.. run this script again"
    try rm "$FILE"
    exit
  fi
}

if [ ! -f "$FILE" ]; then
  yell "Downloading ArchLinuxARM tarball.. so wow"
  curl "http://os.archlinuxarm.org/os/ArchLinuxARM-peach-latest.tar.gz" -o "$FILE"
  check_md5
else
  check_md5
fi


### Pre-Checks for binaries etc...
# what platform is this?
MACHINE="$(uname -m)"
# TOOD: this should attempt to verify if its on ChromeOS-Arch (or another platform)
#   EG: ... trying to prepare the USB stick on a amd64 box would fail

# Binaries must be under /usr/local/bin due to cgroups or something I assume
mkdir -p /usr/local/bin

CGPT_BIN=/usr/local/bin/cgpt.tmp
try wget https://raw.githubusercontent.com/starkers/archbook/master/bin/$MACHINE/cgpt -O "$CGPT_BIN"
try chmod +x "$CGPT_BIN"

if [ ! -f /usr/local/bin/parted ]; then
  INSTALLED_PARTED=1
  PARTED_BIN=/usr/local/bin/parted.tmp
  try wget https://raw.githubusercontent.com/starkers/archbook/master/bin/$MACHINE/parted -O "$PARTED_BIN"
  try chmod +x "$PARTED_BIN"

  try mkdir -p /usr/local/lib
  LIB_PARTED=/usr/local/lib/libparted.so.2.0.0
  try wget https://raw.githubusercontent.com/starkers/archbook/master/bin/$MACHINE/libparted.so.2.0.0 -O $LIB_PARTED
  try ln -sf $LIB_PARTED /usr/local/lib/libparted.so.2
  try ln -sf $LIB_PARTED /usr/local/lib/libparted.so
else
  PARTED_BIN=/usr/local/bin/parted
fi

try mkdir -p root
try dd if=/dev/zero of="$DISK" bs=1M count=30
try $PARTED_BIN "$DISK" mklabel gpt
try $CGPT_BIN create "$DISK"
try $CGPT_BIN add -i 1 -t kernel -b 8192 -s 32768 -l Kernel -S 1 -T 5 -P 10 "$DISK"

#this is used to determine last sector
SECTOR="$($CGPT_BIN show $DISK | grep "Sec GPT table" | awk '{print $1}')"

let "LIMIT = $SECTOR - 40960"
try $CGPT_BIN add -i 2 -t data -b 40960 -s $LIMIT -l Root "$DISK"



yell "Signal re-read of device"
try sync
sleep 1
if [ "$TYPE" == usb ]; then
  yell "I assume this is the USB stick and I'm inside chromeos"
  try sfdisk -R $DISK
else
  yell "I assume this is now the inbuilt MMC and I'm inside arch"
  try partprobe
fi

sleep 1

if [ "$TYPE" == usb ]; then
  try mkfs.ext4 -L root -m 0 "${DISK}2"
  try mount "${DISK}2" root
else
  try mkfs.ext4 -L root -m 0 "${DISK}p2"
  try mount "${DISK}p2" root
fi

try tar -xf ArchLinuxARM-peach-latest.tar.gz -C root

if [ "$TYPE" == usb ]; then
  try dd if=root/boot/vmlinux.kpart of="${DISK}1"
else
  try dd if=root/boot/vmlinux.kpart of="${DISK}p1"
fi

try sync
try umount root

yell "Cleaning up"
if [ X$INSTALLED_PARTED == X1 ]; then
  try rm -f /usr/local/lib/libparted.so /usr/local/lib/libparted.so.2 /usr/local/lib/libparted.so.2.0.0 $PARTED_BIN
fi
try rm "$CGPT_BIN"

yell "beroot!"
