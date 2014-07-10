#!/bin/bash

echo "Please read this script and execute it manually"

exit 1;

apt-get install -u parted btrfs-tools debootstrap

parted --script /dev/sda -- mklabel msdos
parted --script /dev/sda -- mkpart primary fat32 1 64
parted --script /dev/sda -- mkpart primary linux-swap 64 8256
parted --script /dev/sda -- mkpart primary btrfs 8256 -0

mkfs.vfat /dev/sda1
mkswap /dev/sda2
mkfs.btrfs /dev/sda3

mount /dev/sda3 /mnt

debootstrap --include=sudo,openssh-server,ntpdate,dosfstools,less precise /mnt http://192.168.0.54:3142/ports.ubuntu.com/ubuntu-ports/
#debootstrap --include=sudo,openssh-server,ntpdate,dosfstools,less precise /mnt http://127.0.0.1:3142/ports.ubuntu.com/ubuntu-ports/
#debootstrap precise /mnt http://ports.ubuntu.com/ubuntu-ports/

echo root:kosagi |  chroot /mnt /usr/sbin/chpasswd

cp files/etc/fstab /mnt/etc/fstab
cp files/etc/apt/sources.list /mnt/etc/apt/sources.list
cp files/etc/network/interfaces /mnt/etc/network/interfaces
cp files/boot-ubuntu.scr /boot/bootloader/boot.scr

cp kernel/*deb /mnt/root
chroot /mnt dpkg -i linux-firmware-image-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i linux-headers-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i linux-image-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i linux-libc-dev_1.2_armhf.deb

echo "Now reboot"
