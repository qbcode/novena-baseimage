%.scr: %.script
	mkimage -A arm -O linux -a 0 -e 0 -T script -C none -n "Boot script" -d $< $@
