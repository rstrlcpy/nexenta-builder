#!/bin/bash
#
# Copyright 2005 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# $Id: fs_root_code.sh 15992 2006-02-07 03:15:20Z mac $
#

livecd_mnt=/.livecd
dirlist=/.cd_dirlist
fs_type="hsfs"

livecd_domount()
{
	if [ ! -d $2 ]; then
		/bin/mkdir -p $2
	fi
	${livecd_mnt}/root/usr/lib/fs/lofs/mount -m -O $1 $2
	/sbin/mount -O -o remount $1 $2
	if [ $? != 0 ]; then
		echo "unable to mount $2 on $1" >/dev/msglog
	fi
}

#
# Mount from LiveCD.
#
if [ -x /usr/bin/mdisco ]; then
	install_srv=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/iso_nfs_path/{;n;p;}'|/usr/bin/sed -e "s/^[[:space:]]*value=//g" | /usr/bin/sed -e "s/'//g"`
	/sbin/mount -o remount /
	/usr/sbin/devfsadm -c disk

	read livecd_volid < /.volid
	platform=`/bin/uname -i 2>/dev/msglog`
	echo "CD-ROM: \c" >/dev/msglog
	if [ "${platform}" = "i86xpv" ]; then
		sleep 10
		dev_phys=`/sbin/mdisco 2>/dev/msglog`
	else
		if test "x$install_srv" = x; then
			dev_phys=`/usr/bin/mdisco -V ${livecd_volid} -l 2>/dev/msglog`
			if [ $? != 0 ]; then
				sleep 10
				dev_phys=`/usr/bin/mdisco -l 2>/dev/msglog`
			fi
		else
			dev_phys=${install_srv}
			fs_type="nfs -o ro,vers=3"
			`/sbin/ifconfig -a dhcp`
		fi
	fi
if [ $? != 0 ]; then
		echo "discovery failed" >/dev/msglog

	else
		echo "${dev_phys}" >/dev/msglog
		install_srv=`echo ${install_srv} | sed -r -e "s/^[0-9.]+://"`
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
			while read dir
			do
				livecd_domount ${livecd_mnt}/root/${dir} /${dir}
			done < ${dirlist}
		fi
	fi
fi
