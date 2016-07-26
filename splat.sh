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

# global config variables

# SPLAT is the name of this script
SPLAT=$0

# This is the tarball specifically for the Exynos processor on the Samsung and HP Chromebook 11.
# See http://archlinuxarm.org to determine the appropriate tarball for your ARM based
# chromebook.
TARBALL=ArchLinuxARM-peach-latest.tar.gz
# This is the download URL for the above tarball and its md5 file
ARCH_URL=http://os.archlinuxarm.org/os

# This is the mount point for the root FS to which the tarball will be extracted
ROOTFS=/tmp/root

# Binaries must be under /usr/local/bin due to cgroups or something I assume.
# Locally update PATH so that 'cgpt' can be invoked without specifying full path.
PATH="${PATH}:/usr/local/bin"

###
# This function handles installing whatever packages
# are passed to it, determining dynamically whether
# to install using pacman (Arch way) or using emerge
# (ChromeOS/Gentoo way).
###
get_pkg() {
  # do nothing if no arguments given
  for pkg in $*; do
    if [ X`which ${pkg} 2>/dev/null` == X ]; then
      # we need to install ${pkg}
      if [ X`which pacman 2>/dev/null` != X ]; then
        # install the Arch way
        cat <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
We need to install ${pkg} now using 'pacman -S'
When prompted, just hit [ENTER] or type 'Y' and hit
[ENTER] to proceed with the installation of ${pkg}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOF
        # perform the install
        pacman -S "${pkg}"
      else
        # install the gentoo/chromeos way
        if [ X`which emerge 2>/dev/null` == X ]; then
          cat <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
The tool 'emerge' is missing, so we need to install it
via the 'dev_install' command.  When prompted, just hit
[ENTER] to accept the defaults, or customize as desired.
You may see many errors during 'dev_install' execution.
As long as the result is a working version of 'emerge'
we should be good to go, but YMMV.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOF
          # wait for user to say go
          echo -n "Hit [ENTER] to proceed with running dev_install or Ctrl-C to quit: " && read ans
          # execute dev_install
          dev_install
        fi
        cat <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
We can emerge ${pkg} now, so here goes ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOF
        # perform the install
        emerge "${pkg}"
      fi
    fi
  done
}

# This is where we check for the user supplied disk path
if [ X$1 == X ]; then
  DISK=/dev/sda
else
  DISK=$1
fi

# This is where we detect what type of install we are attempting
#
if grep -q /dev/sd[a-z]$ <<<"${DISK}" ; then
  TYPE="usb"
elif grep -q /dev/mmcblk[0-9]$ <<<"${DISK}" ; then
  TYPE="mmc"
else
  cat <<EOF
I'm sorry, but the disk path ${DISK} is invalid.

For USB install, please specify a /dev/sd<x> path
(where <x> is a lower case letter in the range a-z
corresponding to the intended block device target),

For an eMMC or SD card install, please specify a
/dev/mmcblk<N> path (where <N> is a number in the range
0-9 corresponding to the intended block device target).

Be sure to specify a block device path and *not* merely
a single partition's path, because this tool is designed
to apply a complete partition scheme to the entire target
disk.

EOF
  die "exiting ..."
fi

# if [ ! -b "${DISK}" ]; then
#   die "error.. ${DISK} is not a block device"
# fi

yell "Installing to [${DISK}] in 5 seconds... ctrl+c to abort"
sleep 5

for a in ${DISK}* ; do umount $a; done
set -e

###
# make sure the needed tools are present
###
get_pkg wget parted

# download the ArchLinuxARM tarball and MD5 files
for f in "${TARBALL}" "${TARBALL}.md5"; do
  if [ ! -f "${f}" ]; then
    yell "Downloading ${ARCH_URL}/${f} to ${f}"
    wget "${ARCH_URL}/${f}" -O "${f}"
  fi
done

# verify tarball's integrity
if [ X`md5sum -c ${TARBALL}.md5 2>/dev/null | awk '{print $NF}'` == X"OK" ]; then
  yell "Local copy of ${TARBALL} is OK"
else
  yell "Local copy of Arch has wrong md5 ... removing file(s) ... run this script again"
  try rm "${TARBALL}" "${TARBALL}.md5"
  exit 0
fi

# this is where we create a new GPT table and configure partitions
try mkdir -p "${ROOTFS}"
try dd if=/dev/zero of="${DISK}" bs=1M count=30
try parted "${DISK}" mklabel gpt
try cgpt create "${DISK}"
# configure the Kernel partition
try cgpt add -i 1 -t kernel -b 8192 -s 32768 -l Kernel -S 1 -T 5 -P 10 "${DISK}"

#this is used to determine last sector
SECTOR="$(cgpt show ${DISK} | grep "Sec GPT table" | awk '{print $1}')"

let "LIMIT = ${SECTOR} - 40960"
# configure the Root partition
try cgpt add -i 2 -t data -b 40960 -s "${LIMIT}" -l Root "${DISK}"

yell "Signal re-read of device"
try sync
sleep 1
if [ "usb" == "${TYPE}" ]; then
  yell "I assume this is the USB stick and I'm inside chromeos"
  try hdparm -z "${DISK}"
else
  yell "I assume this is now the inbuilt eMMC and I'm inside arch"
  try partprobe
fi

sleep 1

# set name of disk partition
DISKP="${DISK}"
# for eMMC, append 'p' to DISKP
if [ "mmc" == "${TYPE}" ]; then DISKP="${DISKP}p"; fi

# format and mount root partition
try mkfs.ext4 -L root -m 0 "${DISKP}2"
try mount "${DISKP}2" ${ROOTFS}
# extract Arch install to root partition
try tar -xf "${TARBALL}" -C ${ROOTFS}
# write kernel directly to kernel partition
try dd if="${ROOTFS}/boot/vmlinux.kpart" of="${DISKP}1"

# if there is a working copy of cgpt, we are going to transfer
# it to the new install.
for exe in cgpt; do
  fp=`which ${exe} 2>/dev/null`
  if [ X"${fp}" != X ]; then
    # we don't care if this fails
    mkdir -p "${ROOTFS}/usr/local/bin"
    # copy the binary
    try cp -f "${fp}" "${ROOTFS}/usr/local/bin/."
    # make sure it's executable
    try chmod +x "${ROOTFS}/usr/local/bin/${exe}"
  fi
done

# if this is a USB install, we will go ahead and add the TARBALL, its MD5,
# and this script to the ${ROOTFS}/root directory to save download time.
if [ "usb" == "${TYPE}" ]; then
  for f in "${SPLAT}" "${TARBALL}" "${TARBALL}.md5"; do
    try cp -vf "${f}" "${ROOTFS}/root/."
  done
fi

# perform sync, and unmount root partition, and remove ROOTFS if empty
try sync
try umount ${ROOTFS}
try rmdir ${ROOTFS}

if [ "usb" == "${TYPE}" ]; then
  cat <<EOF
Install to ${DISK} finished."
Reboot and hit Ctrl-U to select boot from ${DISK} at the splash screen.
You can simply enjoy running Arch Linux from USB, or to install natively to eMMC,
upon boot to ${DISK}, login as root, enable wifi, and execute the following from /root:

  % bash ${SPLAT} /dev/mmcblk0

EOF
else
  cat <<EOF
Install to ${DISK} finished.  You now have Arch Linux installed natively to eMMC."
Reboot, hit Ctrl-D to select boot from ${DISK} at the splash screen, and enjoy.
EOF
fi
