#!/sbin/sh
#
# Copyright 2006 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# $Id: fs_root_code_zfs.sh 113977 2006-10-10 13:00:37Z root $
#

livecd_mnt=/.livecd
pool_mnt=""
fs_type="hsfs"

livecd_mountpool()
{
	read pool < /.pool_name
	read pool_mnt < /.pool_mnt

	/usr/sbin/zpool import -f -d ${livecd_mnt} ${pool}
	if [ $? != 0 ]; then
		echo "unable to import ZFS pool ${pool} in ${livecd_mnt}" \
		     >/dev/msglog
		return 1
	fi
	return 0
}

livecd_domount()
{
	if [ ! -d $2 ]; then
		/bin/mkdir -p $2
	fi
	${pool_mnt}/usr/lib/fs/lofs/mount -m -O $1 $2
	/sbin/mount -O -o remount $1 $2
	if [ $? != 0 ]; then
		echo "unable to mount $2 on $1" >/dev/msglog
	fi
}

#
# Mount directories from CD.
#
if [ -x /sbin/mdisco ]; then
	install_srv=`/usr/sbin/prtconf -v /devices|/usr/bin/sed -n '/install_server/{;n;p;}'|/usr/bin/sed -e "s/^\s*value=\|'//g"`
	/sbin/mount -o remount /
	/usr/sbin/devfsadm

	read livecd_volid < /.volid
	platform=`/bin/uname -i 2>/dev/msglog`
	echo "CD-ROM: \c" >/dev/msglog
	if [ "${platform}" = "i86xpv" ]; then
		sleep 10
		dev_phys=`/sbin/mdisco 2>/dev/msglog`
	else
		if test "x$install_srv" = x; then
			dev_phys=`/sbin/mdisco -V ${livecd_volid} 2>/dev/msglog`
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
			livecd_mountpool && while read dir; do
				livecd_domount ${pool_mnt}/${dir} /${dir}
			done < /.cd_dirlist
		fi
	fi
fi
