#!/usr/bin/bash
#per:  http://archlinuxarm.org/platforms/armv7/samsung/samsung-chromebook

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
fi

echo "Installing to [$DISK] in 5 seconds... ctrl+c to abort"
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
    echo "Local copy of Arch tarball has the correct MD5 -yay"
  else
    MD5_GOOD=0
    echo "Local copy of Arch has wrong md5.. removing file.. run this script again"
    try rm "$FILE"
    exit
  fi
}

if [ ! -f "$FILE" ]; then
  echo "Downloading Arch tarball"
  curl "http://os.archlinuxarm.org/os/ArchLinuxARM-peach-latest.tar.gz" -O "$FILE"
  check_md5
else
  check_md5
fi


try mkdir -p root

try dd if=/dev/zero of="$DISK" bs=1M count=30
try parted "$DISK" mklabel gpt
try cgpt create "$DISK"
try cgpt add -i 1 -t kernel -b 8192 -s 32768 -l Kernel -S 1 -T 5 -P 10 "$DISK"

SECTOR="$(cgpt show $DISK | grep "Sec GPT table" | awk '{print $1}')"

try cgpt add -i 2 -t data -b 40960 -s `expr $SECTOR - 40960` -l Root "$DISK"
try sync
sleep 1


if [ "$TYPE" == usb ]; then
  # I assume this is the USB stick and I'm inside chromeos
  try sfdisk -R $DISK
else
  # I assume this is now the inbuilt MMC and I'm inside arch
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

yell "beroot!"
