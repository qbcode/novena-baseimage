novena-baseimage
================

To build a base image you need a functioning novena machine running debian
wheezy or else a qemu virtual machine emulating the armv7 architecture
running debian wheezy.

The basic steps are

	git clone https://github.com/qbcode/novena-baseimage
	cd novena-baseimage
	make deps
	git submodule init
	git submodule update
	make novena.img

You will need passwordless sudo to make your life easier as most of the
commands require root.

Have a look at the makefile to see how things work, it is currently a
mess and can be cleaned up.

Notes:
------

Alternative kernel:

* https://github.com/linux4kix/linux-linaro-stable-mx6
  * https://dl.dropboxusercontent.com/u/736509/imx_drm/3.14_imx_drm_config
