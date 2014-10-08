#NOVENA_KVERSION=3.16.0-rc2_1.2
#NOVENA_KVERSION=3.16.0-rc2-00058-gdd3635d_1.2
NOVENA_KVERSION=3.16.0-rc2-28078-gdd3635d_1.2
KERNEL_GIT_VERSION=dd3635dab34fcd65410b6a3513999de379a29d5e

all:

default:

deps:
	sudo apt-get install -y qemu-utils apt-cacher-ng build-essential less rsync lzop u-boot-tools git debhelper bc device-tree-compiler parted kpartx

# The boot script is the only thing different in the recovery image
novena-recovery.img: bootscripts/boot-recovery.scr bootscripts/boot.scr
	echo "Assuming novena.img is already created and functions"
	cp novena.img novena-recovery.img
	sudo kpartx -a -v novena-recovery.img
	sudo mount /dev/mapper/loop0p1 /mnt
	sudo cp bootscripts/boot-recovery.scr /mnt/boot.scr
	sudo cp bootscripts/boot-recovery.scr /mnt/boot-recovery.scr
	sudo umount /mnt
	sudo kpartx -v -d novena-recovery.img

# this is destructive for now
novena.img: bootscripts/boot.scr uImage u-boot
	#qemu-img create novena.img 4000000000
	qemu-img create novena.img 3965190144

	sudo losetup /dev/loop0 novena.img
	sudo parted --script  /dev/loop0 -- mklabel msdos
	sudo parted --script  /dev/loop0   -- mkpart primary fat32 1 64
	sudo parted --script  /dev/loop0   -- mkpart primary ext4 64 -0
	#sudo parted --script /dev/loop0 -- set 1 boot on
	sudo losetup -d /dev/loop0

	sudo kpartx -a -v novena.img
	sudo mkfs.vfat /dev/mapper/loop0p1
	sudo mkfs.ext4 /dev/mapper/loop0p2

	# mount the fat32 and ext4 partition
	sudo mount /dev/mapper/loop0p2 /mnt

	# use local apt-cacher-ng proxy
	sudo debootstrap --components=wheezy-updates,main,wheezy --include=sudo,openssh-server,ntpdate,dosfstools,sysvinit,fbset,less,xserver-xorg-video-modesetting,task-xfce-desktop,hicolor-icon-theme,gnome-icon-theme,tango-icon-theme,i3-wm,i3status,keychain,avahi-daemon,avahi-dnsconfd,libnss-mdns,btrfs-tools,xfsprogs,parted,debootstrap,apt-cacher-ng,python,i2c-tools,qemu-utils,build-essential,rsync,lzop,u-boot-tools,git,debhelper,bc,device-tree-compiler,kpartx,ca-certificates wheezy /mnt http://127.0.0.1:3142/ftp.ie.debian.org/debian/

	# special mount points to silence harmless warnings and errors
	sudo mount --bind /dev/ /mnt/dev
	sudo mount --bind /dev/pts /mnt/dev/pts
	sudo chroot /mnt mount -t proc none /proc
	sudo chroot /mnt mount -t sysfs none /sys

	# don't start daemons on first install
	sudo cp files/usr/sbin/policy-rc.d /mnt/usr/sbin/policy-rc.d
	echo root:kosagi | sudo chroot /mnt /usr/sbin/chpasswd

	# install some basic things needed to kick of the networking etc...
	sudo cp files/etc/hostname /mnt/etc/hostname
	sudo cp files/etc/hosts /mnt/etc/hosts
	sudo cp files/etc/fstab /mnt/etc/fstab
	sudo cp files/etc/network/interfaces /mnt/etc/network/interfaces
	sudo cp files/etc/apt/sources.list.d/kosagi.list /mnt/etc/apt/sources.list.d/kosagi.list
	sudo cp files/etc/apt/sources.list /mnt/etc/apt/sources.list
	
	# pull in some upstream binaries
	sudo cp files/kosagi.gpg.key /mnt/root/kosagi.gpg.key
	sudo chroot /mnt apt-key add /root/kosagi.gpg.key
	sudo chroot /mnt apt-get update -y
	sudo chroot /mnt env DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive apt-get install -y imx-sdma-firmware
	sudo chroot /mnt apt-get clean -y

	# install kernel binaries
	sudo cp *${NOVENA_KVERSION}*.deb  /mnt/root
	sudo cp linux-libc-dev_1.2_armhf.deb /mnt/root
	sudo chroot /mnt dpkg -i /root/linux-firmware-image-${NOVENA_KVERSION}_armhf.deb
	sudo chroot /mnt dpkg -i /root/linux-image-${NOVENA_KVERSION}_armhf.deb
	sudo chroot /mnt dpkg -i /root/linux-headers-${NOVENA_KVERSION}_armhf.deb

	# post install some configuration files	
	sudo mkdir -p /mnt/etc/X11
	sudo cp files/etc/X11/xorg.conf /mnt/etc/X11/xorg.conf
	sudo cp files/etc/inittab /mnt/etc/inittab
	sudo cp files/etc/default/locale /mnt/etc/default/locale

	# setup boot loader and copy kernel
	sudo mkdir -p /mnt/boot/bootloader
	sudo mount /dev/mapper/loop0p1 /mnt/boot/bootloader
	sudo cp novena-linux/arch/arm/boot/uImage /mnt/boot/bootloader/uImage
	sudo cp novena-linux/arch/arm/boot/uImage /mnt/boot/bootloader/uImage.recovery
	sudo cp novena-linux/arch/arm/boot/dts/imx6q-novena.dtb /mnt/boot/bootloader/uImage.dtb
	sudo cp novena-linux/arch/arm/boot/dts/imx6q-novena.dtb /mnt/boot/bootloader/uImage.recovery.dtb
	sudo cp bootscripts/boot.scr /mnt/boot/bootloader/boot.scr
	sudo cp bootscripts/boot.scr /mnt/boot/bootloader/boot-default.scr

	# clean up and unmount things
	sudo rm /mnt/usr/sbin/policy-rc.d
	sudo chroot /mnt umount /proc
	sudo chroot /mnt umount /sys
	sudo umount /mnt/dev/pts
	sudo umount /mnt/dev

	sudo umount /mnt/boot/bootloader
	sudo umount /mnt
	sudo kpartx -v -d novena.img

	sudo dd if=u-boot-imx6/u-boot.imx of=novena.img seek=2 bs=512 conv=notrunc

