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

debootstrap --include=sudo,openssh-server,ntpdate,dosfstools,sysvinit,fbset,less,xserver-xorg-video-modesetting,task-xfce-desktop,hicolor-icon-theme,gnome-icon-theme,tango-icon-theme,i3-wm,i3status,keychain,avahi-daemon,avahi-dnsconfd,libnss-mdns,btrfs-tools,xfsprogs,dosfstools,parted,debootstrap,apt-cacher-ng,python wheezy /mnt http://127.0.0.1:3142/ftp.ie.debian.org/debian/

echo root:kosagi | chroot /mnt /usr/sbin/chpasswd

cp files/etc/fstab /mnt/etc/fstab
cp files/etc/apt/sources.list /mnt/etc/apt/sources.list
cp files/etc/apt/sources.list.d/kosagi.list /mnt/etc/apt/sources.list.d/kosagi.list
cp files/etc/network/interfaces /mnt/etc/network/interfaces
cp files/boot-ubuntu.scr /boot/bootloader/boot.scr

# stop apt from doing stuff
cp files/usr/sbin/policy-rc.d /mnt/usr/sbin/policy-rc.d

cp files/kosagi.gpg.key /mnt/root/kosagi.gpg.key
chroot /mnt apt-key add /root/kosagi.gpg.key
chroot /mnt apt-get update -y
chroot /mnt env DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive apt-get install -y imx-sdma-firmware

mkdir -p /mnt/etc/X11
cp files/etc/X11/xorg.conf /mnt/etc/X11/xorg.conf
cp files/etc/inittab /mnt/etc/inittab
cp files/etc/default/locale /mnt/etc/default/locale

# let apt run things again
rm /mnt/usr/sbin/policy-rc.d

cp kernel/*deb /mnt/root
chroot /mnt dpkg -i /root/linux-firmware-image-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i /root/linux-headers-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i /root/linux-image-3.16.0-rc2-28074-g8b39edb_1.2_armhf.deb
chroot /mnt dpkg -i /root/linux-libc-dev_1.2_armhf.deb

echo "Now reboot"
