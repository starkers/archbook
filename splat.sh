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

if grep -q /dev/sd <<<"${DISK}" ; then
  TYPE=usb
elif grep -q /dev/mmcblk <<<"${DISK}" ; then
  TYPE=mmc
else
  die "I'm sorry but I don't recognise the device: ${DISK}"
fi

# if [ ! -b "${DISK}" ]; then
#   die "error.. ${DISK} is not a block device"
# fi

yell "Installing to [${DISK}] in 5 seconds... ctrl+c to abort"
sleep 5

for a in ${DISK}* ; do umount $a; done
set -e

ROOTFS=/tmp/root
TARBALL=ArchLinuxARM-peach-latest.tar.gz
ARCH_URL=http://os.archlinuxarm.org/os
REPO_URL=https://raw.githubusercontent.com/starkers/archbook/master

check_md5(){
  MD5_CURRENT="$(curl -s ${ARCH_URL}/${TARBALL}.md5 | cut -c 1-32 )"
  MD5_LOCAL="$(md5sum < "${TARBALL}" | cut -c 1-32)"
  if [ "X${MD5_LOCAL}" == "X${MD5_CURRENT}" ]; then
    yell "Local copy of Arch tarball has the correct MD5 -yay"
  else
    yell "Local copy of Arch has wrong md5.. removing file.. run this script again"
    try rm "${TARBALL}"
    exit
  fi
}

if [ ! -f "${TARBALL}" ]; then
  yell "Downloading ArchLinuxARM tarball.. so wow"
  curl "${ARCH_URL}/${TARBALL}" -o "${TARBALL}"
fi
check_md5

### Pre-Checks for binaries etc...
# what platform is this?
MACHINE="$(uname -m)"

###
# Check status of cgpt binary
# The cgpt binary should be native in the chromeos install,
# but it may need to be installed from this repo when this
# script is running in the Arch install from USB,
# and we will keep our fingers crossed that its dependencies
# are satisfied in the current running OS.
###
if [ X`which cgpt 2>/dev/null` == X ]; then
  # Binaries must be under /usr/local/bin due to cgroups or something I assume.
  # Locally update PATH so that 'cgpt' can be invoked without specifying full path.
  PATH="$PATH:/usr/local/bin"
  # create its target directory location
  mkdir -p /usr/local/bin
  # force the install in case the version in the repo is newer
  try wget ${REPO_URL}/bin/${MACHINE}/cgpt -O /usr/local/bin/cgpt
  # make sure its executable
  try chmod +x /usr/local/bin/cgpt
fi

###
# Check if parted is installed, and if not, install
# parted using the distro appropriate method.
# This is a more future proof way to do it than
# installing parted and its libraries from this
# repo, because otherwise we are chasing parted's
# dependencies as Arch gets updated over time.
###
if [ X`which parted 2>/dev/null` == X ]; then
  # we need to install parted
  if [ X`which emerge 2>/dev/null` != X ]; then
    # install parted the gentoo/chromeos way
    try emerge parted
  else if [ X`which pacman 2>/dev/null` != X ]; then
    # install parted the Arch way
    try pacman -S parted
  fi
fi

try mkdir -p "${ROOTFS}"
try dd if=/dev/zero of="${DISK}" bs=1M count=30
try parted "${DISK}" mklabel gpt
try cgpt create "${DISK}"
try cgpt add -i 1 -t kernel -b 8192 -s 32768 -l Kernel -S 1 -T 5 -P 10 "${DISK}"

#this is used to determine last sector
SECTOR="$(cgpt show ${DISK} | grep "Sec GPT table" | awk '{print $1}')"

let "LIMIT = $SECTOR - 40960"
try cgpt add -i 2 -t data -b 40960 -s "${LIMIT}" -l Root "${DISK}"

yell "Signal re-read of device"
try sync
sleep 1
if [ "${TYPE}" == usb ]; then
  yell "I assume this is the USB stick and I'm inside chromeos"
  try sfdisk -R "${DISK}"
else
  yell "I assume this is now the inbuilt MMC and I'm inside arch"
  try partprobe
fi

sleep 1

# set name of disk partition
DISKP="${DISK}"
# for MMC, append 'p' to DISK
if [ "${TYPE}" == mmc ]; then DISKP="${DISKP}p"; fi

# format and mount root partition
try mkfs.ext4 -L root -m 0 "${DISKP}2"
try mount "${DISKP}2" ${ROOTFS}
# extract Arch install to root partition
try tar -xf "${TARBALL}" -C ${ROOTFS}
# write kernel directly to kernel partition
try dd if="${ROOTFS}/boot/vmlinux.kpart" of="${DISKP}1"

# perform sync, and unmount root partition, and remove ROOTFS if empty
try sync
try umount ${ROOTFS}
try rmdir ${ROOTFS}

yell "beroot!"
