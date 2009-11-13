#!/sbin/sh
#
# Copyright 2006 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# $Id: fs_root_code_clofi.sh 113977 2006-10-10 13:00:37Z root $
#

livecd_mnt=/.livecd
lofidev1=/dev/lofi/1
fs_type="hsfs"
#
# Mount directories from CD.
#
if [ -x /sbin/mdisco ]; then
	install_srv=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/iso_nfs_path/{;n;p;}'|/usr/bin/sed -e "s/^\s*value=\|'//g"`
	/sbin/mount -o remount /
	/usr/sbin/devfsadm -c disk

	read livecd_volid < /.volid
	platform=`/bin/uname -i 2>/dev/msglog`
	echo "CD-ROM: \c" >/dev/msglog
	if [ "${platform}" = "i86xpv"  ]; then
		sleep 10
		dev_phys=`/sbin/mdisco 2>/dev/msglog`
	else
		if test "x$install_srv" = x; then
			dev_phys=`/sbin/mdisco -V ${livecd_volid} -l 2>/dev/msglog`
			if [ $? != 0 ]; then
				sleep 10
				dev_phys=`/sbin/mdisco -l 2>/dev/msglog`
			fi
		else
			dev_phys=${install_srv}
			fs_type="nfs -o ro"
			`/sbin/ifconfig -a dhcp`
		fi
	fi
	if [ $? != 0 ]; then
		echo "discovery failed" >/dev/msglog
	else
		echo "${dev_phys}" >/dev/msglog
		/sbin/mount -F ${fs_type} ${dev_phys} ${livecd_mnt} 2>/dev/msglog
		if [ $? != 0 ]; then
			echo "error mounting ${livecd_mnt} on ${dev_phys}" \
			    >/dev/msglog
		else
			read clofi_archive < /.clofi_archive
			/usr/sbin/lofiadm -a ${livecd_mnt}/${clofi_archive} 2>/dev/null
			/usr/sbin/devfsadm -i lofi
			/usr/sbin/lofiadm -a ${livecd_mnt}/${clofi_archive} 2>/dev/null
			/usr/sbin/devfsadm -i lofi
			/sbin/mount -F hsfs `/usr/sbin/lofiadm ${livecd_mnt}/${clofi_archive}` /usr 2>/dev/msglog
			/sbin/mount -o remount /usr
		fi
	fi
fi
