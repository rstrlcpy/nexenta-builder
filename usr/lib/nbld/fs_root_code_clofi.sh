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
	iso_local=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/iso_local/{;n;p;}'|/usr/bin/sed -e "s/^\s*value=\|'//g"`
	/sbin/mount -o remount /
	/usr/sbin/devfsadm -c disk

	read livecd_volid < /.volid
	platform=`/bin/uname -i 2>/dev/msglog`
	echo "CD-ROM: \c" >/dev/msglog
	if [ "${platform}" = "i86xpv" ]; then
		sleep 10
		dev_phys=`/sbin/mdisco -l 2>/dev/msglog`
		dev_phys=`echo $dev_phys | uniq`
	else
		if test "x$install_srv" = x; then
			if test "x$iso_local" != "x"; then
				# TODO:
				# select partition
				echo "$iso_local\c" >/dev/msglog
			else
				dev_phys=`/sbin/mdisco -V ${livecd_volid} -l 2>/dev/msglog`
				if [ $? != 0 ]; then
					sleep 10
					dev_phys=`/sbin/mdisco -l 2>/dev/msglog`
				fi
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
		install_srv=`echo ${install_srv} | sed -e "s/^[0-9.]+://"`
		while :; do
			/sbin/mount -F ${fs_type} ${dev_phys} ${livecd_mnt} 2>/dev/msglog
			if [ $? != 0 ]; then
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
		if [ $rc != 0 ]; then
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
