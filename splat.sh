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

echo "Installing to [$DISK] in 5 seconds... ctrl+c to abort"
sleep 5

for a in ${DISK}* ; do
umount $a
done
set -e


try dd if=/dev/zero of="$DISK" bs=1M count=30
try parted "$DISK" mklabel gpt
try cgpt create "$DISK"
try cgpt add -i 1 -t kernel -b 8192 -s 32768 -l Kernel -S 1 -T 5 -P 10 "$DISK"

SECTOR="$(cgpt show $DISK | grep "Sec GPT table" | awk '{print $1}')"

try cgpt add -i 2 -t data -b 40960 -s `expr $SECTOR - 40960` -l Root "$DISK"
try sync
sleep 1
if grep -q /dev/sd <<<"$DISK" ; then
  # I assume this is the USB stick and I'm inside chromeos
  try sfdisk -R $DISK
fi

if grep -q /dev/mmcblk <<<"$DISK" ; then
  # I assume this is now the inbuilt MMC and I'm inside arch
  try partprobe
fi

sleep 1

try mkfs.ext4 -L root -m 0 "${DISK}2"
try wget http://archlinuxarm.org/os/ArchLinuxARM-peach-latest.tar.gz -c

try mkdir -p root
try mount "${DISK}2" root
try tar -xf ArchLinuxARM-peach-latest.tar.gz -C root

try dd if=root/boot/vmlinux.kpart of="${DISK}1"
try sync
try umount root

yell reboot, ctrl+u
exit


