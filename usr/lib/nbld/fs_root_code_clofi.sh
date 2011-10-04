#!/bin/bash
#
# Copyright 2006 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# $Id: fs_root_code_clofi.sh 113977 2006-10-10 13:00:37Z root $
#

livecd_mnt=/.livecd
lofidev1=/dev/lofi/1
fs_type="hsfs"
usb_mountpoint="/mnt"

mount_usb_flash()
{
	cdrom_devices=`/usr/bin/mdisco -l | /usr/bin/sed -e 's/\/dev\/dsk\///'`
	disk_devices=`/usr/bin/mdisco -ld | /usr/bin/sed -e 's/\/dev\/dsk\///'`
	for disk in $disk_devices; do
		# Skip non-removable devices
		ls -1 /dev/removable-media/rdsk/$disk 2>>/dev/null 1>&2
		if [ $? -ne 0 ]; then
			continue
		fi
		# Skip cd-rom devices
		echo $cdrom_devices | grep $disk 2>>/dev/null 1>&2
		if [ $? -eq 0 ]; then
			continue
		fi
		# Is available disk?
		/sbin/fdisk -G /dev/removable-media/rdsk/$disk 2>>/dev/null 1>&2
		if [ $? -eq 0 ]; then
			removable_devs="$removable_devs $disk"
		fi
	done
	for rem_dev in $removable_devs; do
		rem_dev=`echo $rem_dev | /usr/bin/sed -e 's/p0/p1/'`
		/sbin/mount -F pcfs /dev/removable-media/dsk/$rem_dev $usb_mountpoint 2>>/dev/null 1>&2
		if [ $? -eq 0 ]; then
			ls -1 $usb_mountpoint/$iso_usb 2>>/dev/null 1>&2
			if [ $? -eq 0 ]; then
				break
			fi
			/sbin/umount /dev/removable-media/dsk/$rem_dev 2>>/dev/null 1>&2
		fi
	done

}

#
# Mount directories from CD.
#
if [ -x /usr/bin/mdisco ]; then
	install_srv=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/iso_nfs_path/{;n;p;}'|/usr/bin/sed -e "s/^[[:space:]]*value=//" | /usr/bin/sed -e "s/'//g"`
	iso_usb=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/iso_usb/{;n;p;}'|/usr/bin/sed -e "s/^[[:space:]]*value=//" | /usr/bin/sed -e "s/'//g"`
	/sbin/mount -o remount /
	/usr/sbin/devfsadm -c disk
	read livecd_volid < /.volid
	platform=`/bin/uname -i 2>/dev/msglog`
	echo "CD-ROM: \c" >/dev/msglog
	if [ "${platform}" = "i86xpv" ]; then
		sleep 10
		dev_phys=`/usr/bin/mdisco -l 2>/dev/msglog | uniq`
	else
		if test "x$install_srv" = x; then
			if test "x$iso_usb" != "x"; then
				mount_usb_flash
				/usr/sbin/devfsadm -C
				dev_phys=`/usr/sbin/lofiadm -a $usb_mountpoint/$iso_usb`
			else
				dev_phys=`/usr/bin/mdisco -V ${livecd_volid} -l 2>/dev/msglog`
				if [ $? -ne 0 ]; then
					sleep 10
					dev_phys=`/usr/bin/mdisco -l 2>/dev/msglog`
				fi
			fi
		else
			dev_phys=${install_srv}
			fs_type="nfs -o ro,vers=3"
			`/sbin/ifconfig -a dhcp`
		fi
	fi
	if [ $? -ne 0 ]; then
		echo "discovery failed" >/dev/msglog
	else
		echo "${dev_phys}" >/dev/msglog
		install_srv=`echo ${install_srv} | sed -e "s/^[0-9.]+://"`
		while :; do
			/sbin/mount -F ${fs_type} ${dev_phys} ${livecd_mnt} 2>/dev/msglog
			if [ $? -ne 0 ]; then
				if [ "$fs_type" = "hsfs" ]; then
					rc=1; break
				else
					path_to_root="$(echo ${dev_phys} | egrep -o "/[a-zA-Z0-9_-]+$")$path_to_root"
					dev_phys=`echo ${dev_phys} | sed -e "s/\/[a-zA-Z0-9_-]+$//g"`
					if [ "${path_to_root}" = "${install_srv}" ]; then
						rc=1; break
					fi
				fi
			else
				rc=0; break
			fi
		done
		if [ $rc -ne 0 ]; then
			echo "error mounting ${livecd_mnt} on ${dev_phys}" \
			    >/dev/msglog
		else
			livecd_mnt="${livecd_mnt}${path_to_root}"
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
