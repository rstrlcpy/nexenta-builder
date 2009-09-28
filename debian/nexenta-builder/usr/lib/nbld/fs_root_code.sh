#!/sbin/sh
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
if [ -x /sbin/mdisco ]; then
	install_srv=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/install_server/{;n;p;}'|/usr/bin/sed -e "s/^\s*value=\|'//g"`
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
		/sbin/mount -F ${fs_type} ${dev_phys} ${livecd_mnt}
		if [ $? != 0 ]; then
			echo "error mounting ${livecd_mnt} on ${dev_phys}" \
			    >/dev/msglog
		else
			while read dir
			do
				livecd_domount ${livecd_mnt}/root/${dir} /${dir}
			done < ${dirlist}
		fi
	fi
fi