## Boot scripts
boot.scr: bootscripts/boot.scr

bootscripts/boot.scr: bootscripts/boot.script
	mkimage -A arm -O linux -a 0 -e 0 -T script -C none -n "Boot script" -d bootscripts/boot.script bootscripts/boot.scr

bootscripts/boot-recovery.scr: bootscripts/boot-recovery.script
	mkimage -A arm -O linux -a 0 -e 0 -T script -C none -n "Boot script" -d bootscripts/boot-recovery.script bootscripts/boot-recovery.scr


## helper targets - these really should be cleaned up
uImage: novena-linux/arch/arm/boot/uImage

novena-linux/arch/arm/boot/uImage:
	#cd novena-linux && git checkout ${KERNEL_GIT_VERSION} && make novena_defconfig && make uImage LOADADDR=10008000 -j 4 && make ARCH=arm imx6q-novena.dtb
	cd novena-linux && git remote add qbcode git@github.com:qbcode/novena-linux.git
	cd novena-linux && git checkout ${KERNEL_GIT_VERSION} && cp ../custom.config .config && make uImage LOADADDR=10008000 -j 4 && make ARCH=arm imx6q-novena.dtb

kerneldeb: linux-libc-dev_1.2_armhf.deb

linux-libc-dev_1.2_armhf.deb:
	cp files/debian-build.sh novena-linux && cd novena-linux && git checkout ${KERNEL_GIT_VERSION} && make novena_defconfig && ./debian-build.sh

u-boot: u-boot-imx6/u-boot.imx

u-boot-imx6/u-boot.imx:
	cd u-boot-imx6 && make novena_config && make

sdcard:
	sudo dd if=novena.img of=/dev/mmcblk1 bs=1M


## cleanup
clean:
	-rm -f bootscripts/*.scr

dist-clean: clean
	-sudo umount -f /mnt/boot/bootloader
	-sudo umount -f /mnt
	-sudo losetup -d /dev/loop0
	-sudo kpartx -v -d novena.img
	-rm -f novena.img novena-recovery.img
