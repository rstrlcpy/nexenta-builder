#!/bin/bash
#
# Copyright 2005-2011 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# $Id: nexenta-install.sh 114900 2006-12-07 19:07:17Z joe $
#
# Generic Nexenta installation with removable drive support

pkill -9 dialog 2>/dev/null
clear
echo "Initializing Installer. Please wait..."

LOGFILE=/tmp/nexenta-install.log
rm -f $LOGFILE

exec 3<>$LOGFILE
exec 2>&3
printlog() {
	echo "* $*" >&3
	if test "x$auto_install" = "x1"; then
		echo "PXE-INST-MSG: $*" | /usr/nexenta/remote-logger "--host=$loghost" "--port=$logport"
	fi
}
printlog "Press CTRL-C to refresh."
printlog "Installer started at '`date`'. Logging."

export LOGNAME=root
export HOME=/root
export PS1="\W> "
export TERMINFO=/usr/share/lib/terminfo
export TERM=sun-color
export PATH=/bin:/sbin:/usr/sbin:/usr/bin:$PATH

TITLE="NexentaOS"
BOOT_ANYWHERE=${BOOT_ANYWHERE:-0}
MEMSCRATCH=${MEMSCRATCH:-0}
CURDIR=${PWD}
ISO_MOUNT_POINT=/.livecd
EXTRADEBDIR=$ISO_MOUNT_POINT/extradebs
PROFILE_DIR=$ISO_MOUNT_POINT/install_profiles
PROFILE_BASE=machine
PROFILE_STATUS=""
EXTRADEB_PROFILE=$EXTRADEBDIR/defaults
RMFORMAT_TMP=/tmp/rmformat.$$
TMP_FILE=/tmp/installer.$$
RM_LABEL="NEXENTA"
RM_DISK=""
UPGRADE_DISK=""
UPGRADE=0
CUSTOM_REPO=$1
REPO=${CUSTOM_REPO:=/usr/nexenta}
DEFPROFILE=$REPO/defaults
TMPDEST=/tmp/dest.$$
UPGRADE_LOG=$TMPDEST/var/tmp/nexenta_upgrade.log
UPGRADE_SCRIPT=$TMPDEST/upgrade-base.sh
TMPREPO=/tmp/dest.$$/tmp/repo
DBFILE=/tmp/repository.db.$$
UPMAP=/tmp/upgrade.map.$$
RDMAP=/tmp/rmdrive.map.$$
TMPMESSAGES=/tmp/messages.$$
FIRSTSTART=/.nexenta-first-start
LICENSELOC=/.license-location
testusr=n3x3nt4
signature=`date '+%F-%N'`
sysmem=`prtconf | grep 'Memory size:' | nawk '{ print $3 }'`
set -i reposize
set -i spaceneeded
DU=/usr/bin/du
test -f /usr/gnu/bin/du && DU=/usr/gnu/bin/du
reposize=`$DU $REPO/dists -B MB -c --summarize | grep total | sed -e 's/MB//g' | nawk '{ print $1 }'`
(( spaceneeded=reposize*3 ))
DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_ESC=255
export KEEP_COLORS=1
DIALOG_RES=/tmp/dialog_result.$$
AUTOPART_SWAP_SIZE=$sysmem
test $AUTOPART_SWAP_SIZE -gt 1024 && AUTOPART_SWAP_SIZE=1024 # but no more than 1G
AUTOPART_ROOT_SIZE=8192
AUTOPART_MIN_EXPORT=2048
AUTOPART_MIN_SWAP=256
AUTOPART_CMD_FILE=/tmp/autopart_cmds.tmp
AUTOPART_FMT_ERR=/tmp/autopart_format_err.tmp
CMD_FILE=/tmp/manual-format-cmds.$$
PART_TABLE=/tmp/manual-part-table.$$
ZPOOL_HOME="home"
DEFAULT_PROFILE="minimal"
SELECTED_KBD_TYPE="US-English"
MIN_MEM_REQUIRED=384

ZFS_ROOTPOOL="syspool"
ZFS_ROOTFS="$ZFS_ROOTPOOL/rootfs-nmu-000"
ROOTDISK_TYPE="ufs"

ROOTPOOL_ZVOL_DIR="/dev/zvol/dsk/$ZFS_ROOTPOOL"
rawdump="dump"

TZDIR=/usr/share/lib/zoneinfo
TZ_COUNTRY_TABLE=$TZDIR/tab/country.tab
TZ_ZONE_TABLE=$TZDIR/tab/zone_sun.tab
TZ_for_date=""
newline='
'
#INFO_EXTRA1="Local time is now:       %s"
#INFO_EXTRA2="Universal Time is now:   %s"
INFO_TZ="Therefore TZ='%s' will be used."
result_disk_pool=""
result_disk_spare=""

auto_install=""
MACHINESIG=""
dialog_cmd() {
	echo dialog\ --backtitle\ $TITLE-Installer-$MACHINESIG\ --keep-window\ --colors\ --no-signals\ --no-escape
}
dialog_cmd_with_escape() {
	echo dialog\ --backtitle\ $TITLE-Installer-$MACHINESIG\ --keep-window\ --colors\ --no-signals
}
DIALOG_WITH_ESC="$(dialog_cmd_with_escape)"
DIALOG="$(dialog_cmd)"

oneline_msgbox_slim() {
	$DIALOG --title " $1 " --msgbox "$2" 0 0
}

oneline_msgbox() {
	test "x$1" = xError && printlog $(echo "Error: $2"|sed -e "s/\n//g")
	$DIALOG --title " $1 " --msgbox "
  $2

" 0 -1
}

oneline_info() {
	$DIALOG --title " Information " --infobox "
 $1" 5 70
}

oneline_yN_ask() {
	$DIALOG --title " Question " --defaultno --yesno "
 $1" 7 70
}

oneline_Yn_ask() {
	$DIALOG --title " Question " --yesno "
 $1" 7 70
}

message_Yn_ask() {
	$DIALOG --title " Question " --yesno "$1 $2" 0 0
}

callback()
{
	local func=$1
	printlog "Kick-Start: executing $func"
	shift
	if declare -f $func 2>/dev/null 1>&2; then
		eval "$func $*"
		return $?
	fi
	return 1
}

welcome_head()
{
	$DIALOG --title " Welcome " --msgbox "
               Welcome to the $TITLE Installer!

     If you intend to install $TITLE onto a removable drive
     (e.g. USB memory stick, portable hard drive, etc.), please
     make sure that the drive is currently inserted, powered on,
     and is not write protected before proceeding any further.

     You can press 'CTRL-A :quit' at anytime to quit the installer.
     Use SPACEBAR to select an entry, and TAB-UP-DOWN keys to navigate.
     Use only UP-DOWN arrow keys to navigate between input fields.
     You can also cycle through the Installer, Shell or Log by
     pressing F1-F2-F3 (or ESC-1,2,3) keys.

  ** IMPORTANT: Please backup any important data before continuing **

" 0 0
	if test $? != $DIALOG_OK; then
		aborted
	fi
}

boolean2human()
{
	if test "x$1" = x0; then
		echo "No"
	else
		echo "Yes"
	fi
}

boolean_check()
{
	# TRUE if empty or '1'
	test "x$1" = x -o "x$1" = x1
}

welcome_ks()
{
	local conf=""

	test "x$_KS_hostname" != x &&       conf="$conf     * Host Name: $_KS_hostname\n"
	test "x$_KS_domainname" != x &&     conf="$conf     * Domain Name: $_KS_domainname\n"
	test "x$_KS_root_passwd" != x &&    conf="$conf     * Root Password: See User Guide\n"
	test "x$_KS_user_name" != x &&      conf="$conf     * Default User Name: $_KS_user_name\n"
	test "x$_KS_user_passwd" != x &&    conf="$conf     * Default User Password: See User Guide\n"
	test "x$_KS_time_zone" != x &&      conf="$conf     * Default Time Zone: $_KS_time_zone\n"
	test "x$_KS_use_dhcp" != x &&       conf="$conf     * DHCP enabled: $(boolean2human $_KS_use_dhcp)\n"
	test "x$_KS_use_ipv6" != x &&       conf="$conf     * IPv6 enabled: $(boolean2human $_KS_use_ipv6)\n"
	test "x$_KS_use_grub_mbr" != x &&   conf="$conf     * Install GRUB on MBR: $(boolean2human $_KS_use_grub_mbr)\n"
	test "x$_KS_auto_reboot" != x &&    conf="$conf     * Auto Reboot: $(boolean2human $_KS_auto_reboot)\n"
	test "x$_KS_check_upgrade" != x &&  conf="$conf     * Attempt to Upgrade: $(boolean2human $_KS_check_upgrade)\n"

	$DIALOG --title " Welcome " --yesno "
    Welcome to the $TITLE Kick-Start Installer.\n\n
     Following Auto Configuration will be applied:\n\n$conf\n" 0 0
	if test $? != $DIALOG_OK; then
		aborted
	fi
}

rmdrive_info()
{
	local rmdrive=$1

	rmformat -l ${rmdrive} 2> /dev/null > ${RMFORMAT_TMP}

	if [ $? -ne 0 ]; then
		return 1
	fi

	local rmlogical=`grep "Logical Node:" ${RMFORMAT_TMP} | sed -e 's/^[ \t1-9.]*Logical Node:[ \t]*//g'`
	local rmdsk=`echo ${rmlogical} | sed -e 's/rdsk/dsk/g' | sed -e 's/p0/s0/g'`
	local rmphysical=`grep "Physical Node:" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Physical Node:[ \t]*//g'`
	local rmdevice=`grep "Connected Device:" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Connected Device:[ \t]*//g' -e 's/\s */ /g'`
	local rmtype=`grep "Device Type:" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Device Type:[ \t]*//g'`
	local rmbus=`grep -w "\<Bus\>" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Bus:[ \t]*//g'`
	local rmsize=`grep -w "\<Size\>" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Size:[ \t]*//g'`
	local rmlabel=`grep -w "\<Label\>" ${RMFORMAT_TMP} | sed -e 's/^[ \t]*Label:[ \t]*//g'`

	echo "${rmlogical}:${rmdsk}:${rmdevice}:${rmbus}:${rmtype}:${rmlabel}:${rmsize}:${rmphysical}" >> ${RDMAP}

	printlog "Detected removable device: ${rmlogical}:${rmdsk}:${rmdevice}:${rmbus}:${rmtype}:${rmlabel}:${rmsize}:${rmphysical}"

	rm ${RMFORMAT_TMP}
}

find_zpool_by_disk_and_destroy()
{
	local disk=$1
	local force_destroy=$2
	for p in `zpool list -H|awk '{print $1'}`; do
		if zpool status $p|grep $disk >/dev/null; then
			if test "x$force_destroy" != x1; then
				$DIALOG --title " Warning! "  --yesno "\n  Disk '$disk' is part of ZFS Pool '$p'.\n     Destroy '$p' and proceed?" 7 50
				if test $? == $DIALOG_OK; then
					zpool destroy -f $p
					return 0
				else
					return 1
				fi
			else
				zpool destroy -f $p
				return 0
			fi
		fi
	done
	return 0
}

######## partitioner begin ##########

part_read()
{
	local disk=$1

	fdisk -W $PART_TABLE /dev/rdsk/${disk}p0 >/dev/null 2>&1
}

part_id()
{
	local id=$1

	cat $PART_TABLE | awk -F: "/^\*.*$id/ {print \$2}" | sed -e "s/SUNIXOS/SOLARIS/" -e "s/^\s* //"
}

part_act()
{
	local act=$1
	if test $act == 128; then
		echo "Active"
	else
		echo "     -"
	fi
}

part_list_all()
{
	cat $PART_TABLE | awk '!/^\*/ && !/^$/ {print $0}'
}

part_delete()
{
	local num=$1

	rm -f $CMD_FILE
	echo 3 >> $CMD_FILE
	echo $num >> $CMD_FILE
	echo y >> $CMD_FILE
	echo 5 >> $CMD_FILE

	cat $CMD_FILE | fdisk /dev/rdsk/${disk}p0 2>&1 >/dev/null
	local rc=$?

	rm -f $CMD_FILE

	if test $rc == 0 && ! part_read $disk; then
		oneline_msgbox Error "Cannot re-read fdisk table from disk $disk. Warning! Table has be modified!"
		return 1
	elif test $rc != 0; then
		oneline_msgbox Error "Cannot update fdisk table for disk $disk."
		return $rc
	fi

	return $rc
}

part_add()
{
	local disk=$1
	local ptype=$2
	local percent=$3
	local active=$4
	local tmp_file="/tmp/part-add.$$"

	rm -f $CMD_FILE
	echo n >> $CMD_FILE
	echo 1 >> $CMD_FILE
	if test "x$ptype" = xSOLARIS2; then
		echo 1 >> $CMD_FILE
	else
		echo 4 >> $CMD_FILE
	fi
	echo $percent >> $CMD_FILE
	if test "x$active" = x1; then
		echo y >> $CMD_FILE
	else
		echo n >> $CMD_FILE
	fi
	echo 5 >> $CMD_FILE

	cat $CMD_FILE | fdisk /dev/rdsk/${disk}p0 2>&1 >/dev/null 2>$tmp_file
	local rc=$?

	local errmsg="Unknown error."
	if test "x`cat $tmp_file`" != x; then
		errmsg="`cat $tmp_file`"
		rc=1
	fi

	rm -f $CMD_FILE $tmp_file

	if test $rc == 0 && ! part_read $disk; then
		oneline_msgbox Error "Cannot re-read fdisk table from disk $disk. Warning! Table has been modified!"
		return 1
	elif test $rc != 0; then
		oneline_msgbox Error "Cannot update fdisk table for disk $disk: $errmsg"
		return $rc
	fi

	return $rc
}

part_set_active()
{
	local disk=$1
	local num=$2
	local tmp_file="/tmp/part-add.$$"

	rm -f $CMD_FILE
	echo 2 >> $CMD_FILE
	echo $num >> $CMD_FILE
	echo 5 >> $CMD_FILE

	cat $CMD_FILE | fdisk /dev/rdsk/${disk}p0 2>&1 >/dev/null 2>$tmp_file
	local rc=$?

	local errmsg="Unknown error."
	if test "x`cat $tmp_file`" != x; then
		errmsg="`cat $tmp_file`"
		rc=1
	fi

	rm -f $CMD_FILE $tmp_file

	if test $rc == 0 && ! part_read $disk; then
		oneline_msgbox Error "Cannot re-read fdisk table from disk $disk. Warning! Table has been modified!"
		return 1
	elif test $rc != 0; then
		oneline_msgbox Error "Cannot update fdisk table for disk $disk: $errmsg"
		return $rc
	fi

	return $rc
}

part_record()
{
	local entry=$1
	local fld=$2
	local num=0

	part_list_all | while read id act bhead bsect bcyl ehead esect ecyl rsect numsect; do
		let num=$num+1
		if test $num == $entry; then
			test "x$fld" = x && echo "$read $id $act $bhead $bsect $bcyl $ehead $esect $ecyl $rsect $numsect"
			test "x$fld" = xid && echo "$id"
			test "x$fld" = xact && echo "$act"
			test "x$fld" = xbhead && echo "$bhead"
			test "x$fld" = xbsect && echo "$bsect"
			test "x$fld" = xbcyl && echo "$bcyl"
			test "x$fld" = xehead && echo "$ehead"
			test "x$fld" = xesect && echo "$esect"
			test "x$fld" = xesyl && echo "$esyl"
			test "x$fld" = xrsect && echo "$rsect"
			test "x$fld" = xnumsect && echo "$numsect"
			break
		fi
	done
}

part_disk_numsect()
{
	local disk=$1

	echo $(fdisk -G /dev/rdsk/${disk}p0 | tail -1 | awk '{print 2+$1*$5*$6}')
}

part_size_mb()
{
	local disk=$1
	local numsect=$2

	echo $(fdisk -G /dev/rdsk/${disk}p0 | tail -1 | awk "{print int($numsect*\$7/1024/1024)}")
}

part_percent()
{
	local disk=$1
	local numsect=$2
	local p=1

	test "x$numsect" = x0 && p=0
	echo $(($numsect*100/$(part_disk_numsect $disk)+$p))
}

part_item_format()
{
	local disk=$1
	local act=$2
	local id=$3
	local numsect=$4

	printf "%6s     %14s     %7s     %3s\n" $(part_act $act) $(part_id $id) $(part_size_mb $disk $numsect) $(part_percent $disk $numsect)
}

part_fdisk_menu()
{
	local disk=$1
	local TOP_INFO="\\nSelect partition on which you'd like to install software or Edit selected partition.\\n\\nPress Add/Delete if you'd like to add new partition or delete selected.\\n"
	local HEAD_INFO="Id__Status___________Type___________Size(MB)___(%)\\n"
	local rlist=""
	local num=1
	local tmp_file=/tmp/part-data.$$

	while true; do
		rm -f $tmp_file
		part_list_all | while read id act bhead bsect bcyl ehead esect ecyl rsect numsect; do
			local l=$(echo "$(part_item_format $disk $act $id $numsect)"|sed -e "s/ /./g")
			echo -n "$num \"$l\" " >>$tmp_file
			let num=$num+1
		done

		if test ! -f $tmp_file || ! part_has_sol2; then
			oneline_msgbox Warning "No any 'SOLARIS2' partitions found on $disk! You will need to create at least one."
			part_add_menu $disk 1 || return 1
			continue
		fi
		break
	done

	eval $DIALOG --ok-label Continue --extra-button --extra-label Add --cancel-label Cancel --help-button --help-label Delete --title \" Partition Editor \" --menu \"$TOP_INFO\\nPlease select a partion to be edited and select Continue:\\n\\n$HEAD_INFO\" 21 54 4 `cat $tmp_file` 2>$DIALOG_RES
	local rc=$?

	rm -f $tmp_file
	return $rc
}

part_format_check_size()
{
	local avail=$1

	if test $avail -lt $(($2+$3+$4+$5+$6)); then
		oneline_msgbox Error "\nTotal size becomes greater than available ${avail}MB. Please correct.\n"
		return 1
	fi

	return 0
}

part_slice_change()
{
	local disk=$1
	local p=$2
	local s=$3

	local rlist=""
	for i in 1 3 4 5 6 7; do
		local ns="/dev/dsk/${disk}s$i"
		test "x$ns" = "x$4" -o "x$ns" = "x$5" -o "x$ns" = "x$6" -o "x$ns" = "x$7" && continue
		if test "x$ns" = "x$s"; then
			rlist="$rlist $ns unassigned on"
		else
			rlist="$rlist $ns unassigned off"
		fi
	done

	$DIALOG --defaultno --ok-label "Change" --cancel-label "Keep" --radiolist "\nWould you like to change slice for [$p] from $s?\n\nPlease select available slices from the list below or select Keep to keep [$p] => $s." 0 0 0 $rlist 2>$DIALOG_RES
	if test $? == 0; then
		test $p = "swap" && slice_swap=$(dialog_res)
		test $p = "/export/home" && slice_export_home=$(dialog_res)
		test $p = "/opt" && slice_opt=$(dialog_res)
		test $p = "/var" && slice_var=$(dialog_res)
	fi
}

part_cleanup_unassigned()
{
	test "x$slice_swap" = xunassigned && slice_swap=
	test "x$slice_export_home" = xunassigned && slice_export_home=
	test "x$slice_var" = xunassigned && slice_var=
	test "x$slice_opt" = xunassigned && slice_opt=
}

part_format_menu()
{
	local disk=$1
	local num=$2
	local rc=0
	local avail="$(part_size_mb $disk $(part_record $num numsect))"

	if test "x$avail" = x; then
		oneline_msgbox Error "\nCould not detect available partition size on $disk. Please select another partition.\n"
		return 1
	fi

	local size_root_min=${_KS_profile_rootsize[$_KS_profile_selected]}

	local size_root=$(($avail-$AUTOPART_MIN_SWAP))
	local size_swap=$AUTOPART_MIN_SWAP
	local size_export_home=0
	local size_opt=0
	local size_var=0
	slice_root="/dev/dsk/${disk}s0"
	slice_swap="/dev/dsk/${disk}s7"
	slice_export_home="unassigned"

	minimal_allowed=$(($size_root_min+$AUTOPART_MIN_SWAP))
	if test $minimal_allowed -gt $avail; then
		oneline_msgbox Error "\nSelected partition size less than minimal allowed ${minimal_allowed}MB. Please select another partition.\n"
		return 1
	elif test $(($AUTOPART_ROOT_SIZE+$AUTOPART_MIN_EXPORT+$AUTOPART_SWAP_SIZE)) -lt $avail; then
		size_root=$AUTOPART_ROOT_SIZE
		size_swap=$AUTOPART_SWAP_SIZE
		size_export_home=$(($avail-$AUTOPART_ROOT_SIZE-$AUTOPART_SWAP_SIZE))
		slice_export_home="/dev/dsk/${disk}s1"
	elif test $(($size_root_min+$AUTOPART_SWAP_SIZE)) -lt $avail; then
		size_root=$(($avail-$AUTOPART_SWAP_SIZE))
		size_swap=$AUTOPART_SWAP_SIZE
	fi

	slice_opt="unassigned"
	slice_var="unassigned"

	while test $rc != 1 && test $rc != 250; do
		$DIALOG --ok-label "Continue" \
		              --extra-label "Edit" \
			      --inputmenu "Now partitioning disk '$disk'. You will need to assign slice sizes in megabytes. Total available size is ${avail}MB. You can adjust slice sizes and assignments by selecting Edit. Zero-sized slices will not be created.\n" \
			      21 65 10 \
			      "1.[/]-($slice_root):"                    "$size_root" \
			      "2.[swap]-($slice_swap):"                 "$size_swap" \
			      "3.[/export/home]-($slice_export_home):"  "$size_export_home" \
			      "4.[/var]-($slice_var):"                  "$size_var" \
			      "5.[/opt]-($slice_opt):"                  "$size_opt" \
			      2>$DIALOG_RES
		rc=$?
		if test $rc == 0; then
			# Continue case
			local msg="\nNext slices selected to be FORMATTED:\n"
			msg="$msg\n[/] => $slice_root (${size_root}MB)"
			test "x$size_swap" != x0 && msg="$msg\n[swap] => $slice_swap (${size_swap}MB)"
			test "x$size_export_home" != x0 && msg="$msg\n[/export/home] => $slice_export_home (${size_export_home}MB)"
			test "x$size_var" != x0 && msg="$msg\n[/var] => $slice_var (${size_var}MB)"
			test "x$size_opt" != x0 && msg="$msg\n[/opt] => $slice_opt (${size_opt}MB)"
			msg="$msg\n\n"
			message_Yn_ask "$msg" "Are you done with slicing and ready format?\n\n"
			test $? != $DIALOG_OK && continue
			break
		elif test $rc == 3; then
			# Edit case
			tag=`echo "$(dialog_res)" |sed -e 's/^RENAMED //' -e 's/:.*//'`
			item=`echo "$(dialog_res)" |sed -e 's/^.*:[ ]*//' -e 's/[ ]*$//'`
			test "x$item" = x && item=0
			test $item -gt 0 2>/dev/null || item=0
			case "$tag" in
			1.*)
				if test $item -lt $size_root_min; then
					oneline_msgbox Error "\nSize of root slice less than ${size_root_min}MB not allowed. Please correct.\n"
					continue
				fi
				part_format_check_size $avail $item $size_swap $size_export_home $size_var $size_opt || continue
				size_root="$item"
				;;
			2.*)
				if test $item == 0; then
					slice_swap="unassigned"
				else
					slice_swap="/dev/dsk/${disk}s7"
					part_format_check_size $avail $size_root $item $size_export_home $size_var $size_opt || continue
					part_slice_change $disk "swap" $slice_swap $slice_root $slice_export_home $slice_var $slice_opt
				fi
				size_swap="$item"
				;;
			3.*)
				if test $item == 0; then
					slice_export_home="unassigned"
				else
					slice_export_home="/dev/dsk/${disk}s1"
					part_format_check_size $avail $size_root $size_swap $item $size_var $size_opt || continue
					part_slice_change $disk "/export/home" $slice_export_home $slice_root $slice_swap $slice_var $slice_opt
				fi
				size_export_home="$item"
				;;
			4.*)
				if test $item == 0; then
					slice_var="unassigned"
				else
					slice_var="/dev/dsk/${disk}s3"
					part_format_check_size $avail $size_root $size_swap $size_export_home $item $size_opt || continue
					part_slice_change $disk "/var" $slice_var $slice_root $slice_swap $slice_export_home $slice_opt
				fi
				size_var="$item"
				;;
			5.*)
				if test $item == 0; then
					slice_opt="unassigned"
				else
					slice_opt="/dev/dsk/${disk}s4"
					part_format_check_size $avail $size_root $size_swap $size_export_home $size_var $item || continue
					part_slice_change $disk "/opt" $slice_opt $slice_root $slice_swap $slice_export_home $slice_var
				fi
				size_opt="$item"
				;;
			esac

		else
			# Cancel case
			slice_root=
			slice_swap=
			slice_export_home=
			slice_opt=
			slice_var=
			return 1
		fi
	done

	oneline_info "Slicing selected partition on disk $disk. Please wait..."

	fdisk -B ${disk}p0 2>/dev/null

	local i
	echo p > $AUTOPART_CMD_FILE
	for i in 0 1 3 4 5 6 7; do
		echo $i >> $AUTOPART_CMD_FILE
		echo unassigned >> $AUTOPART_CMD_FILE
		echo wm >> $AUTOPART_CMD_FILE
		echo 0 >> $AUTOPART_CMD_FILE
		echo 0c >> $AUTOPART_CMD_FILE
	done
	echo q >> $AUTOPART_CMD_FILE
	echo label >> $AUTOPART_CMD_FILE
	echo 0 >> $AUTOPART_CMD_FILE
	echo q >> $AUTOPART_CMD_FILE
        format -ef $AUTOPART_CMD_FILE -d $disk >/dev/null 2>$AUTOPART_FMT_ERR
        if test $? != 0; then
                oneline_msgbox Error "Cannot slice disk $disk. Got error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
		rm -f $AUTOPART_CMD_FILE $AUTOPART_FMT_ERR
		part_cleanup_unassigned
                return 1
        fi
	rm -f $AUTOPART_CMD_FILE $AUTOPART_FMT_ERR

	local phys="/dev/rdsk/${disk}p0"
	local csize="$(fdisk -G $phys | tail -1 | awk '{print $5*$6*$7}')"
	local slice
	local sectnum=3
	local cyls=0

	let size_root=($size_root*1024*1024-$csize*3)/1024/1024

	fdisk -B ${disk}p0 2>/dev/null

	echo p > $AUTOPART_CMD_FILE
	for item in "$slice_root:$size_root" "$slice_swap:$size_swap" "$slice_export_home:$size_export_home" "$slice_var:$size_var" "$slice_opt:$size_opt"; do

		test "x$item" = "xunassigned:0" && continue

		local slice=$(echo $item|awk -F: '{print $1}'|sed -e "s/.*s\([0-9]\+\)/\1/")
		local size=$(echo $item|awk -F: '{print $2}')
		local label="unassigned"
		cyls=$(($size*1024*1024/$csize-2))

		test $sectnum == 3 && label="root"

		echo $slice >> $AUTOPART_CMD_FILE
		echo $label >> $AUTOPART_CMD_FILE
		echo wm >> $AUTOPART_CMD_FILE
		echo $sectnum >> $AUTOPART_CMD_FILE
		echo ${cyls}c >> $AUTOPART_CMD_FILE

		printlog "Slice$slice: $cyls cylinders"

		let sectnum=$sectnum+$cyls+1
	done
	echo q >> $AUTOPART_CMD_FILE
	echo label >> $AUTOPART_CMD_FILE
	echo 0 >> $AUTOPART_CMD_FILE
	echo q >> $AUTOPART_CMD_FILE
        format -ef $AUTOPART_CMD_FILE -d $disk >/dev/null 2>$AUTOPART_FMT_ERR
        if test $? != 0; then
                oneline_msgbox Error "Cannot slice disk $disk. Got error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
		rm -f $AUTOPART_CMD_FILE $AUTOPART_FMT_ERR
		part_cleanup_unassigned
                return 1
        fi
	rm -f $AUTOPART_CMD_FILE $AUTOPART_FMT_ERR

	part_cleanup_unassigned

	if test "x$ROOTDISK_TYPE" != xzfs; then
		if mntfmt_do "$slice_root" $TMPDEST; then
			test "x$slice_usr" != x &&
				mntfmt_do $slice_usr $TMPDEST/usr
			test "x$slice_var" != x &&
				mntfmt_do $slice_var $TMPDEST/var
			test "x$slice_opt" != x &&
				mntfmt_do $slice_opt $TMPDEST/opt
			test "x$slice_export_home" != x &&
				mntfmt_do "$slice_export_home" $TMPDEST/export/home "zfs"
		else
			oneline_info "Cannot format/mount root! Giving up..."
			return 1
		fi
	fi

	return 0
}

part_total_numsect()
{
	local tmp_file=/tmp/part-data.$$
	local total=0
	local tmp_file=/tmp/part-data.$$

	rm -f $tmp_file
	part_list_all | while read id act bhead bsect bcyl ehead esect ecyl rsect numsect; do
		let total=$total+$numsect
		echo $total > $tmp_file
	done

	if test ! -f $tmp_file; then
		echo "0"
		return
	fi

	read total < $tmp_file
	rm -f $tmp_file

	echo $total
}

part_has_sol2()
{
	local tmp_file=/tmp/part-has-sol2.$$
	local num=0
	local rc=1

	rm -f $tmp_file
	part_list_all | while read id act bhead bsect bcyl ehead esect ecyl rsect numsect; do
		let num=$num+1
		test $(part_record $num id) == 191 && touch $tmp_file
	done
	test -f $tmp_file && rc=0
	rm -f $tmp_file
	return $rc
}

part_add_menu()
{
	local disk=$1
	local active=$2
	local total=$(part_total_numsect)
	local avail=$((100-$(part_percent $disk $total)))

	if test $avail -le 1; then
		oneline_msgbox Error "You do not have enough space on selected disk $disk. Please correct."
		return 1
	fi

	local TOP_INFO="\nType should be a string: SOLARIS2 or OTHEROS.\nAvailable percentage range 1..$avail%.\n\n"
	local T=SOLARIS2
	local P=$avail

	while true; do
		$DIALOG --title " Adding new fdisk partition " \
			--form "$TOP_INFO" 15 50 5 \
			"Type:" 2 2 $T 2 16 30 14 \
			"Percentage:" 4 2 $P 4 16 4 3 2>$DIALOG_RES
		local rc=$?
		local sel_type=$(cat $DIALOG_RES|head -1)
		local sel_percent=$(cat $DIALOG_RES|tail -1)
		if test $rc == $DIALOG_OK; then
			if test "x$sel_type" != xSOLARIS2 -a "x$sel_type" != xOTHEROS; then
				oneline_msgbox Error "Not allowed partition type '$sel_type'. Please correct."
				T=$sel_type
				continue
			fi
			if test "x$sel_type" = xSOLARIS2 && part_has_sol2; then
				oneline_msgbox Error "Disk $disk already has SOLARIS2 partition. Please correct."
				return 1
			fi
			if test "x$sel_percent" = x ||
			   ! test $sel_percent -gt 0 2>/dev/null ||
			   test $sel_percent -gt $avail -o $sel_percent -lt 1; then
				oneline_msgbox Error "Entered percentage '$sel_percent' is not in a range 1...$avail. Please correct."
				P=$sel_percent
				continue
			fi
			test $sel_percent != 100 -a $sel_percent == $avail && sel_percent=$(($sel_percent-1))
			part_add $disk $sel_type $sel_percent $active
			return $?
		fi
		break
	done
	return 1
}

part_manual()
{
	local disk=$1
	local modified=0
	local rc

	if [ "${RM_DISK}" != "" ]; then
		return 1
	fi

	if ! oneline_yN_ask "Warning! Manual partitioner may modify existing partitions on disk $disk. Proceed?"; then
		return 1
	fi

	oneline_info "Gathering partition information on $disk. Please wait..."

	if ! part_read $disk; then
		oneline_msgbox Error "Cannot read fdisk table from $disk."
		return 1
	fi

	while true; do
		part_fdisk_menu $disk
		rc=$?
		if test $rc == 0; then
			# Continue case
			local num=$(dialog_res)
			if test $(part_record $num id) != 191; then
				oneline_msgbox "Wrong selected partition" \
					"Only 'SOLARIS2' type partitions could be sliced. Please try again."
				continue
			fi
			if test $(part_record $num act) != 128; then
				message_Yn_ask "\nSelected partition is not marked as 'Active'" "\n\nDo you want to mark it as 'Active'?\n"
				if test $? != $DIALOG_OK; then
					oneline_msgbox "Warning!" \
						"\nYour system may not boot after installation is complete.\nYou will need to manually modify Boot Manager on active partition.\n"
				else
					part_set_active $disk $num
					modified=1
				fi
			fi
	 		part_format_menu $disk $num || continue
			rc=0
			break
		elif test $rc == 2; then
			# Delete case
			local num=$(dialog_res|awk '{print $2}')
			local id=$(part_id $(part_record $num id))
			if oneline_yN_ask "Are you sure you want to delete Id #$num ($id) ?"; then
				part_delete $num
				modified=1
			else
				oneline_info "No changes made..."
			fi
			continue
		elif test $rc == 3; then
			# Add case
			part_add_menu $disk
			modified=1
			continue
		fi
		# Cancel case
		test "x$modified" = x0 && oneline_info "No changes made. Select another disk or auto-partition..."
		rc=1
		break
	done

	rm -f $CMD_FILE $PART_TABLE 2>/dev/null

	return $rc
}

######## partitioner end ##########

autopart_zfs()
{
	local autodisks=$1
	local config=$2
	local s0_slices=$(echo $autodisks|sed -e "s/\(d[0-9]\+\)/\1s0/g")
	local hot_spare_cmd="spare $3"

	zfs_root_slices=$s0_slices

	oneline_info "Preparing $config-type ZFS volume using '$s0_slices'... "

	test ! -d $TMPDEST && mkdir -p $TMPDEST

	test $config = "pool" && config=""
	test "x$3" = "x" && hot_spare_cmd=""
	if ! zpool create -f -O compression=on -m legacy $ZFS_ROOTPOOL $config $s0_slices $hot_spare_cmd 2>$AUTOPART_FMT_ERR; then
		zpool destroy $ZFS_ROOTPOOL 2>/dev/null
		sync
		if ! zpool create -f -O compression=on -m legacy $ZFS_ROOTPOOL $config $s0_slices $hot_spare_cmd 2>$AUTOPART_FMT_ERR; then
			oneline_msgbox Error "Cannot create ZFS 'root' pool using disk(s) $disks with error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
			return 1
		fi
	fi

	if ! zfs create -o mountpoint=none "$ZFS_ROOTFS" 2>$AUTOPART_FMT_ERR; then
		oneline_msgbox Error "Cannot create $ZFS_ROOTFS filesystem with error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
		return 1
	fi

	if ! zfs set mountpoint=legacy "$ZFS_ROOTFS" 2>$AUTOPART_FMT_ERR; then
		oneline_msgbox Error "Cannot change $ZFS_ROOTFS property with error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
		return 1
	fi

	if ! zpool set bootfs=$ZFS_ROOTFS $ZFS_ROOTPOOL 2>$AUTOPART_FMT_ERR; then
		oneline_msgbox Error "Cannot change $ZFS_ROOTPOOL bootfs property with error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
		return 1
	fi

	oneline_info "Mounting [/]... "
	umount $TMPDEST 2>/dev/null
	if ! mount -F zfs "$ZFS_ROOTFS" $TMPDEST 2>/dev/null; then
		oneline_msgbox Error "Cannot mount $ZFS_ROOTFS to $TMPDEST!"
		return 1
	fi
	return 0
}

autopart()
{
	if [ "${RM_DISK}" != "" ]; then
		return 1
	fi

	local disk="/dev/dsk/${1}s0"
	local fstype=$2
	local phys="$(echo $disk|sed -e 's/dsk/rdsk/' -e 's/s0/p0/')"
	local cyls="$(fdisk -G $phys|tail -1|awk '{print $1-2}')"
	local csize="$(fdisk -G $phys | tail -1 | awk '{print $5*$6*$7}')"
	local root_min_size=${_KS_profile_rootsize[$_KS_profile_selected]}
	local root_min_bytes=$(($root_min_size*1024*1024))
	local swap_size=$AUTOPART_SWAP_SIZE
	local swap_bytes=$(($swap_size*1024*1024))

	if test $(($cyls*$csize)) -lt $root_min_bytes; then
		oneline_msgbox Error "Disk size is too small and cannot even fit a root partition.\nNeeded at least $root_min_size MB."
		return 1
	fi

	if test $(($cyls*$csize)) -lt $(($root_min_bytes+$swap_bytes)); then
		oneline_msgbox Error "Disk size is too small.\nNeeded at least $(($root_min_size+$swap_size)) MB."
		return 1
	fi

	if ! fdisk -B $phys >/dev/null 2>&1; then
		oneline_msgbox Error "Fdisk cannot apply new partition table."
		return 1
	fi

	local root_cyls=$(($AUTOPART_ROOT_SIZE*1024*1024/$csize))
	local swap_cyls=$(($swap_bytes/$csize))
	local add_cyls=$((1*1024*1024/$csize))
	test "x$add_cyls" = "x0" && add_cyls=1
	local min_export_cyls=$(($AUTOPART_MIN_EXPORT*1024*1024/$csize))
	local d="$(echo $disk|sed -e 's;/dev/dsk/\(c[0-9]\+.*d[0-9]\+\).*;\1;')"
	local slice_s3=""

	if test $fstype = "zfs"; then
		zpool create -f -m legacy tmp $d || printlog "Cannot create temporary ZFS pool on disk '$d'"
		zpool destroy tmp || printlog "Cannot destroy temporary ZFS pool on disk '$d'"
		if ! zdb -l /dev/rdsk/${d}s0 | grep devid >/dev/null; then
			printlog "Warning! Disk '$d' is not labeled correctly: devid is missing"
		fi
		dd if=/dev/zero of=/dev/rdsk/${d}p0 bs=512 count=10000 2>/dev/null 1>&2
	fi
	fdisk -B ${d}p0 2>/dev/null

	if boolean_check $_KS_autopart_use_swap_zvol; then
		echo p > $AUTOPART_CMD_FILE
		echo 0 >> $AUTOPART_CMD_FILE
		echo root >> $AUTOPART_CMD_FILE
		echo wm >> $AUTOPART_CMD_FILE
		echo 3 >> $AUTOPART_CMD_FILE
		echo $(($cyls-$add_cyls-4))c >> $AUTOPART_CMD_FILE
		printlog "Slice0: / $(($cyls-$add_cyls-4)) cylinders"
		echo 3 >> $AUTOPART_CMD_FILE
		echo alternates >> $AUTOPART_CMD_FILE
		echo wu >> $AUTOPART_CMD_FILE
		echo $(($cyls-$add_cyls-1)) >> $AUTOPART_CMD_FILE
		echo ${add_cyls}c >> $AUTOPART_CMD_FILE
		echo q >> $AUTOPART_CMD_FILE
		echo label >> $AUTOPART_CMD_FILE
		echo 0 >> $AUTOPART_CMD_FILE
		echo q >> $AUTOPART_CMD_FILE
		slice_s3="1"
	else
		echo p > $AUTOPART_CMD_FILE
		echo 0 >> $AUTOPART_CMD_FILE
		echo root >> $AUTOPART_CMD_FILE
		echo wm >> $AUTOPART_CMD_FILE
		echo 3 >> $AUTOPART_CMD_FILE
		if test $cyls -gt $(($root_cyls+$min_export_cyls)) -a "x$_KS_autopart_export_home" != x0 -a $fstype = "ufs"; then
			echo ${root_cyls}c >> $AUTOPART_CMD_FILE
			printlog "Slice0: / ${root_cyls} cylinders"
			echo 1 >> $AUTOPART_CMD_FILE
			echo home >> $AUTOPART_CMD_FILE
			echo wm >> $AUTOPART_CMD_FILE
			echo $(($root_cyls+4)) >> $AUTOPART_CMD_FILE
			echo $(($cyls-$swap_cyls-$root_cyls-10))c >> $AUTOPART_CMD_FILE
			printlog "Slice1: /export/home $(($cyls-$swap_cyls-$root_cyls-10)) cylinders"
		else
			echo $(($cyls-$swap_cyls-8))c >> $AUTOPART_CMD_FILE
			printlog "Slice0: / $(($cyls-$swap_cyls-8)) cylinders"
		fi
		echo 7 >> $AUTOPART_CMD_FILE
		echo swap >> $AUTOPART_CMD_FILE
		echo wu >> $AUTOPART_CMD_FILE
		echo $(($cyls-$swap_cyls-5)) >> $AUTOPART_CMD_FILE
		echo ${swap_cyls}c >> $AUTOPART_CMD_FILE
		printlog "Slice7: swap ${swap_cyls} cylinders"
		echo q >> $AUTOPART_CMD_FILE
		echo label >> $AUTOPART_CMD_FILE
		echo 0 >> $AUTOPART_CMD_FILE
		echo q >> $AUTOPART_CMD_FILE
	fi

	format -ef $AUTOPART_CMD_FILE -d $d >/dev/null 2>$AUTOPART_FMT_ERR
	if test $? != 0; then
		# something went wrong first time... try again after slight delay
		sleep 10
		rm -f $AUTOPART_FMT_ERR
		format -ef $AUTOPART_CMD_FILE -d $d >/dev/null 2>$AUTOPART_FMT_ERR
		if test $? != 0; then
			oneline_msgbox Error "Cannot auto-partition $phys disk with error:\n\n $(cat $AUTOPART_FMT_ERR)\n"
			return 1
		fi
	fi
	if test "x$slice_s3" = x1; then
		dd if=/dev/zero of=/dev/rdsk/${d}s3 2>/dev/null 1>&2
	fi
	if test $fstype = "ufs"; then
		slice_root=$disk
		slice_swap="$(echo $disk|sed -e 's/s0/s7/')"
		if ! mntfmt_do "$slice_root" $TMPDEST; then
			reboot_exit "Cannot format/mount root! Giving up..."
		fi
		if test $cyls -gt $(($root_cyls+$min_export_cyls)) -a "x$_KS_autopart_export_home" != x0; then
			slice_export_home="$(echo $disk|sed -e 's/s0/s1/')"
			if ! mntfmt_do "$slice_export_home" $TMPDEST/export/home "zfs"; then
				reboot_exit "Cannot format/mount root! Giving up..."
			fi
		fi
	else
		if boolean_check $_KS_autopart_use_swap_zvol; then
			if test "x$slice_root" = x; then
				slice_root=$d
				slice_swap="syspool/swap"
			fi
		else
			if test "x$slice_root" = x; then
				slice_root=$disk
				slice_swap="$(echo $disk|sed -e 's/s0/s7/')"
			else
				slice_swap="$slice_swap $(echo $disk|sed -e 's/s0/s7/')"
			fi
		fi
	fi

	return 0
}

autopart_ask()
{
	local manual_cmd=""
	local disknum=0
	local onoff=""
	local drive_node info_disk info_size i check_size disk_size
	local TMP_DISKSIZE_FILE="/tmp/autopart-disk-size.$$"

	result_disk_pool=""
	result_disk_spare=""

	oneline_info "Checking for available disks..."

	rmformat >/dev/null 2>&1
	devfsadm -c disk >/dev/null 2>&1
	sync; sleep 3
	local cdrom=`$REPO/mdisco -l | uniq | sed -e 's/p0/s0/g'`
	local iso_usb="$(extract_args iso_usb)"
	if test "x$iso_usb" != x; then
		iso_usb=`basename \`mount | egrep "^/mnt" | awk '{print $3}' | sed -e 's/p1/s0/'\``
		iso_usb="/dev/rdsk/$iso_usb"
	fi

	while test ! -f /var/adm/messages; do
		sleep 1
		svcadm enable system-log > /dev/null 2>&1
	done
	cp /var/adm/messages $TMPMESSAGES

	rm -f $TMP_FILE $TMP_DISKSIZE_FILE>/dev/null
	touch $TMP_FILE
	local drvs=$($REPO/mdisco -ld | uniq | sed -e 's/p0/s0/g' | sort)
	for drv in $drvs; do
		test "$drv" = "$iso_usb" && continue
		echo $cdrom | grep $drv 2>/dev/null 1>&2 && continue
		local vendor=""
		local devpath=""
		local phys=""
		local size=""
		local p=""
		local disk="$(echo $drv|sed -e 's/.*\/\(c[0-9]\+.*\)s[0-9]\+$/\1/')"

		if test -f $RDMAP && grep $drv $RDMAP >/dev/null; then
			local bus=$(grep $drv $RDMAP|nawk -F: '{print $4}')
			vendor=$(grep $drv $RDMAP|nawk -F: '{print $3}')
			size=$(grep $drv $RDMAP|nawk -F: '{print $7}')
			test "x$vendor" = x && vendor="Unknown Vendor"
			vendor="$size"" ($bus $vendor)"
		else
			devpath="$(ls -l $drv | awk '{print $11}' | \
			    sed -e 's;.*devices/;;' -e 's;:[a-z]\+;;')"
			phys="$(echo $drv | sed -e 's/dsk/rdsk/' -e 's/s0/p0/')"
			size="$(fdisk -G $phys | tail -1 | \
			    awk '{print $1*$5*$6*$7}')"
			size="$(round_disk_size $size)"
			p=$(grep "cmdk.*is.*$devpath" $TMPMESSAGES | \
			    sed -e "s/.*cmdk\([0-9]\+\)\s* .*/\1/" | sort -u)
			if test "x$p" = x; then
				vendor=$(iostat -En | grep -A1 $disk | \
				    tail -1 | sed -e 's/Vendor:\s*\(.*\)\s*Product:\s*\(.*\)\s*Revision:.*/\1 \2/')
			else
				vendor=$(grep 'gda:.*Disk' $TMPMESSAGES | \
				    grep "Disk$p" | sed -e "s/^.*Disk/Disk/" | \
				    sed -e "s/.*<\(.*\)>.*/\1/" -e "s/'//g" -e "s/Vendor //" -e "s/  Product / /"|tail -1)
			fi
			test "x$vendor" = x && vendor="Unknown Vendor"
			vendor="$size"" GB ($vendor)"
		fi

		vendor=$(echo $vendor|sed -e 's/\s*)/)/')

		onoff="off"
		test $disknum == 0 && onoff="on"

		echo -n "$disk \"$vendor\" $onoff " >> $TMP_FILE
		echo "$disk $size" >> $TMP_DISKSIZE_FILE

		let disknum=$disknum+1
	done

	rlist=$(cat $TMP_FILE)
	rm -f $TMP_FILE >/dev/null
	if test "x$auto_install" = "x1"; then
		for dev_id in `echo $syspool_luns | sed -e "s/~~/ /g"`; do
			if test `echo $dev_id | egrep "^c[0-9]{1,2}\w*d[0-9]{1,2}$"`; then
				result_disk_pool="$result_disk_pool $dev_id"
			else
				result_disk_pool="$result_disk_pool $(get_lun_by_device_id $dev_id)"
			fi
		done
		printlog "Selected disk(s) for auto partitioning: $(echo $result_disk_pool)"
		if test "x$syspool_spare" != "x"; then
			for dev_id in `echo $syspool_spare | sed -e "s/~~/ /g"`; do
				if test `echo $dev_id | egrep "^c[0-9]{1,2}\w*d[0-9]{1,2}$"`; then
					result_disk_spare="$result_disk_spare $dev_id"
				else
					result_disk_spare="$result_disk_spare $(get_lun_by_device_id $dev_id)"
				fi

			done
			printlog "Selected disk(s) for hot-spare: $(echo $result_disk_spare)"
		fi
		rm -f $TMP_FILE $TMP_DISKSIZE_FILE
		return 0
	fi
	if test "x$rlist" != "x"; then
		CHECK_INFO="\nPlease select disk(s) for the $TITLE system volume. Automatic partitioning will repartition the selected disk(s) using pre-configured layout.\n\\Z1NOTE\\Zn: For mirrored ZFS-boot configuration, please select two or more equal-size disks.\n\\Z1WARNING\\Zn: $TITLE Operating System will be installed onto the system volume, and all existing data on the selected disk(s) will be lost during the installation process!"
		if boolean_check $_KS_autopart_manual; then
			manual_cmd="--ok-label Auto --extra-label Manual --extra-button --help-button --help-label Fdisk"
			CHECK_INFO="$CHECK_INFO Backup existing data or proceed with manual/fdisk partitioning.\n\nIf you want to upgrade instead of reinstall, press ESC to go back.\n"
		else
			manual_cmd="--ok-label Select"
			CHECK_INFO="$CHECK_INFO\n"
		fi

		echo "$DIALOG_WITH_ESC $manual_cmd --no-cancel --title \" Fresh Installation \" --checklist \"$CHECK_INFO\nPlease select disk(s) (no more than 3) to be automatically partitioned:\" 0 0 5 $rlist" >$TMP_FILE

		. $TMP_FILE 2>$DIALOG_RES
		local rc=$?

		# strip '"'
		local result=$(echo $(dialog_res)|sed -e "s/\"//g")
		echo $result >$DIALOG_RES

		case "$rc" in
		$DIALOG_ESC)
			oneline_msgbox Installer "Restarting disks detection..."
			rm -f $TMP_FILE $TMP_DISKSIZE_FILE
			return 2
			;;
		3)
			if test "x$(dialog_res)" = x; then
				oneline_msgbox Install "Please select a disk for manual partitioning."
			elif echo "$(dialog_res)" | grep " " >/dev/null; then
				oneline_msgbox Install "Only one disk could be selected for manual partitioning."
				rm -f $TMP_FILE $TMP_DISKSIZE_FILE
				return 2
			else
				drive_node="/dev/dsk/$(dialog_res)s0"
				if test -f $RDMAP && grep $drive_node $RDMAP \
				    >/dev/null; then
					local rm_node=$(grep $drive_node $RDMAP | nawk -F: '{print $1}')
					RM_DISK="${rm_node}"
#					BOOT_ANYWHERE=1
				fi
				printlog "Selected disk for manual partitioning: $(dialog_res)"
			fi
			rm -f $TMP_FILE $TMP_DISKSIZE_FILE
			return 3
			;;
		$DIALOG_OK)
			if test "x$(dialog_res)" = x; then
				oneline_msgbox Install "Please select one or more disks."
				rm -f $TMP_FILE $TMP_DISKSIZE_FILE
				return 2
			elif [ "$(echo $(dialog_res)|wc -w)" -gt "3" ]; then
				oneline_msgbox Install "Please select no more than 3 disks."
				rm -f $TMP_FILE $TMP_DISKSIZE_FILE
				return 2
			elif echo "$(dialog_res)" | grep " " >/dev/null; then
				for disk in `echo $(dialog_res)|sed -e "s/ /\n/g"`; do
					disk_size=$(cat $TMP_DISKSIZE_FILE|grep $disk|awk '{print $2}')
					if test "x$check_size" = x; then
						check_size=$disk_size
					elif ! compare_size $check_size $disk_size; then
						if ! oneline_yN_ask "Warning! You have selected not-equal-sized disks. Proceed?"; then
							rm -f $TMP_FILE $TMP_DISKSIZE_FILE
							return 2
						fi
						break
					fi
				done
			else
				drive_node="/dev/dsk/$(dialog_res)s0"
				if test -f $RDMAP && grep $drive_node $RDMAP \
				    >/dev/null; then
					local rm_node=$(grep $drive_node $RDMAP | nawk -F: '{print $1}')
					part_id=`fdisk -W - $rm_node | \
					         grep -v "^*" | grep -v "^$" | \
						 awk '{print $1}'| grep -v '^0'`
					if test "x$part_id" = x; then
						RM_DISK=""
					else
						RM_DISK="${rm_node}"
					fi
#					BOOT_ANYWHERE=1
				fi
			fi
			printlog "Selected disk(s) for auto partitioning: $(dialog_res)"
			result_disk_pool=$(dialog_res)

			if [ "$(echo $result_disk_pool|wc -w)" -lt "2" ]; then
				rm -f $TMP_FILE $TMP_DISKSIZE_FILE
				return 0
			fi
			for disk in `echo $result_disk_pool|sed -e "s/ /\n/g"`; do
				rlist=$(echo $rlist|sed -e "s/\(c[0-9]\{1,2\}\w*d[0-9]\{1,2\}\)/\n\1/2g"|sed -e "/$disk/ d"|sed -e "s/^ //"|sed -e "/^$/d"|sort)
			done
			rlist=$(echo $rlist|sed -e "s/\bon\b/off/g")
			if [ "${rlist}" != "" ]; then
				if ! oneline_Yn_ask "Would you like to add one or more hot spare disk(s) to the system volume?"; then
					rm -f $TMP_FILE $TMP_DISKSIZE_FILE
					return 0
				fi
				while true; do
					CHECK_INFO="\nPlease select hot spare disk(s) for the $TITLE system volume.\n\\Z1WARNING\\Zn: $TITLE Operating System will be installed onto the system volume, and all existing data on the selected disk(s) will be lost during the installation process!\nPress ESC to go back."
					echo "$DIALOG_WITH_ESC $manual_cmd --title \" Fresh Installation \" --checklist \"$CHECK_INFO\nPlease select one or more hot spare disk(s):\" 0 0 5 $rlist" >$TMP_FILE

					. $TMP_FILE 2>$DIALOG_RES
					local rc=$?

					# strip '"'
					local result=$(echo $(dialog_res)|sed -e "s/\"//g")
					echo $result >$DIALOG_RES

					case "$rc" in
					$DIALOG_OK)
						if test "x$(dialog_res)" = x; then
							oneline_msgbox Error "Please use SPACEBAR and Up/Down arrows to select one or more hot spare disk(s)."
						else
							for disk in `echo $(dialog_res)|sed -e "s/ /\n/g"`; do
								disk_size=$(cat $TMP_DISKSIZE_FILE|grep $disk|awk '{print $2}')
								if test $check_size -ne $disk_size; then
									if ! oneline_yN_ask "Warning! You have selected not-equal-sized disks. Proceed?"; then
										rm -f $TMP_FILE $TMP_DISKSIZE_FILE
										return 2
									fi
									break
								fi
							done
							result_disk_spare=$(dialog_res)
							printlog "Selected disk(s) for hot-spare: $(dialog_res)"
							break
						fi
						;;
					$DIALOG_CANCEL)
						result_disk_spare=""
						printlog "Hot-spare disks not selected"
						break
						;;
					$DIALOG_ESC)
						rm -f $TMP_FILE $TMP_DISKSIZE_FILE
						return 2
						;;
					esac
				done
				result_disk_spare=$(dialog_res)
				printlog "Selected disk(s) for hot-spare: $(dialog_res)"
			fi

			rm -f $TMP_FILE $TMP_DISKSIZE_FILE
			return 0
			;;
		*)
			;;
		esac
		if echo $(dialog_res)|egrep "^HELP" >/dev/null; then
			sed -i -e "s/^HELP.*\(c[0-9]\+.*\)$/\1/" $DIALOG_RES
		fi
		if test "x$(dialog_res)" = x; then
			oneline_msgbox Install "Please select a disk for manual partitioning."
		else
			oneline_msgbox Partitioning "No automatic partitioning performed."
			printlog "Selected disk for fdisk partitioning: '$(dialog_res)'"
		fi
		rm -f $TMP_FILE $TMP_DISKSIZE_FILE
		return 1
	fi
	return 1
}

check_nexenta_drive()
{
	if [ -d $2/var/lib/apt -a -d $2/var/lib/dpkg ]; then
		local release=`grep Nexenta $2/etc/issue|sed -e "s/Nexenta.*GNU\/OpenSolaris //"`
		if test "x$release" = x; then
			release="unknown"
		fi

		echo "$1:$release" >> $UPMAP
		return 0
	fi
	return 1
}

check_upgrade()
{
	# disabled...
	return 0

	oneline_info "Checking for upgrade..."

	# mdisco cannot detect hard disks without rmformat?
	rmformat >/dev/null 2>&1

	local cdrom=`$REPO/mdisco -l | uniq | sed -e 's/p0/s0/g'`

	mkdir $TMPDEST > /dev/null 2>&1
	rm -f $UPMAP > /dev/null 2>&1
	touch $UPMAP

	$REPO/mdisco -ld | uniq | sort | sed -e 's/p0/s0/g' |
	while read drv; do
		echo $cdrom | grep $drv 2>/dev/null 1>&2 && continue
		mount -F ufs $drv $TMPDEST > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			check_nexenta_drive $drv $TMPDEST
			umount $TMPDEST > /dev/null 2>&1
		fi
	done

	num_drv=`cat $UPMAP | wc -l`
	if [ $num_drv -eq 0 ]; then
		oneline_info "No upgradeable drive found"
		printlog "No upgradeable drive found"
		sleep 1
		return 1
	fi

	CHECK_INFO="\nInstall has detected that the following disks are eligible for upgrade. Upgrade allows you to retain your data, including any customized system files.\n\nIf you choose not to upgrade, select Install to begin with a fresh installation; note however, that you will lose all data on the drive by doing so. Press CTRL-C at anytime to quit the installer.\n"

	rlist=""
	IFS=$newline
	for i in `cat $UPMAP|sort`; do
		local status=0
		local drive=$(echo $i|awk -F: '{print $1}')
		local release=$(echo $i|awk -F: '{print $2}')
		rlist="$rlist $drive \"$release\" off"
	done
	unset IFS

	rm -f $TMP_FILE >/dev/null
	echo "$DIALOG --ok-label Upgrade --cancel-label Install --title \" Upgrade Options \" --radiolist \"$CHECK_INFO\nPlease choose an existing $TITLE installation to upgrade :\" 0 0 0 $rlist" > $TMP_FILE

	while true; do
		. $TMP_FILE 2>$DIALOG_RES
		if test $? != $DIALOG_OK; then
			oneline_msgbox Upgrade "No upgrade will be performed."
			printlog "No upgrade will be performed."
			rm -f $TMP_FILE >/dev/null
			return 1
		fi
		upgrade_node=$(dialog_res)
		if test "x$upgrade_node" = x; then
			oneline_msgbox Upgrade "Please select a drive."
			continue
		fi
		if test "x$release" = xunknown || \
		   echo $release | grep "Alpha [1234]" >/dev/null; then
			oneline_msgbox_slim Upgrade "Upgrade from selected drive will not be performed. The selected drive contains previous Alpha release upgrade from which is not supported by this installation program.\n\nPlease select another drive or proceed with fresh install option."
			continue
		fi
		UPGRADE_DISK="${upgrade_node}"
		UPGRADE=1
		printlog "Selected disk for upgrade: ${upgrade_node}"
		break
	done
	rm -f $TMP_FILE >/dev/null
	return 0
}

detect_removable()
{
	oneline_info "Detecting removable devices..."
	local cdrom=`$REPO/mdisco -l | uniq | sed -e 's/\/dev\/dsk\//\/dev\/rdsk\//g'`

	rmformat 2>/dev/null 1>&2

	rm -f $RDMAP > /dev/null 2>&1
	touch $RDMAP

	if [ $? -ne 0 ]; then
		return 1
	fi

	rmformat 2> /dev/null | grep "Logical Node:" |
	nawk '/Node:/ { print $4 }' | while read drv; do
		echo $cdrom | grep $drv 2>/dev/null 1>&2 && continue
		rmdrive_info ${drv}
	done
	return 0
}

generic_partition_ask()
{
	local hlpmsg="[Enter to skip]"
	test "x$1" = "x/" && hlpmsg=""
	echo -n "Please specify $1 $hlpmsg: "
}

partition_ask()
{
	local btns=--ok-label\ Select
	local rlist=""
	local p=$1; shift
	local plist=$*
	for i in `echo $plist|sort`; do
		local disp_part=$(echo $i|awk -F: '{print $1}')
		local disp_comment=$(echo $i|awk -F: '{print $2}')
		rlist="$rlist $disp_part $disp_comment 0"
	done
	if test "x$p" = "x/"; then
		btns=$btns\ --no-cancel
	else
		btns=$btns\ --cancel-label\ Skip\ --defaultno
	fi
	while true; do
		$DIALOG $btns --title " Manual Partitioning " --radiolist "Please select partition to be assigned as [$p] :" 0 64 11 $rlist 2>$DIALOG_RES
		test "x$p" != "x/" -a "x$(dialog_res)" = "x$slice_root" && continue
		break
	done
}

plist_modify()
{
	local assigned=$1;
	local p=$2;
	shift; shift
	local plist=$*
	echo $plist | sed -e "s;$p:\S\+;$p:$assigned;"
}

dialog_res() {
	echo "`cat $DIALOG_RES 2>/dev/null`"
}

generic_Yn_ask()
{
	while true; do
		echo -n "$1 [Y/n] "; read ans
		test x$ans = x -o x$ans = xy -o x$ans = xY && return 0
		test x$ans = xn -o x$ans = xN && return 1
	done
}

format_drive()
{
	local disk=$1

	while true; do
		if ! manual_partitioning $disk; then
			return 1
		fi

		if [ "${RM_DISK}" = "" ]; then
			oneline_Yn_ask "Are you done with manual partitioning?"
			test $? = $DIALOG_OK && break
		else
			break
		fi
	done

	if test "x$ROOTDISK_TYPE" != xzfs; then
		if mntfmt_do "$slice_root" $TMPDEST; then
			test "x$slice_usr" != x &&
				mntfmt_do $slice_usr $TMPDEST/usr
			test "x$slice_var" != x &&
				mntfmt_do $slice_var $TMPDEST/var
			test "x$slice_opt" != x &&
				mntfmt_do $slice_opt $TMPDEST/opt
			test "x$slice_export_home" != x &&
				mntfmt_do "$slice_export_home" $TMPDEST/export/home "zfs"
		else
			oneline_info "Cannot format/mount root! Giving up..."
			return 1
		fi
	fi
	return 0
}

readvfstab() {
	while read special fsckdev mountp fstype fsckpass automnt mntopts; do
		case "$special" in
		'' )	# Ignore empty lines.
			continue
			;;

		'#'* )	# Ignore comment lines.
			continue
			;;

		'-')	# Ignore "no-action" lines.
			continue
			;;
		esac

		[ "x$mountp" = "x$1" ] && break
	done
}

upgrade_drive()
{
	local release=`grep $UPGRADE_DISK $UPMAP | nawk -F : '{ print $2 }'`
	local release_new=`cat /etc/issue|sed -e "s/Nexenta.*GNU\/OpenSolaris //"`

	slice_root=$UPGRADE_DISK

	local msg="\nYou are about to upgrade $slice_root:\n"
	msg="$msg\nFrom:  ${release}"
	msg="$msg\nTo:    ${release_new}\n"

	mount -F ufs $UPGRADE_DISK $TMPDEST > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		reboot_exit "Error mounting $UPGRADE_DISK for upgrade."
	fi

	msg="$msg\nMount points (from vfstab):\n"

	readvfstab / < $TMPDEST/etc/vfstab
	if [ ! -z $special ]; then
		msg="$msg\n    [/] => $special"
	fi

	readvfstab /usr < $TMPDEST/etc/vfstab
	if [ ! -z $special ]; then
		msg="$msg\n    [/usr] => $special"
		slice_usr=$special
	fi

	readvfstab /var < $TMPDEST/etc/vfstab
	if [ ! -z $special ]; then
		msg="$msg\n    [/var] => $special"
		slice_var=$special
	fi

	readvfstab /opt < $TMPDEST/etc/vfstab
	if [ ! -z $special ]; then
		msg="$msg\n    [/opt] => $special"
		slice_opt=$special
	fi

	message_Yn_ask "$msg\n\n" "     Are you sure you want to upgrade?"
	test $? != $DIALOG_OK && return 1

	mnt_do $slice_root $TMPDEST
	test "x$slice_usr" != x &&
		mnt_do $slice_usr $TMPDEST/usr
	test "x$slice_var" != x &&
		mnt_do $slice_var $TMPDEST/var
	test "x$slice_opt" != x &&
		mnt_do $slice_opt $TMPDEST/opt

	return 0
}

mnt_do()
{
	local loc=`echo "$2/" | sed -e "s:$TMPDEST::"`

	oneline_info "Checking [$loc] on $1..."
	umount -f $1> /dev/null 2>&1
	fsck -y $(b2r $1) > /dev/null 2>&1

	oneline_info "Mounting [$loc]... "
	test ! -d $2 && mkdir $2
	umount $2 2>/dev/null
	if ! mount -F ufs $1 $2 2>/dev/null; then
		oneline_msgbox Error "Error mounting $1 to [$loc]!"
		return 1
	fi
	return 0
}


mntfmt_do()
{
	local fstype=$3
	test "x$fstype" = x && fstype="ufs"
	local loc=`echo "$2/" | sed -e "s:$TMPDEST::"`
	oneline_info "Preparing '$fstype' file system on $1... "
	test ! -d $2 && mkdir -p $2
	if test $fstype = ufs; then
		echo y | newfs $1 1>/dev/null 2>/dev/null
		oneline_info "Mounting [$loc]... "
		umount $2 2>/dev/null
		if ! mount -F $fstype $1 $2 2>/dev/null; then
			oneline_msgbox Error "Error mounting $1 to [$loc]!"
			return 1
		fi
	else
		local phys=$(echo $1|sed -e 's/\/dev\/dsk\///')
		if ! zpool create -m $2 -f $ZPOOL_HOME $phys 2>/dev/null; then
			oneline_msgbox Error "Error creating ZFS pool on $1 to [$loc]!"
			return 1
		fi
		zfs set compression=on home
		printlog "ZFS compression enabled for $1"
	fi
	printlog "Successfuly formatted: $1 ($fstype) and mounted at $2"
	return 0
}

slice_tag()
{
	local dev=$1
	local tags

	tags[0]="unassigned"
	tags[1]="unassigned"
	tags[2]="root"
	tags[3]="swap"
	tags[4]="usr"
	tags[5]="unassigned"
	tags[6]="unassigned"
	tags[7]="var"
	tags[8]="home"
	tags[9]="unassigned"

	local slice=$(echo $dev|sed -e "s/.*s\([0-9]\+\)$/\1/")
	local tag=$(prtvtoc -s $dev 2>/dev/null|awk "/^[ \t]+$slice/ {print \$2}")
	echo ${tags[$tag]}
}

partitions_detect()
{
	local disk=$1
	local output="/tmp/fstyp.output"
	local output_fs="/tmp/fstyp_good.output"
	local cdrom=`$REPO/mdisco -l | uniq | sed -e 's/p0//g' | sed -e 's/\/dev\/dsk\///g'`
	local exclude_cdrom_cmd="egrep -v \"${cdrom}\" |"
	if test "x$cdrom" = x; then
		exclude_cdrom_cmd=""
	fi

	devfsadm -c disk
	local plist=""
	for f in `find /dev/dsk`; do
		echo $f | grep -v $disk >/dev/null && continue
		if echo $f | $exclude_cdrom_cmd egrep -v "s2$" | egrep -v "s8$" | egrep -v "s9$" | egrep "[0-9]s[0-9]" >/dev/null; then
			if fstyp $f 1>&2 2>$output 1>$output_fs; then
				plist="$plist $f<$(slice_tag $f)>:unassigned"
			elif ! cat $output | grep "cannot open" > /dev/null &&
			       cat $output | grep "nknown_fstyp" >/dev/null; then
				plist="$plist $f<$(slice_tag $f)>:unassigned"
			fi
		fi
	done
	rm -f $output $output_fs
	echo $plist
}

manual_partitioning()
{
	local disk=$1

	if [ "${RM_DISK}" != "" ]; then
		oneline_info "Preparing Solaris partition on ${RM_DISK} ..."
		# use extremely large size to trigger error
		# so that rmformat prints out media size
		rm -f ${RMFORMAT_TMP}
		touch ${RMFORMAT_TMP}
		echo "slices: 2 = 0, 999GB, \"wm\", \"backup\" " >> ${RMFORMAT_TMP}
		local total_sectors=`rmformat -s ${RMFORMAT_TMP} ${RM_DISK} 2>&1 | grep "sectors" | nawk '{ print $6 }'`

		# find out number of bytes per sector
		rm -f ${RMFORMAT_TMP}
		touch ${RMFORMAT_TMP}
		echo "slices: 0 = 0, 1, \"wm\", \"root\" " >> ${RMFORMAT_TMP}
		rmformat -s ${RMFORMAT_TMP} ${RM_DISK} > /dev/null 2>&1
		local bytes_per_sec=`prtvtoc ${RM_DISK} | grep "bytes/sector" | nawk '{ print $2 }'`
		local sec_per_cyl=`prtvtoc ${RM_DISK} | grep "sectors/cylinder" | nawk '{ print $2 }'`

		local total_size=0
		local mb_size=0
		local boot_size=0
		local alt_off=0
		local alt_size=0
		local root_off=0
		local root_size=0
		local total_spaceneeded=0

		# total_size (in bytes)
		(( total_size = total_sectors * bytes_per_sec ))

		(( mb_size = total_size / ( 1024 * 1024) ))

		(( total_spaceneeded = reposize + spaceneeded ))

		# If the target drive is small and machine doesn't
		# have enough RAM, we won't have enough space for
		# debootstrap to copy all the packages, so bail out.
		MEMSCRATCH=0
		if [ $mb_size -lt $total_spaceneeded ]; then
			if [ $sysmem -lt $spaceneeded ]; then
				oneline_msgbox_slim Error "\nSorry, there is not enough space on the drive to store all\nbootstrapped packages (drive size is $mb_size MB, space needed\nis $total_spaceneeded MB), and there is not enough RAM in your system\nto utilize memory as scratch drive (RAM is $sysmem MB, memory\nneeded is $spaceneeded MB).\n\nYou will need to install on a different drive or increase\nthe amount of RAM in your system.\n\n"
				return 1
			fi
			MEMSCRATCH=1
		else
			# If there's plenty of RAM, make use of it
			# for faster installation
			if [ $sysmem -ge $spaceneeded ]; then
				MEMSCRATCH=1
			fi
		fi

		fdisk -B ${RM_DISK}
		rmformat -b ${RM_LABEL} ${RM_DISK} > /dev/null 2>&1

		# some devices will refuse to be formatted,
		# so we cannot check for return value here
		echo "y" | rmformat -U ${RM_DISK} > /dev/null 2>&1

		rmformat -b ${RM_LABEL} ${RM_DISK} > /dev/null 2>&1

		# slice 8 is boot slice (in bytes), from cyl. 0, length 1 cyl.
		(( boot_size = sec_per_cyl * bytes_per_sec ))

		# slice 9 is alternates slice, from cyl. 1, length 2 cyl.
		(( alt_off = boot_size + 1 ))
		(( alt_size = sec_per_cyl * 2 * bytes_per_sec ))

		# root slice starts after alternates to end of disk;
		# backup slice is for the entire disk.
		(( root_off = alt_off + alt_size + 1 ))
		(( root_size = (total_size - root_off) + bytes_per_sec ))

		rm -f ${RMFORMAT_TMP}
		touch ${RMFORMAT_TMP}
		echo "slices: 0 = ${root_off}, ${root_size}, \"wm\", \"root\" :"  >> ${RMFORMAT_TMP}
		echo "        2 = 0, ${total_size}, \"wm\", \"backup\" :" >> ${RMFORMAT_TMP}
		echo "        8 = 0, ${boot_size}, \"wu\", \"boot\" :" >> ${RMFORMAT_TMP}
		echo "        9 = ${alt_off}, ${alt_size}, \"wu\", \"alternates\"" >> ${RMFORMAT_TMP}
		rmformat -s ${RMFORMAT_TMP} ${RM_DISK} > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			oneline_msgbox Error "Error creating slices on ${RM_DISK}. Root slice size is ${mb_size}"
			return 1
		fi

		slice_root=`echo "${RM_DISK}" | sed -e 's/\/dev\/rdsk\//\/dev\/dsk\//g' | sed -e 's/p0/s0/g'`

		return 0
	fi

	message_Yn_ask "\nYou are about to use Solaris interactive partitioning tool. Usage of this tool is recommended for advanced users only. This process might *DESTROY* any existing partition or slice information on the disk(s). You can press CTRL-C at anytime to exit the interactive tool.\n\nContinue with manual partitioning?"
	test $? != $DIALOG_OK && return 1
	while true; do
		clear >/dev/console
		stty sane
		echo
		echo
		format -d $disk
		$DIALOG --no-label Cancel --extra-button --extra-label Retry --title " Question " --yesno "
 Are you done with manual partitioning?" 7 70
 		local rc=$?
		test $rc = $DIALOG_OK && break
		test $rc = 3 && continue
		return 1
	done

	while true; do
		oneline_info "Detecting available slices... "
		local plist=$(partitions_detect $disk)
		while true; do
			partition_ask "/" $plist; slice_root=$(dialog_res)
			test "x$slice_root" != x && plist=$(plist_modify "/" "$slice_root" $plist)
			test "x$slice_root" != x && break
		done
		partition_ask "swap" $plist; slice_swap=$(dialog_res)
		test "x$slice_swap" != x && plist=$(plist_modify "swap" "$slice_swap" $plist)
#		partition_ask "/usr" $plist; slice_usr=$(dialog_res)
#		test "x$slice_usr" != x && plist=$(plist_modify "/usr" "$slice_usr" $plist)
#		partition_ask "/var" $plist; slice_var=$(dialog_res)
#		test "x$slice_var" != x && plist=$(plist_modify "/var" "$slice_var" $plist)
#		partition_ask "/opt" $plist; slice_opt=$(dialog_res)
#		test "x$slice_opt" != x && plist=$(plist_modify "/opt" "$slice_opt" $plist)
		partition_ask "/export/home" $plist; slice_export_home=$(dialog_res)
		test "x$slice_export_home" != x && plist=$(plist_modify "/export/home" "$slice_export_home" $plist)
		local msg="Next selected slices will be \\Z1FORMATTED\\Zn:\n"
		msg="$msg\n[/] => $slice_root"
		test "x$slice_swap" != x && msg="$msg\n[swap] => $slice_swap"
		test "x$slice_usr" != x && msg="$msg\n[/usr] => $slice_usr"
		test "x$slice_var" != x && msg="$msg\n[/var] => $slice_var"
		test "x$slice_opt" != x && msg="$msg\n[/opt] => $slice_opt"
		test "x$slice_export_home" != x && msg="$msg\n[/export/home] => $slice_export_home"
		msg="$msg\n\n"
		message_Yn_ask "$msg" "Are you done with partitioning and ready to format?\n"
		if test $? = $DIALOG_OK; then
			slice_root=$(echo $slice_root|sed -e 's/<.*>$//')
			slice_swap=$(echo $slice_swap|sed -e 's/<.*>$//')
			slice_usr=$(echo $slice_usr|sed -e 's/<.*>$//')
			slice_var=$(echo $slice_var|sed -e 's/<.*>$//')
			slice_opt=$(echo $slice_opt|sed -e 's/<.*>$//')
			slice_export_home=$(echo $slice_export_home|sed -e 's/<.*>$//')
			return 0
		fi
	done
}

progress_bar()
{
	local max_lines=$1
	local prog=$2
	local logfile=$3
	local msg=$4
	sleep 3
	(
	while pgrep $prog>/dev/null; do
		test ! -e $logfile && continue
		lines=`cat $logfile|wc -l`
		prc=$((100*$lines/$max_lines))
		test $prc -gt 99 && prc=99
		echo $prc
		sleep 1
	done
	echo 100
	) | $DIALOG --input-fd 1 --title " Current progress " --gauge \
		" $msg " 7 70
}

install_base()
{
	local lines=${_KS_profile_lines[$_KS_profile_selected]}
	local message="Installing the base $DEFAULT_PROFILE software..."
	printlog $message
	$REPO/install-base.sh $TMPDEST $REPO $MEMSCRATCH &
	progress_bar $lines install-base.sh $TMPDEST/debootstrap/debootstrap.log \
		"$message... Please wait."
}

process_extradebs()
{
	chrootenv="/usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm"
	chroot $TMPDEST $chrootenv /usr/sbin/mount /proc
	packages_full=$(find ${EXTRADEBDIR} -name *.deb)
	if test "x$packages_full" != "x"; then
		oneline_info "Installing the extra packages. Please wait..."
		packages=""
		for package in $packages_full; do
			package_basename="$(basename $package)"
			packages="$packages $package_basename"
			packages_chroot="$packages_chroot /var/tmp/extradebs/$package_basename"
		done
		printlog "Installing extra deb packages: $packages"
		mkdir -p $TMPDEST/var/tmp/extradebs
		cp ${EXTRADEBDIR}/*.deb $TMPDEST/var/tmp/extradebs
		chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH \
			LOGNAME=root HOME=/root TERM=xterm \
			DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
			/usr/bin/dpkg --force-conflicts --force-depends --force-confold --force-confdef \
			-i $packages_chroot 2>>/tmp/extradebs_install.log 1>&2
		if test -f ${EXTRADEBDIR}/postinst; then
			cp ${EXTRADEBDIR}/postinst $TMPDEST/var/tmp/extradebs
			chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH \
				LOGNAME=root HOME=/root TERM=xterm bash \
				/var/tmp/extradebs/postinst 2>>/tmp/extradebs_install.log 1>&2
			printlog "Script postinst executed successfully"
		fi
		rm -rf $TMPDEST/var/tmp/extradebs
		printlog "Customization scripts output:"
		printlog "`cat /tmp/extradebs_install.log`"
		printlog "Extra deb packages were successfully installed"
	fi
	if test -f ${EXTRADEBDIR}/remove-pkgs.list; then
		oneline_info "Removing the extra packages. Please wait..."
		printlog "Removing extra deb packages: $(cat ${EXTRADEBDIR}/remove-pkgs.list)"
		chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH \
			LOGNAME=root HOME=/root TERM=xterm \
			/usr/bin/dpkg --force-all -P `cat ${EXTRADEBDIR}/remove-pkgs.list` \
			2>>/tmp/extradebs_remove.log 1>&2
		if test -f ${EXTRADEBDIR}/postrm; then
			cp ${EXTRADEBDIR}/postrm $TMPDEST/var/tmp
			chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH \
				LOGNAME=root HOME=/root TERM=xterm bash \
				/var/tmp/postrm 2>>/tmp/extradebs_remove.log 1>&2
				printlog "Script postrm executed successfully"
			rm -f $TMPDEST/var/tmp/postrm
		fi
		printlog "Customization scripts output:"
		printlog "`cat /tmp/extradebs_remove.log`"
		printlog "Extra deb packages were successfully removed"
	fi
	chroot $TMPDEST $chrootenv /usr/sbin/umount /proc 2>/dev/null
}

msig_setup()
{
	while :; do
		$DIALOG --title " Input form " \
			--form " Machine Signature: " 10 30 3 \
			"Msig:" 2 2 "$MACHINESIG" 2 10 10 9 2>$DIALOG_RES
		if test $? == 0; then
			local msig=$(dialog_res)
			echo $msig | egrep "^[A-Z0-9]{9}$" 2>/dev/null 1>&2
			if test $? == 0; then
				if test "$msig" == $MACHINESIG; then
					oneline_yN_ask "MACHINESIG will not be changed. Do you agree?"
					test $? = $DIALOG_OK && break;
					continue
				fi
				MACHINESIG=$msig
				oneline_msgbox "Information" "New MACHINESIG: $MACHINESIG"
				DIALOG="$(dialog_cmd)"
				DIALOG_WITH_ESC="$(dialog_cmd_with_escape)"
				break
			else
				oneline_msgbox Error "Entered MACHINESIG is incorrect"
				continue
			fi
		else
			oneline_msgbox "Information" "Will use MACHINESIG: $MACHINESIG"
			break
		fi
	done
}

loopback_mnt()
{
	mount -F lofs -O $1 $2 >/dev/null 2>&1
	if [ $? -ne 0 ];then
		reboot_exit "Unable to mount $1 on $2"
	fi
}

upgrade_init()
{
	rm -f $UPGRADE_SCRIPT

	if [ -f $TMPDEST/etc/apt/sources.list ]; then
		mv $TMPDEST/etc/apt/sources.list \
		    $TMPDEST/etc/apt/sources.list.orig
	fi

	if [ -f $TMPDEST/debootstrap/debootstrap.log ]; then
		mv $TMPDEST/debootstrap/debootstrap.log \
		    $TMPDEST/debootstrap/debootstrap.log.old
	fi

	if [ -f $TMPDEST/usr/sbin/installf ]; then
		mv $TMPDEST/usr/sbin/installf $TMPDEST/usr/sbin/_installf
	fi

	if [ -f $TMPDEST/usr/bin/installf ]; then
		mv $TMPDEST/usr/bin/installf $TMPDEST/usr/bin/_installf
	fi

	if [ -f $TMPDEST/usr/sbin/removef ]; then
		mv $TMPDEST/usr/sbin/removef $TMPDEST/usr/sbin/_removef
	fi

	if [ -f $TMPDEST/usr/bin/removef ]; then
		mv $TMPDEST/usr/bin/removef $TMPDEST/usr/bin/_removef
	fi

	if [ -f $TMPDEST/boot/grub/menu.lst ]; then
		mv $TMPDEST/boot/grub/menu.lst $TMPDEST/boot/grub/_menu.lst
	fi
}

upgrade_fini()
{
	test $UPGRADE = 0 && return

	rm -f $UPGRADE_SCRIPT >/dev/null 2>&1
	if [ -f $TMPDEST/etc/apt/sources.list.orig ]; then
		mv $TMPDEST/etc/apt/sources.list.orig \
		    $TMPDEST/etc/apt/sources.list
	fi

	if [ -f $TMPDEST/usr/sbin/_installf ]; then
		mv $TMPDEST/usr/sbin/_installf $TMPDEST/usr/sbin/installf
	fi

	if [ -f $TMPDEST/usr/bin/_installf ]; then
		mv $TMPDEST/usr/bin/_installf $TMPDEST/usr/bin/installf
	fi

	if [ -f $TMPDEST/usr/sbin/_removef ]; then
		mv $TMPDEST/usr/sbin/_removef $TMPDEST/usr/sbin/removef
	fi

	if [ -f $TMPDEST/usr/bin/_removef ]; then
		mv $TMPDEST/usr/bin/_removef $TMPDEST/usr/bin/removef
	fi

	if [ -f $TMPDEST/boot/grub/_menu.lst ]; then
		mv $TMPDEST/boot/grub/_menu.lst $TMPDEST/boot/grub/menu.lst
		# check if safe mode were present in old version
		if ! cat $TMPDEST/boot/grub/menu.lst | grep "Safe Mode" >/dev/null 2>&1; then
			# nope, adding new entry to the old menu.lst...
			cat << EOF >> $TMPDEST/boot/grub/menu.lst
title Nexenta OS "Elatte" [Safe Mode, 32-bit]
	root (hd0,0,a)
	kernel$ /platform/i86pc/kernel/unix -s
	module$ /boot/x86.miniroot-safe
EOF
		fi
	fi
}

upgrade_base()
{
	oneline_info "Preparing to upgrade..."

	local locrepo=`echo "$TMPREPO/" | sed -e "s:$TMPDEST::"`
	local upgrade_log=`echo "$UPGRADE_LOG" | sed -e "s:$TMPDEST::"`
	local upgrade_script=`echo "$UPGRADE_SCRIPT" | sed -e "s:$TMPDEST::"`
	local upgrade_script_ps=`basename $upgrade_script`
	local filelist
	local file

	if [ ! -d $TMPREPO ]; then
		mkdir -p $TMPREPO > /dev/null 2>&1
	fi

	loopback_mnt $REPO $TMPREPO

	if [ -f $UPGRADE_LOG ]; then
		mv $UPGRADE_LOG $UPGRADE_LOG.old
	fi
	touch $UPGRADE_LOG
	if [ $? -ne 0 ]; then
		oneline_msgbox Error "Unable to create $UPGRADE_LOG"
	fi

	upgrade_init

	echo "deb file://$locrepo elatte-unstable main contrib non-free" > \
		$TMPDEST/etc/apt/sources.list
	echo "deb-src file://$locrepo elatte-unstable main contrib non-free" >> \
		$TMPDEST/etc/apt/sources.list

	chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm /usr/bin/apt-get -y update 2>> $UPGRADE_LOG 1>&2
	if [ $? -ne 0 ]; then
		oneline_msgbox Error "apt-get update failed"
	fi

	cat << EOF > $UPGRADE_SCRIPT
#!/usr/bin/bash
#
# Copyright 2005 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# Upgrade script generated by installer

export UPDATE=yes
export FAKEROOT=yes
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export NEXENTA_LU_SEEN=true
touch /.nexenta-lu.lock
/usr/sbin/mount /proc
mv /var/lib/dpkg/diversions* /var/tmp/
touch /var/lib/dpkg/diversions
/usr/bin/dpkg --force-conflicts --force-depends --force-confold --force-confdef -i \`find $locrepo -name *.deb\` >> $upgrade_log 2>&1
mv /var/tmp/diversions* /var/lib/dpkg/
EOF
	chmod 0755 $UPGRADE_SCRIPT

	# Fixups for broken pre-remove maintainer scripts
	# Pass 1: fix non-matching close bracket
	filelist=$(find $TMPDEST/var/lib/dpkg/info -name "sunw*.prerm")
	for file in `echo $filelist|/usr/bin/sort`; do
		cat $file | /usr/bin/nawk '
		BEGIN { mark = 0; line = 0 }
		{
			line++
			if (mark == 0) {
				if ($1 == "export" && $2 == "UPDATE") {
					mark = line
				}
			} else {
				if ($1 == "}" && (line == (mark + 1))) {
					next
				}
			}
			print
		}' > $file.$$
		mv $file.$$ $file
	done

	# Fixups for broken pre-remove maintainer scripts
	# Pass 2: fix empty alien_atexit routine
	filelist=$(find $TMPDEST/var/lib/dpkg/info -name "sunw*.prerm")
	for file in `echo $filelist|/usr/bin/sort`; do
		cat $file | /usr/bin/nawk '
		BEGIN { mark = 0; line = 0 }
		{
			line++
			if (mark == 0) {
				if ($1 == "alien_atexit()" && $2 == "{") {
					mark = line
				}
			} else {
				if ($1 == "}" && (line == (mark + 1))) {
					print "\ttrue"
				}
			}
			print
		}' > $file.$$
		mv $file.$$ $file
	done

	# Alpha{1,2} => Alpha3 pre-upgrade brokenness fixes
	chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
		/usr/bin/dpkg --force-all -P sunwzfsu sunwzfsr menu-xdg gnome2-user-guide 2>> $UPGRADE_LOG 1>&2

	# Alpha{1,2,3} => Alpha4 pre-upgrade fixes
	if test ! -L $TMPDEST/bin; then
		local chrootenv="/usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm"

		#
		# force-upgrade new sunwcslr and sunwcsu (needs to be done before /bin move)
		#
		filelist=$(chroot $TMPDEST $chrootenv find $locrepo -name "sunwcslr_*.deb" -or -name "sunwcsu_*.deb")
		chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
			/usr/bin/dpkg --force-all --unpack $filelist 2>> $UPGRADE_LOG 1>&2

		#
		# move old binaries to /usr/bin. Upgrade will overwrite them anyways.
		#
		for f in `ls $TMPDEST/bin`; do
			if test ! -L $TMPDEST/bin/$f; then
				echo "mv $TMPDEST/bin/$f $TMPDEST/usr/bin/$f" >> $UPGRADE_LOG
				mv $TMPDEST/bin/$f $TMPDEST/usr/bin/$f
			else
				echo "symlink skip $TMPDEST/bin/$f" >> $UPGRADE_LOG
			fi
		done
		rm -rf $TMPDEST/bin
		ln -s usr/bin $TMPDEST/bin
		ln -sf bash $TMPDEST/usr/bin/sh

		#
		# force-upgrade new sysvinit
		#
		filelist=$(chroot $TMPDEST $chrootenv find $locrepo -name "sysvinit_*.deb")
		chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
			/usr/bin/dpkg --force-all --unpack $filelist 2>> $UPGRADE_LOG 1>&2

		#
		# force-upgrade new dpkg and bash
		#
		filelist=$(chroot $TMPDEST $chrootenv find $locrepo -name "dpkg_*.deb" -or -name "bash*.deb")
		chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
			/usr/bin/dpkg --force-all --unpack $filelist 2>> $UPGRADE_LOG 1>&2

		#
		# force-upgrade new /bin stuff
		#
                filelist=$(chroot $TMPDEST $chrootenv find $locrepo -name "base-files_*.deb" -or -name "debianutils_*.deb" -or -name "gzip_*.deb" -or -name "coreutils_*.deb" -or -name "sed_*.deb" -or -name "grep_*.deb" -or -name "tar_*.deb")
                chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
			/usr/bin/dpkg --force-all --unpack $filelist 2>> $UPGRADE_LOG 1>&2
	fi

	# Alpha5 => Alpha6+
	chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
		/usr/bin/dpkg --force-all -P nexenta-sunw sunwgrub 2>> $UPGRADE_LOG 1>&2

	mv "$TMPDEST/sbin/start-stop-daemon" "$TMPDEST/sbin/start-stop-daemon.REAL"
	echo \
"#!/bin/sh
echo
echo \"Warning: Fake start-stop-daemon called, doing nothing\"" > "$TMPDEST/sbin/start-stop-daemon"
	chmod 755 "$TMPDEST/sbin/start-stop-daemon"

	(chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm $upgrade_script) &
	progress_bar 3800 $upgrade_script_ps $UPGRADE_LOG \
		"Upgrading Base software... Please wait."

	oneline_info "Checking APT repository..."
	chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm \
		/usr/bin/apt-get -y -f install 2>> $UPGRADE_LOG 1>&2

	mv "$TMPDEST/sbin/start-stop-daemon.REAL" "$TMPDEST/sbin/start-stop-daemon"

	#
	# Uncomment to debug
	#
	# chroot $TMPDEST /usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm /bin/bash

	upgrade_fini

	cp $UPGRADE_LOG $upgrade_log
	oneline_msgbox Information "Upgrade complete; please check log file before reboot ($upgrade_log)"
}

getrand_10_200() {
	echo | gawk '{srand(systime()); print 10+int(190*rand())}'
}

configure_network()
{
	local numconfigured=0
	local staticif=0
	local use_dhcp=0
	local use_ipv6=0
	local ipaddress=""
	local netmask=""
	local ifnum=0

	if test "x$_KS_hostname" = x -o "x$_KS_domainname" = x; then
		while true; do
			$DIALOG --title " Input form " \
				--form " Host identification: " 12 50 5 \
				"Host name:" 2 2 myhost 2 16 30 30 \
				"Domain name:" 4 2 mydomain.com 4 16 30 30 2>$DIALOG_RES
			hostname=$(cat $DIALOG_RES|head -1)
			domainname=$(cat $DIALOG_RES|tail -1)
			oneline_Yn_ask "Are you done with host identification?"
			test $? = $DIALOG_OK && break
		done
	else
		hostname=$_KS_hostname
		domainname=$_KS_domainname
		oneline_info "Configuring Host and Domain names..."
	fi

	test "x$hostname" = x && hostname="myhost"
	test "x$domainname" = x && domainname="mydomain.com"

	# Create system's node name
	echo "$hostname" > $TMPDEST/etc/nodename
	printlog "Hostname is set to $hostname at /etc/nodename"

	echo "$domainname" > $TMPDEST/etc/defaultdomain
	printlog "Domain Name is set to $domainname at /etc/defaultdomain"

	echo "search $domainname" >> $TMPDEST/etc/resolv.conf
	echo "domain $domainname" >> $TMPDEST/etc/resolv.conf
	printlog "Domain Name is set to $domainname at /etc/resolv.conf"

	ifconfig -a plumb >/dev/null 2>&1
	iflist=`ifconfig -a|grep flags=|nawk -F: '{print $1}'|egrep -v lo0`
	for ifname in $iflist; do

		if test "x$auto_install" = "x1"; then
			_KS_iface_ip[$ifnum]="$(extract_args ipaddr_$ifname)"
			_KS_iface_mask[$ifnum]="$(extract_args netmask_$ifname)"
			if test "x${_KS_iface_ip[$ifnum]}" = x -o "x${_KS_iface_mask[$ifnum]}" = x; then
				(( ifnum = ifnum + 1 ))
				continue
			fi
		fi

		if test "x$_KS_use_dhcp" = x; then
			oneline_Yn_ask "Do you want to configure network interface $ifname?"
			test $? != $DIALOG_OK && continue
			use_dhcp=0
		else
			oneline_info "Configuring $ifname ..."
			use_dhcp=$_KS_use_dhcp
		fi

		use_ipv6=0
		ipaddress=""
		netmask=""
		while true; do
			if test "x$_KS_use_dhcp" = x; then
				oneline_Yn_ask "Do you want to enable DHCP for $ifname?"
				test $? = $DIALOG_OK && use_dhcp=1
			fi

			if test $use_dhcp = 0; then
				if test "x$_KS_ifaces" = x; then
					while true; do
						ifconfig ${ifname}:1 unplumb >/dev/null 2>&1
						$DIALOG --title " Interface settings for $ifname " \
							--form "\nStatic address configuration:" 14 38 5 \
							"IP Address:" 2 2 "" 2 16 15 15 \
							"Netmask:" 4 2 "" 4 16 15 15 2>$DIALOG_RES
						ipaddress=$(cat $DIALOG_RES|head -1)
						netmask=$(cat $DIALOG_RES|tail -1)
						ifconfig $ifname addif $ipaddress netmask $netmask >/dev/null 2>&1
						test $? = 0 && break
						oneline_msgbox Error "Invalid IP address and/or netmask."
					done
					ifconfig ${ifname}:1 unplumb >/dev/null 2>&1
				elif test "x${_KS_iface_ip[$ifnum]}" != x -a "x${_KS_iface_mask[$ifnum]}" != x; then
					ipaddress=${_KS_iface_ip[$ifnum]}
					netmask=${_KS_iface_mask[$ifnum]}
					static_ifnames[$ifnum]=$ifname
				else
					break
				fi
			fi

			if test "x$_KS_use_ipv6" = x; then
				oneline_yN_ask "Do you want to enable IPV6 for $ifname?"
				test $? = $DIALOG_OK && use_ipv6=1
			else
				use_ipv6=$_KS_use_ipv6
			fi

			if test "x$_KS_use_dhcp" = x -o "x$_KS_use_ipv6" = x; then
				oneline_Yn_ask "Are you done with configuring $ifname?"
				test $? = $DIALOG_OK && break
			else
				break
			fi
		done

		if test "x$ipaddress" = x -a "x$netmask" = x; then
			(( ifnum = ifnum + 1 ))
			continue
		fi

		if test $use_dhcp != 0; then
			touch $TMPDEST/etc/hostname.$ifname
			printlog "Network interface $ifname enabled by touching /etc/hostname.$ifname"
			echo "wait 15" > $TMPDEST/etc/dhcp.$ifname
			printlog "Network interface $ifname configured to use DHCP by touching /etc/dhcp.$ifname"
			printlog "DHCP timeout for $ifname is set to 15 seconds"
		else
			staticif=1
			echo "$ipaddress netmask $netmask broadcast + up" \
			    >> $TMPDEST/etc/hostname.$ifname
			printlog "Network interface $ifname enabled by touching /etc/hostname.$ifname"
			printlog "Static conf for $ifname: $ipaddress netmask $netmask broadcast + up"
		fi

		if test $use_ipv6 != 0; then
			touch $TMPDEST/etc/hostname6.$ifname
			printlog "IPv6 enabled for $ifname by touching /etc/hostname6.$ifname"
		fi
		(( numconfigured = numconfigured + 1 ))
		(( ifnum = ifnum + 1 ))

		if boolean_check $_KS_use_dhcp; then
			if boolean_check $_KS_use_ipv6; then
				break
			fi
		fi
	done

	if test $staticif != 0; then
		if test "x$_KS_gateway" = x; then
			oneline_Yn_ask "Do you want configure static default gateway?"
			if test $? = $DIALOG_OK; then
				$DIALOG --title " Network configuration " \
					--form "\nStatic address configuration:" 12 40 3 \
					"Default gateway:" 2 2 "" 2 19 15 15 2>$DIALOG_RES
				gateway=$(dialog_res)
			fi
		else
			test "x$_KS_gateway" != x0 && gateway=$_KS_gateway
		fi

		if test "x$gateway" != x; then
			echo "$gateway" > $TMPDEST/etc/defaultrouter
			printlog "Default gateway set to $gateway in /etc/defaultrouter"
		fi

		if test "x$_KS_dns1" = x -a "x$_KS_dns2" = x; then
			oneline_Yn_ask "Do you want configure name server addresses?"
			if test $? = $DIALOG_OK; then
				$DIALOG --title " Network configuration " \
				    --form "\nStatic address configuration:" 14 38 5 \
				    "DNS address 1:" 2 2 "" 2 16 15 15 \
				    "DNS address 2:" 4 2 "" 4 16 15 15 2>$DIALOG_RES
				dns1=$(cat $DIALOG_RES|head -1)
				dns2=$(cat $DIALOG_RES|tail -1)
			fi
		else
			test "x$_KS_dns1" != x0 && dns1=$_KS_dns1
			test "x$_KS_dns2" != x0 && dns2=$_KS_dns2
		fi

		if test "x$dns1" != x -o "x$dns2" != x; then
			touch $TMPDEST/etc/resolv.conf
		fi
		if test "x$dns1" != x; then
			echo "nameserver $dns1" >> $TMPDEST/etc/resolv.conf
			printlog "Name Server1 set to $dns1 at /etc/resolv.conf"
		fi
		if test "x$dns2" != x; then
			echo "nameserver $dns2" >> $TMPDEST/etc/resolv.conf
			printlog "Name Server2 set to $dns2 at /etc/resolv.conf"
		fi
	else
		# If none is configured, use default behavior
		if test $numconfigured = 0; then
			touch $TMPDEST/etc/.UNCONFIGURED
			printlog "No network interfaces configured. Touching /etc/.UNCONFIGURED"
		fi
	fi

	# Bootstrap /etc/inet/hosts entry
	node_name="$hostname"
	node_fqnd="$node_name.$domainname"
	ipaddress_0="127.0.0.1"
	if test "x$_KS_ifaces" != x; then
		ipaddress_0=${_KS_iface_ip[0]}

	fi
	hosts_entry=$ipaddress_0$'\t'$node_name$'\t'$node_fqnd$'\tloghost'
	echo "$hosts_entry" >> $TMPDEST/etc/inet/hosts
	rm -f $TMPDEST/etc/inet/ipnodes; ln -s ./hosts $TMPDEST/etc/inet/ipnodes
	printlog "FQND $node_name.$domainname pointing to $ipaddress_0 added to /etc/inet/hosts"
}

customize_hdd_install()
{
	local pass1
	local pass2
	local user

	if test "x$_KS_root_passwd" = x; then
		while true; do
			$DIALOG --insecure --no-cancel --title " Set root password " \
				--passwordform " Root Password: " 12 50 5 \
				"Enter password:" 2 2 "" 2 20 19 19 \
				"Re-enter Password:" 4 2 "" 4 20 19 19 2>$DIALOG_RES
			pass1=$(cat $DIALOG_RES|head -1)
			pass2=$(cat $DIALOG_RES|tail -1)
			if test "x$pass1" != "x$pass2"; then
				oneline_msgbox Error "Passwords mismatch. Please repeat."
				continue
			fi
			oneline_Yn_ask "Are you done with assigning root password?"
			test $? = $DIALOG_OK && break
		done
	else
		pass1=$_KS_root_passwd
		test $_KS_root_passwd = "empty" && pass1=
		oneline_info "Configuring user 'root'..."
	fi

	# fix /etc/shadow
	chroot $TMPDEST /usr/sbin/pwconv 2>> $UPGRADE_LOG 1>&2
	rm -f $TMPDEST/etc/shadow- $TMPDEST/etc/shadow.org $TMPDEST/etc/passwd.org

	cp /etc/passwd /etc/passwd.$$
	cp /etc/shadow /etc/shadow.$$

	echo "root:$pass1" | chpasswd
	mv $TMPDEST/etc/passwd /tmp/passwd.tmp
	cat /etc/passwd | grep ^root: > $TMPDEST/etc/passwd
	cat /tmp/passwd.tmp | grep ^root: -v >> $TMPDEST/etc/passwd
	chown root:sys $TMPDEST/etc/passwd
	chmod 0644 $TMPDEST/etc/passwd

	mv $TMPDEST/etc/shadow /tmp/shadow.tmp
	cat /etc/shadow | grep ^root: | \
	    nawk -F: '{print $1":"$2":"$3"::::::"}' > $TMPDEST/etc/shadow
	cat /tmp/shadow.tmp | grep ^root: -v >> $TMPDEST/etc/shadow
	chown root:sys $TMPDEST/etc/shadow
	chmod 0400 $TMPDEST/etc/shadow

	printlog "Root password is set"

	restore_passwd_info

	if test "x$_KS_user_passwd" = x -o "x$_KS_user_name" = x; then
		while true; do
			while true; do
				$DIALOG --no-cancel --title " Create non-root user " \
				    --inputbox "\nUsername:" 10 30 2>$DIALOG_RES
				user=$(echo $(dialog_res))
				test "x$user" != x && break
			done

			if cat /etc/passwd|awk -F: '{print $1}'|grep "^$user$" >/dev/null; then
				oneline_msgbox Error "User $user already exists."
				continue
			fi

			while true; do
				$DIALOG --insecure --no-cancel \
					--title " Set password for $user " \
					--passwordform " Password for $user: " 12 50 5 \
				"Enter password:" 2 2 "" 2 20 19 19 \
				"Re-enter Password:" 4 2 "" 4 20 19 19 2>$DIALOG_RES
				pass1=$(cat $DIALOG_RES|head -1)
				pass2=$(cat $DIALOG_RES|tail -1)
				if test "x$pass1" != "x$pass2"; then
					oneline_msgbox Error "Passwords mismatch. Please repeat."
					continue
				fi
				oneline_Yn_ask "Are you done with assigning password for $user?"
				test $? = $DIALOG_OK && break
			done
			oneline_Yn_ask "Do you want to commit the changes (username $user)?"
			test $? = $DIALOG_OK && break
		done
	else
		user=$_KS_user_name
		pass1=$_KS_user_passwd
		test $_KS_user_passwd = "empty" && pass1=
		oneline_info "Configuring user '$user'..."
	fi

	mkdir -p /export/home
	rm -rf /export/home/$user
	local user1000=$(cat /etc/passwd|grep "x:1000:"|awk -F: '{print $1}')
	test "x$user1000" != x && userdel $user1000 2>/dev/null
	userdel $user 2> /dev/null
	rm -f /etc/passwd.lock
	useradd -u 1000 -d /export/home/$user -g staff -s /bin/bash $user

	cp /etc/passwd /etc/passwd.$$
	cp /etc/shadow /etc/shadow.$$

	echo "$user:$pass1" | chpasswd
	cat /etc/passwd | egrep "^$user" >> $TMPDEST/etc/passwd
	cat /etc/shadow | egrep "^$user" |  nawk -F: '{print $1":"$2":"$3"::::::"}' >> $TMPDEST/etc/shadow

	mkdir -p $TMPDEST/export/home/$user
	find $TMPDEST/etc/skel -name ".*" -type f -exec cp {} $TMPDEST/export/home/$user/ \;
	chown -R $user:staff $TMPDEST/export/home/$user
	echo "$user    ALL=(ALL) ALL" >> $TMPDEST/etc/sudoers
#	echo "root    ALL=(ALL) ALL" >> $TMPDEST/etc/sudoers

	printlog "Added user: $user and assigned new password"

	restore_passwd_info

	configure_network

	oneline_info "Customizing software..."

	# We need device reconfiguration
	touch $TMPDEST/reconfigure
	printlog "Touching /reconfigure to force device reconfiguration"

	# Tell NFS4 to not prompt us for default domain
	touch $TMPDEST/etc/.NFS4inst_state.domain
	printlog "Touching /etc/.NFS4inst_state.domain to NFS4 not to prompt for domain"

	# Prepare system to use DNS
	touch $TMPDEST/etc/resolv.conf
	cp $TMPDEST/etc/nsswitch.dns $TMPDEST/etc/nsswitch.conf
	cp $REPO/eventhook $TMPDEST/etc/dhcp/
	printlog "Enable /etc/nsswitch.conf to use DNS resolver"

	# Set root shell to /bin/bash
	sed 's/sbin\/sh/bin\/bash/g' $TMPDEST/etc/passwd > /tmp/output
	cp /tmp/output $TMPDEST/etc/passwd
	chmod 0644 $TMPDEST/etc/passwd
	chown root:sys $TMPDEST/etc/passwd
	printlog "Root SHELL is set to /bin/bash"

	apply_kbd

	customize_common

	oneline_info "Setting up vfstab..."
	vfstab_setup

	oneline_info "Customizing bootenv.rc..."
	customize_bootenv

	oneline_info "Customizing sources.list..."
	customize_sources

	oneline_info "Populating /dev..."
	devfsadm -r $TMPDEST
	printlog "Populated /dev"

	callback _KS_callback_post_install
}

customize_common()
{
	# Copy over customized SMF manifests and methods
	cp $REPO/nexenta-sysidtool.xml $TMPDEST/var/svc/manifest/system/
	chmod 0444 $TMPDEST/var/svc/manifest/system/nexenta-sysidtool.xml
	chown root:sys $TMPDEST/var/svc/manifest/system/nexenta-sysidtool.xml

	cp $REPO/nexenta-sysidtool-net $TMPDEST/lib/svc/method/
	chmod 0555 $TMPDEST/lib/svc/method/nexenta-sysidtool-net
	chown root:bin $TMPDEST/lib/svc/method/nexenta-sysidtool-net

	cp $REPO/nexenta-sysidtool-system $TMPDEST/lib/svc/method/
	chmod 0555 $TMPDEST/lib/svc/method/nexenta-sysidtool-system
	chown root:bin $TMPDEST/lib/svc/method/nexenta-sysidtool-system

	printlog "Installed sysidtools SMF methods"

	#
	# Work around GNU's "uname -S" problem; we use /bin/hostname
	# to set machine's hostname instead.  We should probably fix
	# GNU's uname at some point.
	#
	sed -e 's/sbin\/uname\ -S/bin\/hostname/' < \
	    $TMPDEST/lib/svc/method/identity-node > /tmp/output
	cp /tmp/output $TMPDEST/lib/svc/method/identity-node

	cp /etc/release $TMPDEST/etc/release
	printlog "Installed /etc/release"

	cp /etc/default/init $TMPDEST/etc/default/init
	printlog "Installed /etc/default/init"

	cp /etc/rtc_config $TMPDEST/etc/rtc_config
	printlog "Installed /etc/rtc_config"
}

customize_hdd_upgrade()
{
	oneline_info "Customizing software..."

	# We need device reconfiguration
	touch $TMPDEST/reconfigure

	customize_common

	oneline_info "Customizing bootenv.rc..."
	customize_bootenv

	oneline_info "Populating /dev..."
	devfsadm -r $TMPDEST
	printlog "Populated /dev"

	callback _KS_callback_post_upgrade
}

reboot_msg_ks()
{
	local msg=$1
	local conf=""
	local i=
	local applied=""

	test "x$_KS_hostname" != x &&       conf="$conf     * Host Name: $_KS_hostname\n"
	test "x$_KS_domainname" != x &&     conf="$conf     * Domain Name: $_KS_domainname\n"
	test "x$_KS_root_passwd" != x &&    conf="$conf     * Root Password: See User Guide\n"
	test "x$_KS_user_name" != x &&      conf="$conf     * Default User Name: $_KS_user_name\n"
	test "x$_KS_user_passwd" != x &&    conf="$conf     * Default User Password: See User Guide\n"
	test "x$_KS_time_zone" != x &&      conf="$conf     * Default Time Zone: $_KS_time_zone\n"
	test "x$_KS_use_ipv6" != x &&       conf="$conf     * IPv6 enabled: $(boolean2human $_KS_use_ipv6)\n"
	test "x$_KS_use_dhcp" != x &&       conf="$conf     * DHCP enabled: $(boolean2human $_KS_use_dhcp)\n"
	if test "x$_KS_use_dhcp" = x0; then
		for i in $_KS_ifaces; do
			if test "x${_KS_iface_ip[$i]}" != x -a "x${static_ifnames[$i]}" != x; then
					    conf="$conf     * Network Interface ${static_ifnames[$i]}: ${_KS_iface_ip[$i]}/${_KS_iface_mask[$i]}\n"
			fi
		done
	fi
	test "x$_KS_use_grub_mbr" != x &&   conf="$conf     * GRUB installed on MBR: $(boolean2human $_KS_use_grub_mbr)\n"
	test "x$_KS_autopart_export_home" != x0 -a $ROOTDISK_TYPE = "ufs" && \
					    conf="$conf     * ZFS volume 'home' mounted at: /export/home\n"

	test "x$conf" != x && applied="\nThe following configuration has been applied:\n\n$conf"

	$DIALOG --title " Successful Installation " --msgbox "\n
    $msg.\n$applied\n
    Press 'OK' to reboot into $TITLE\n\n" 0 0
}

reboot_exit()
{
	cd ${CURDIR}
	sync
	cleanup
	if [ ! -z "$*" ]; then
		if test "x$_KS_auto_reboot" != x1; then
			if test "x$_KS_auto_reboot" != x; then
				reboot_msg_ks "$*"
				touch /.nexenta-try-reboot
			else
				message_Yn_ask "\n $*" "\n    Would you like to reboot now?    "
				if test $? -eq $DIALOG_OK; then
					touch /.nexenta-try-reboot
				fi
			fi
		else
			touch /.nexenta-try-reboot
			if test "x$auto_install" != "x1"; then
				oneline_info "$*"
				sleep 2
			fi
		fi
	fi
	clear
	screen -X quit >/dev/null
	clear
	exit
}

install_grub()
{
	if test $UPGRADE = 1; then
		# don't do anything... grub-data should take care
		return
	fi

	local disk=$(echo $slice_root|sed -e "s/.*\/\(.*\)s[0-9]\+$/\1/")
	local mbr=""
	if test "x$_KS_use_grub_mbr" = x; then
		message_Yn_ask "
	Installing GRUB on the master boot record overrides any boot manager currently installed on the disk '$disk'. The system will always boot from GRUB in the OS partition regardless of which fdisk partition is active." "Install GRUB on the master boot record anyway? (recommended)"
		if test $? != $DIALOG_OK; then
			oneline_msgbox Warning "Master boot record is NOT updated! You will have to manually update your existing boot manager."
		else
			mbr="-f -m"
			mbr_desc=" on MBR"
		fi
	else
		if test $_KS_use_grub_mbr = 1; then
			mbr="-f -m"
			mbr_desc=" on MBR"
		fi
	fi

	oneline_info "Installing GRUB$mbr_desc..."

	# installing grub loader
	cd $TMPDEST/boot/grub
	if test "x$zfs_root_slices" != x; then
		for s0_slice in `echo $zfs_root_slices|sed -e "s/ /\n/g"`; do
			installgrub $mbr $TMPDEST/boot/grub/stage1 $TMPDEST/boot/grub/stage2 /dev/rdsk/$s0_slice >/dev/null
			printlog "GRUB installed on ZFS slice $s0_slice"
		done
	else
		installgrub $mbr $TMPDEST/boot/grub/stage1 $TMPDEST/boot/grub/stage2 `echo $slice_root|sed -e "s/\/dsk/\/rdsk/"` >/dev/null
		printlog "GRUB installed on $slice_root"
	fi

	# this could be used for chainload configuration
	#echo "disk" > $AUTOPART_CMD_FILE
	#echo "0" >> $AUTOPART_CMD_FILE
	#echo "q" >> $AUTOPART_CMD_FILE
	#local hd=$(format -f $AUTOPART_CMD_FILE 2>&1 | awk -F. "/[0-9]+\. $disk/ {print \$1}" | sed -e "s/^\s* //")

	local part=0
	fdisk -W - /dev/rdsk/${disk}p0 | awk '!/^\*/ && !/^$/ {print $0}' |\
	while read id act bhead bsect bcyl ehead esect ecyl rsect numsect; do
		if test $id == 191; then
			echo -n $part > $AUTOPART_CMD_FILE
			break
		fi
		let part=$num+1
	done
	part=$(cat $AUTOPART_CMD_FILE 2>/dev/null)
	rm -f $AUTOPART_CMD_FILE

	local slice=$(echo $slice_root|sed -e "s/.*\/.*s\([0-9]\+\)$/\1/")

	# make sure hd is a correct value
	#if test "x$hd" != x -a $hd -ge 1 2>/dev/null; then
	#	sed -i -e "s/hd0,/hd$hd,/" $TMPDEST/boot/grub/menu.lst
	#fi

	# make sure part is a correct value
	if test "x$part" != x -a $part -ge 1 2>/dev/null; then
		sed -i -e "s/\(hd[0-9]\+,\)./\1$part/" $TMPDEST/boot/grub/menu.lst
	fi

	# make sure slice is a correct value
	if test "x$slice" != x -a $slice -ge 1 2>/dev/null; then
		test $slice == 0 && slice=a
		test $slice == 1 && slice=b
		test $slice == 2 && slice=c
		test $slice == 3 && slice=d
		test $slice == 4 && slice=e
		test $slice == 5 && slice=f
		test $slice == 6 && slice=g
		test $slice == 7 && slice=h
		test $slice == 8 && slice=i
		test $slice == 9 && slice=j
		sed -i -e "s/\(hd[0-9]\+,[0-9]\+,\)./\1$slice/" $TMPDEST/boot/grub/menu.lst
	fi

	# Edit menu.lst for curently distro
	sed -i -e "s/_#N.*N#_/$grub_n_title/" $TMPDEST/boot/grub/menu.lst
	sed -i -e "s/_#S.*S#_/$grub_s_title/" $TMPDEST/boot/grub/menu.lst

	# enable ZFS/Boot feature in the GRUB menu for all entries
	if test $ROOTDISK_TYPE = "zfs" && \
	   ! cat $TMPDEST/boot/grub/menu.lst | grep "ZFS-BOOTFS" >/dev/null; then

		# make sure GRUB passes ZFS-BOOTFS property up to the kernel
		sed -i -e "s/\/unix/\/unix -B \$ZFS-BOOTFS/" $TMPDEST/boot/grub/menu.lst

		# but remove it for safe mode...
		sed -i -e "s/\/unix .* -s/\/unix -s/" $TMPDEST/boot/grub/menu.lst

		# no need to specify root...
		sed -i -e "/^[ 	]*root[ 	]\+(/d" $TMPDEST/boot/grub/menu.lst

		# copy menu.lst on syspool
		umount /$ZFS_ROOTPOOL 2>/dev/null
		if zfs set mountpoint=/$ZFS_ROOTPOOL $ZFS_ROOTPOOL; then
			mkdir -p /$ZFS_ROOTPOOL/boot/grub
			cp $TMPDEST/boot/grub/menu.lst /$ZFS_ROOTPOOL/boot/grub
			umount /$ZFS_ROOTPOOL 2>/dev/null
			zfs set mountpoint=none $ZFS_ROOTPOOL
		fi
	fi

	printlog "Updated /boot/grub/menu.lst"

	cd /
}

customize_bootenv()
{
	# nothing to do for Boot Anywhere
	if [ $BOOT_ANYWHERE -ne 0 ]; then
		return
	fi

	echo "setprop prealloc-chunk-size 0x2000" >> $TMPDEST/boot/solaris/bootenv.rc
	if test $ROOTDISK_TYPE = "ufs"; then
		local path=`ls -l $slice_root|awk '{print $11}'|sed -e "s/.*\/devices//"`
		echo "setprop bootpath $path" >> $TMPDEST/boot/solaris/bootenv.rc
	fi
	echo "setprop console 'text'" >> $TMPDEST/boot/solaris/bootenv.rc
	printlog "Updated /boot/solaris/bootenv.rc"
}

r2b() { echo `echo $1 | sed -e "s/\/rdsk/\/dsk/"`; }
b2r() { echo `echo $1 | sed -e "s/\/dsk/\/rdsk/"`; }

mntdev()
{
	if [ $BOOT_ANYWHERE -ne 0 ]; then
		echo `basename $1 | nawk -F s '{ print "/.nexenta/s"$2 }'`
	else
		if [ "$RM_DISK" = "" ]; then
			r2b $1
		else
			r2b /dev/rdsk/c0t0d0s0
		fi
	fi
}

fsckdev()
{
	if [ $BOOT_ANYWHERE -ne 0 ]; then
#		echo `basename $1 | nawk -F s '{ print "/.nexenta/s"$2 }'`
		echo "-"
	else
		if [ "$RM_DISK" = "" ]; then
			b2r $1
		else
			b2r /dev/dsk/c0t0d0s0
		fi
	fi
}

add_signature()
{
	echo "$signature" > $1/.nexenta
	chown root:root $1/.nexenta
	chmod 0400 $1/.nexenta
	printlog "Signature $1/.nexenta added"
}

vfstab_setup()
{
	# Customize /etc/vfstab
	if test $ROOTDISK_TYPE = zfs; then
	echo "$ZFS_ROOTFS	-		/	zfs	-	no	-" >> $TMPDEST/etc/vfstab
	else
	echo "$(mntdev $slice_root)	$(fsckdev $slice_root)	/	ufs	1	no	-" >> $TMPDEST/etc/vfstab
	fi

	test x$slice_usr != x &&
	echo "$(mntdev $slice_usr)	$(fsckdev $slice_usr)	/usr	ufs	2	yes	-" >> $TMPDEST/etc/vfstab

	test x$slice_var != x &&
	echo "$(mntdev $slice_var)	$(fsckdev $slice_var)	/var	ufs	2	yes	-" >> $TMPDEST/etc/vfstab

	test x$slice_opt != x &&
	echo "$(mntdev $slice_opt)	$(fsckdev $slice_opt)	/opt	ufs	2	yes	-" >> $TMPDEST/etc/vfstab

#	test x$slice_export_home != x &&
#	echo "$ZPOOL_HOME	$(fsckdev $slice_export_home)	/export/home	zfs	2 yes	-" >> $TMPDEST/etc/vfstab

	if boolean_check $_KS_autopart_use_swap_zvol; then
		echo "/dev/zvol/dsk/$slice_swap	-		-	swap	-	no	-" >> $TMPDEST/etc/vfstab
	else
		for sswap in `echo $slice_swap|sed -e "s/ /\n/g"`; do
			echo "$(mntdev $sswap)	-		-	swap	-	no	-" >> $TMPDEST/etc/vfstab
		done
	fi

	printlog "Installed /etc/vfstab"

	if [ $BOOT_ANYWHERE -ne 0 ]; then
		add_signature $TMPDEST
	fi
}

configure_repository()
{
	rm -f $DBFILE >/dev/null 2>&1

	manifest_list=`find ${TMPDEST}/var/svc/manifest/* \
	    -type f -name "*.xml" -print`

	set -- ${manifest_list}

	CONFIGD=${TMPDEST}/lib/svc/bin/svc.configd
	SVCCFG=${TMPDEST}/usr/sbin/svccfg
	DTD=${TMPDEST}/usr/share/lib/xml/dtd/service_bundle.dtd.1

	# Create the repository with smf/manifest property
	PKG_INSTALL_ROOT=${TMPDEST} SVCCFG_DTD=${DTD} \
	SVCCFG_REPOSITORY=${DBFILE} SVCCFG_CONFIGD_PATH=${CONFIGD} \
	${SVCCFG} add smf/manifest >/dev/null 2>&1

	# This will significantly speed up next reboot
	while [ $# -gt 0 ]; do
		# Import manifests into the repository
		SVCCFG_CHECKHASH=1 \
		PKG_INSTALL_ROOT=${TMPDEST} SVCCFG_DTD=${DTD} \
		SVCCFG_REPOSITORY=${DBFILE} SVCCFG_CONFIGD_PATH=${CONFIGD} \
		${SVCCFG} import $1 >/dev/null 2>&1

		shift
	done

	plat=`uname -i`

	cd ${TMPDEST}/var/svc/profile
	rm -f inetd_services.xml >/dev/null 2>&1
	ln -fs inetd_generic.xml inetd_services.xml >/dev/null 2>&1
	rm -f name_service.xml >/dev/null 2>&1
	ln -fs ns_dns.xml name_service.xml >/dev/null 2>&1
	ln -fs platform_${plat}.xml platform.xml >/dev/null 2>&1

	PKG_INSTALL_ROOT=${TMPDEST} SVCCFG_DTD=${DTD} \
	SVCCFG_REPOSITORY=${DBFILE} SVCCFG_CONFIGD_PATH=${CONFIGD} \
	${SVCCFG} apply ${TMPDEST}/var/svc/profile/generic.xml >/dev/null 2>&1

	PKG_INSTALL_ROOT=${TMPDEST} SVCCFG_DTD=${DTD} \
	SVCCFG_REPOSITORY=${DBFILE} SVCCFG_CONFIGD_PATH=${CONFIGD} \
	${SVCCFG} apply ${TMPDEST}/var/svc/profile/platform.xml >/dev/null 2>&1

	PKG_INSTALL_ROOT=${TMPDEST} SVCCFG_DTD=${DTD} \
	SVCCFG_REPOSITORY=${DBFILE} SVCCFG_CONFIGD_PATH=${CONFIGD} \
	${SVCCFG} -s vtdaemon setprop options/secure=false >/dev/null 2>&1

	# Store the repository under etc/svc/repository.db
	chown root:sys ${DBFILE}
	mv ${DBFILE} ${TMPDEST}/etc/svc/repository.db
	printlog "SMF repository configured at /etc/svc/repository.db"
}

update_boot_archive()
{
	test ! -d $TMPDEST/etc/devices && mkdir $TMPDEST/etc/devices
	if test $ROOTDISK_TYPE = "zfs"; then
		cp /etc/zfs/zpool.cache $TMPDEST/etc/zfs
	fi
	cp -f /etc/path_to_inst $TMPDEST/etc
	cd $TMPDEST
	SUN_PERSONALITY=1 bootadm update-archive -R $TMPDEST >/dev/null
	printlog "Boot archive created: /platform/i86pc/boot_archive"
	cp -a $REPO/x86.miniroot-safe $TMPDEST/boot
	printlog "Safe Boot archive created: /boot/x86.miniroot-safe"
	rm -f $TMPDEST/etc/zfs/zpool.cache
}

cleanup_after_install()
{
	find $TMPDEST/usr -type d -name ".svn" | xargs rm -rf
	rm $TMPDEST/*.err > /dev/null 2>&1
	rm $TMPDEST/*.orig > /dev/null 2>&1
	rm -f $TMPDEST/var/cache/apt/*.bin > /dev/null 2>&1
	rm -f $TMPDEST/var/cache/apt/archives/*.deb > /dev/null 2>&1
	rm -rf $TMPDEST/var/cache/apt/archives > /dev/null 2>&1
	rm -f $TMPDEST/etc/skel/.profile.dpkg-dist > /dev/null 2>&1
	mkdir -p $TMPDEST/var/cache/apt/archives/partial
	test -d $TMPDEST/var/log/apt || mkdir -p $TMPDEST/var/log/apt
	cp $TMPDEST/debootstrap/debootstrap.log $TMPDEST/var/log/apt/debootstrap.log
	rm -rf $TMPDEST/debootstrap > /dev/null 2>&1

	test "x$slice_usr" != x && umount -f $TMPDEST/usr > /dev/null 2>&1
	test "x$slice_var" != x && umount -f $TMPDEST/var > /dev/null 2>&1
	test "x$slice_opt" != x && umount -f $TMPDEST/opt > /dev/null 2>&1
	test "x$slice_export_home" != x && umount -f $TMPDEST/export/home > /dev/null 2>&1
	umount -f $TMPDEST$REPO > /dev/null 2>&1
	umount -f $TMPDEST> /dev/null 2>&1
}

customize_sources()
{
	echo "# Main repository sources" > $TMPDEST/etc/apt/sources.list
	echo "deb $_KS_apt_sources" >> $TMPDEST/etc/apt/sources.list
	echo "deb-src $_KS_apt_sources" >> $TMPDEST/etc/apt/sources.list
	if test "x$_KS_plugin_sources" != x; then
		echo >> $TMPDEST/etc/apt/sources.list
		echo "# Third-party and commercial NexentaStor plugins sources" >> $TMPDEST/etc/apt/sources.list
		echo "deb $_KS_plugin_sources" >> $TMPDEST/etc/apt/sources.list
		echo "deb-src $_KS_plugin_sources" >> $TMPDEST/etc/apt/sources.list
	fi
	rm -f "$TMPDEST/var/lib/apt/lists/*" 2>/dev/null 1>&2
	printlog "Installed /etc/apt/sources.list"
}

customize_X()
{
	# session manager wants it
	test ! -d $TMPDEST/dev/X && mkdir $TMPDEST/dev/X
	chmod 1777 $TMPDEST/dev/X
}

restore_passwd_info()
{
	rm -f /tmp/passwd.tmp
	rm -f /tmp/shadow.tmp
	if [ -f /etc/passwd.$$ ]; then
		cp /etc/passwd.$$ /etc/passwd
		rm -f /etc/passwd.$$
	fi
	if [ -f /etc/shadow.$$ ]; then
		cp /etc/shadow.$$ /etc/shadow
		rm -f /etc/shadow.$$
	fi
}

cleanup_pre()
{
	upgrade_fini
	userdel $testusr > /dev/null 2>&1
	test -f "$TMPDEST/sbin/start-stop-daemon.REAL" && \
		mv "$TMPDEST/sbin/start-stop-daemon.REAL" "$TMPDEST/sbin/start-stop-daemon"
	rm -f $TMPDEST/var/tmp/required.lst
	rm -f $TMPDEST/var/tmp/base.lst
	if [ $MEMSCRATCH -ne 0 ]; then
		mount -p | grep $TMPDEST/var/cache/apt/archives
		if [ $? -eq 0 ]; then
			umount -f $TMPDEST/var/cache/apt/archives \
			    > /dev/null 2>&1
		fi
	fi
	test "x$slice_usr" != x && umount $TMPDEST/usr > /dev/null 2>&1
	test "x$slice_var" != x && umount $TMPDEST/var > /dev/null 2>&1
	test "x$slice_opt" != x && umount $TMPDEST/opt > /dev/null 2>&1
	test "x$slice_export_home" != x && umount $TMPDEST/export/home > /dev/null 2>&1
	umount -f $TMPDEST$REPO > /dev/null 2>&1
	umount -f $TMPREPO > /dev/null 2>&1
	umount -f $TMPDEST > /dev/null 2>&1
	rm -f $RMFORMAT_TMP >/dev/null 2>&1
	rm -f $DBFILE >/dev/null 2>&1
	rm -f $UPMAP >/dev/null 2>&1
	rm -f $RDMAP >/dev/null 2>&1
	rm -f $TMP_FILE >/dev/null 2>&1
	rm -f $TMPMESSAGES >/dev/null 2>&1
	restore_passwd_info
	UPGRADE=0
	UPGRADE_DISK=""
	RM_DISK=""
}

cleanup()
{
	# close log
	exec 3>&-
	cleanup_pre
	svcadm disable system/filesystem/rmvolmgr > /dev/null 2>&1
	rm -f $DIALOG_RES >/dev/null 2>&1
}

aborted_sig()
{
	oneline_Yn_ask "Abort installation process?"
	test $? = $DIALOG_OK && aborted
}

aborted()
{
	oneline_msgbox Warning "Installation has been interrupted."
	cleanup
	screen -X quit >/dev/null
	exit 1
}

kbd_layouts()
{
	echo | kbd -s | egrep "^[ \t]*[0-9]+" | awk '{print $2}' > /tmp/a
	echo | kbd -s | egrep "^[ \t]*[0-9]+" | awk '{print $4}' >> /tmp/a
	for l in `cat /tmp/a`; do
		kbd -s $l >/dev/null
		kbd -l | awk '/^layout.*=/ {print $1}' | awk -F= "{print \"${l}\",\$2}"
	done
	kbd -s US-English >/dev/null
	rm -f /tmp/a
}

select_kbd()
{
	oneline_info "Preparing keyboard layout information..."
	$DIALOG --default-item 'US-English' --nocancel --menu 'Please select your keyboard layout from the list...' 20 70 12 $(kbd_layouts) 2>$DIALOG_RES

	SELECTED_KBD_TYPE=$(dialog_res)
}

apply_xkbmap()
{
	cat > /tmp/xkbmap <<EOF
US-English:us
UK-English:gb
Czech:cz
Danish:dk
Dutch:nl
French:fr
French-Canadian:fr
German:de
Greek:gr
Hungarian:hu
Italian:it
Japanese(106):
Japanese(J3100):jp
Latvian:lv
Lithuanian:lt
Polish:pl
Korean:us
Norwegian:no
Portuguese:pt
Russian:ru
Spanish:es
Swedish:se
Swiss-French:ch
Swiss-German:ch
Taiwanese:vn
Turkish:tr
EOF

}

apply_kbd()
{
	sed -i -e "s/^\(setprop[ \t]\+keyboard-layout[ \t]\+\).*/\1$SELECTED_KBD_TYPE/" $TMPDEST/boot/solaris/bootenv.rc
	printlog "Using selected keyboard-layout '$SELECTED_KBD_TYPE'"
}

tz_by_posix()
{
	# Ask the user for a POSIX TZ string.  Check that it conforms.
	while
		$DIALOG --no-cancel --title " Time Zone " \
		    --inputbox "\nPlease enter the desired value of the TZ environment variable. For example, GST-10 is a zone named GST that is 10 hours ahead (east) of UTC (GMT/Zulu)." 0 0 2>$DIALOG_RES

		TZ=$(dialog_res)
		env LC_ALL=C nawk -v TZ="$TZ" 'BEGIN {
			tzname = "[^-+,0-9][^-+,0-9][^-+,0-9]+"
			time = "[0-2]?[0-9](:[0-5][0-9](:[0-5][0-9])?)?"
			offset = "[-+]?" time
			date = "(J?[0-9]+|M[0-9]+\.[0-9]+\.[0-9]+)"
			datetime = "," date "(/" time ")?"
			tzpattern = "^(:.*|" tzname offset "(" tzname \
			  "(" offset ")?(" datetime datetime ")?)?)$"
			if (TZ ~ tzpattern) exit 1
			exit 0
		}'
	do
		oneline_msgbox_slim "Time Zone" "$TZ is not a conforming POSIX time zone string."

	done
	TZ_for_date=$TZ
}

tz_by_location()
{
	# Get list of names of countries in the continent or ocean.
	countries=$(nawk -F'\t' \
		-v continent="$continent" \
		-v TZ_COUNTRY_TABLE="$TZ_COUNTRY_TABLE" \
	'
		/^#/ { next }
		$3 ~ ("^" continent "/") {
			if (!cc_seen[$1]++) cc_list[++ccs] = $1
		}
		END {
			while (getline <TZ_COUNTRY_TABLE) {
				if ($0 !~ /^#/) cc_name[$1] = $2
			}
			for (i = 1; i <= ccs; i++) {
				country = cc_list[i]
				if (cc_name[country]) {
				  country = cc_name[country]
				}
				print country
			}
		}
	' <$TZ_ZONE_TABLE | sort -f)

	rlist=""
	IFS=$newline
	c=0
	cn=0
	declare -a icountry
	for country in $countries
	do
		cn=$(( $c + 1 ))
		rlist="$rlist $cn \"$country\" off"
		icountry[c]=$country
		c=$cn
	done
	unset IFS

	rm -f $TMP_FILE >/dev/null
	echo "$DIALOG --default-item 25 --ok-label Select --no-cancel --title \" Location: $continent \" --radiolist \"\nPlease select a country or region.\" 0 0 0 $rlist" > $TMP_FILE

	while true; do
		# If there's more than one country, ask the user which one.
		case $countries in
		*"$newline"*)
			. $TMP_FILE 2>$DIALOG_RES
			if test $? != $DIALOG_OK; then
				continue
			fi

			cn=$(dialog_res)
			c=$(( $cn - 1 ))
			country="${icountry[$c]}"
			if test "x$country" != x; then
				break;
			fi
			oneline_msgbox "Time Zone" "Please select a country."
			;;
		*)
			country=$countries
			break;
			;;
		esac
	done
	rm -f $TMP_FILE >/dev/null

	# Get list of names of time zone rule regions in the country.
	regions=$(nawk -F'\t' \
		-v country="$country" \
		-v TZ_COUNTRY_TABLE="$TZ_COUNTRY_TABLE" \
	'
		BEGIN {
			cc = country
			while (getline <TZ_COUNTRY_TABLE) {
				if ($0 !~ /^#/  &&  country == $2) {
					cc = $1
					break
				}
			}
		}
		$1 == cc { print $5 }
	' <$TZ_ZONE_TABLE)

	rlist=""
	IFS=$newline
	c=0
	cn=0
	declare -a iregion
	for region in $regions
	do
		cn=$(( $c + 1 ))
		rlist="$rlist $cn \"$region\" off"
		iregion[c]=$region
		c=$cn
	done
	unset IFS

	rm -f $TMP_FILE >/dev/null
	echo "$DIALOG --default-item 21 --ok-label Select --no-cancel --title \" Location: $continent/$country \" --radiolist \"\nPlease select one of the following time zone regions.\" 0 0 0 $rlist" > $TMP_FILE

	while true; do
		# If there's more than one region, ask the user which one.
		case $regions in
		*"$newline"*)
			. $TMP_FILE 2>$DIALOG_RES
			if test $? != $DIALOG_OK; then
				continue
			fi

			cn=$(dialog_res)
			c=$(( $cn - 1 ))
			region="${iregion[$c]}"
			if test "x$region" != x; then
				break;
			fi
			oneline_msgbox "Time Zone" "Please select a region."
			;;
		*)
			region=$regions
			break;
			;;
		esac
	done
	rm -f $TMP_FILE >/dev/null

	region=$(echo $region | sed -e 's/_/ /g')

	# Determine TZ from country and region.
	TZ=$(nawk -F'\t' \
		-v country="$country" \
		-v region="$region" \
		-v TZ_COUNTRY_TABLE="$TZ_COUNTRY_TABLE" \
	'
		BEGIN {
			cc = country
			while (getline <TZ_COUNTRY_TABLE) {
				if ($0 !~ /^#/  &&  country == $2) {
					cc = $1
					break
				}
			}
		}

		$1 == cc && $5 == region {
			# Check if tzname mapped to
			# backward compatible tzname
			if ($4 == "-") {
				print $3
			} else {
				print $4
			}
		}
	' <$TZ_ZONE_TABLE)

	# Make sure the corresponding zoneinfo file exists.
	TZ_for_date=$TZDIR/$TZ
	<$TZ_for_date || reboot_exit "Time zone files are not set up correctly"

	# Absolute path TZ's not supported
	TZ_for_date=$TZ
}

apply_tz()
{
	local TZ=$1

	grep "^TZ=" /etc/default/init >/dev/null && {
		rm -f $TMP_FILE >/dev/null
		sed -e '/^TZ=.*$/ d' /etc/default/init > $TMP_FILE
		cp $TMP_FILE /etc/default/init
		rm -f $TMP_FILE >/dev/null
	}
	test ! -f /etc/default/init && touch /etc/default/init
	echo "TZ=$TZ" >> /etc/default/init

	/usr/sbin/rtc -z $TZ >/dev/null
	/usr/sbin/rtc -c >/dev/null
	printlog "Time Zone set to $TZ"
}

select_tz()
{
	# Make sure the tables are readable.
	for f in $TZ_COUNTRY_TABLE $TZ_ZONE_TABLE
	do
		<$f || reboot_exit "Time zone files are not set up correctly"
	done

	continent=
	country=
	region=

	rlist="\
Africa        	Africa					off	\
America      	Americas				off	\
Antarctica    	Antarctica				off	\
Arctic		\"Arctic Ocean\"			off	\
Asia          	Asia					off	\
Atlantic	\"Atlantic Ocean\"			off	\
Australia     	Australia				off	\
Europe        	Europe					off	\
Pacific		\"Pacific Ocean\"			off	\
Indian		\"Indian Ocean\"			off	\
none          	\"Specify time zone using POSIX TZ format\"	off	\
"

	rm -f $TMP_FILE >/dev/null
	echo "$DIALOG --default-item 'Pacific' --ok-label Select --no-cancel --title \" Location \" --radiolist \"\nPlease identify a location so that time zone rules can be set correctly.  You may select none to manually enter a TZ string.\" 0 0 0 $rlist" > $TMP_FILE

	while true; do
		. $TMP_FILE 2>$DIALOG_RES
		if test $? != $DIALOG_OK; then
			continue
		fi

		continent=$(dialog_res)
		if test "x$continent" != x; then
			break;
		fi

		oneline_msgbox "Time Zone" "Please select a continent/ocean."
	done
	rm -f $TMP_FILE >/dev/null

	case $continent in
	none)	tz_by_posix ;;
	*)	tz_by_location ;;
	esac

	rlist=""
	case $country+$region in
	?*+?*)	rlist="        $country\n        $region\n";;
	?*+)	rlist="        $country\n";;
	+)	rlist="        TZ='$TZ'\n"
	esac

	extra_info=$(printf "$INFO_TZ" "$TZ")

	oneline_Yn_ask "The following information has been given:\n\n The Current time zone selected is ---> $TZ"
	if test $? = $DIALOG_OK; then
		apply_tz $TZ
		return 0
	fi
	return 1
}

select_profile()
{
	# no need to select profile if just one supplied
	local num=$(echo $_KS_profiles|wc|awk '{print $2}')
	test $num -le 1 && return

	local msg="$TITLE allows to select installation profile. You may choose to select one which suits your needs the most."
	local rlist=""
	for p in $_KS_profiles; do
		local en="off"
		test "x$p" = "x$_KS_profile_selected" && en="on"
		rlist="$rlist \"${_KS_profile_name[$p]}\" \"${_KS_profile_desc[$p]}\" $en"
		msg="$msg\n\n${_KS_profile_longdesc[$p]}"
	done
	msg="$msg\n\nSelect your default profile:"
	eval $DIALOG --no-cancel --ok-label Select --title \" Default User Profile \" --radiolist \"$msg\" 19 70 3 $rlist 2>$DIALOG_RES

	DEFAULT_PROFILE=$(dialog_res)
	for p in $_KS_profiles; do
		if test "x${_KS_profile_name[$p]}" = "x$DEFAULT_PROFILE"; then
			_KS_profile_selected=$p
			break
		fi
	done
	printlog "Using profile: $DEFAULT_PROFILE"
}

apply_profile()
{
	oneline_info "Applying user profile..."
	mkdir -p $TMPDEST/var/tmp
	cd $TMPDEST/var/tmp
	ln -sf ../../$REPO/required-$DEFAULT_PROFILE.lst required.lst
	ln -sf ../../$REPO/base-$DEFAULT_PROFILE.lst base.lst
	cd - >/dev/null
	printlog "Applied selected profile: $DEFAULT_PROFILE"
}

check_components()
{
	# XXX: add more check here
	if [ ! -f /usr/sbin/debootstrap ]; then
		echo "Debootstrap is not present on this system."
		screen -X quit >/dev/null
		exit 1
	fi
	if [ ! -f $DEFPROFILE ]; then
		echo "Default profile '$DEFPROFILE' not found."
		screen -X quit >/dev/null
		exit 1
	fi
}

check_requirements()
{
	local tmpfile="/tmp/hwdisco.$$"

	if test $MIN_MEM_REQUIRED -gt $sysmem; then
		oneline_msgbox Error "Not enough physical memory for minimal installation: requires ${MIN_MEM_REQUIRED}M, found ${sysmem}M"
		return 1
	fi

	printlog "Detected Devices:
`$REPO/hwdisco -a`"

	if test "x$_KS_need_network" = x1; then
		ifconfig -a plumb >/dev/null 2>&1
		if ! ifconfig -a|grep flags=|nawk -F: '{print $1}'|egrep -v lo0 >/dev/null; then
			message_Yn_ask "\nNo network adapter or required networking driver found.\nEnsure that target has network adapter properly installed.\n\nFor third-party driver installation instructions press F2\nand type 'less /DRIVER-INSTALL.txt'\n\nAbort installation process?"
			test $? = $DIALOG_OK && return 1
		fi
	fi

	eval 'format 2>/dev/null <<_EOF\cD\n_EOF | egrep "[0-9]+\. c" >/dev/null'
	if test $? != 0; then
		message_Yn_ask "\nNo hard disk or required storage driver found.\nEnsure that hard disk is properly connected to a storage controller.\n\nFor third-party driver installation instructions press F2\nand type 'less /DRIVER-INSTALL.txt'\n\nAbort installation process?"
		test $? = $DIALOG_OK && return 1
	fi

	echo > $tmpfile
	$REPO/hwdisco >> $tmpfile
	local rc=$?

	if test $rc == 1; then
		printlog "Missing Drivers Information:
`cat $tmpfile`"
		if test "x$_KS_disable_missing_drivers_warning" = x1; then
			rm -f $tmpfile
			return 0
		fi
		echo >> $tmpfile
		echo "   Press 'Continue' if you'd like to continue installation" >> $tmpfile

		$DIALOG --title " Missing Drivers Information " --ok-label "Continue" \
		       --no-cancel --extra-button --extra-label "Terminate" \
		       --textbox $tmpfile 0 0
		rc=$?

		if test $rc == 3; then
			rm -f $tmpfile
			return 1
		fi
	fi

	rm -f $tmpfile
	return 0
}

show_license()
{
	local text_file=$1
	$DIALOG --title "Software License" --help-button --help-label 'Disagree' \
		--exit-label 'I Agree' --textbox "$text_file" 0 0
	local rc=$?
	test $rc == 0 && return 0
	return 1
}

extract_lic_file()
{
	local lic_text=$1
	lic_pkgname=$(echo "$lic_text"|awk -F: '{print $1}')
	lic_pkg=$(find $REPO -name "${lic_pkgname}_*.deb" 2>/dev/null)
	if test -f "$lic_pkg"; then
		dpkg -x "$lic_pkg" "/tmp/$lic_pkgname" 2>/dev/null
		lic_text=$(echo "$lic_text"|awk -F: '{print $2}')
	fi
	echo $lic_text
}

extract_lic_text()
{
	local lic_text=$1
	lic_pkgname=$(echo "$lic_text"|awk -F: '{print $1}')
	lic_pkg=$(find $REPO -name "${lic_pkgname}_*.deb" 2>/dev/null)
	if test -f "$lic_pkg"; then
		dpkg -x "$lic_pkg" "/tmp/$lic_pkgname" 2>/dev/null
		lic_file=$(echo "$lic_text"|awk -F: '{print $2}')
		if test -f "/tmp/$lic_pkgname$lic_file"; then
			cp "/tmp/$lic_pkgname$lic_file" / 2>/dev/null
			lic_text=/$(basename "/tmp/$lic_pkgname$lic_file" 2>/dev/null)
		fi
		rm -rf "/tmp/$lic_pkgname"
	fi
	echo $lic_text
}

create_swap()
{
	for sswap in `echo $slice_swap|sed -e "s/ /\n/g"`; do
		if boolean_check $_KS_autopart_use_swap_zvol; then
			local rawswap="/dev/zvol/dsk/$sswap";
			zfs create -V ${AUTOPART_SWAP_SIZE}m $sswap
			swap -a $rawswap 2>/dev/null 1>&2
		else
			swap -a $sswap 2>/dev/null 1>&2
		fi
	done
}

create_dump()
{
	if boolean_check $_KS_autopart_use_swap_zvol; then
		AUTOPART_DUMP_SIZE=$(calculate_dump_size)
		if test "x$AUTOPART_DUMP_SIZE" = "x"; then
			printlog "DUMP Device is not created: No free space on $ZFS_ROOTPOOL"
			rawdump=""
		else
			zfs create -V ${AUTOPART_DUMP_SIZE}m $ZFS_ROOTPOOL/$rawdump
			if [ $? -eq 0 ]; then
				printlog "DUMP Device was successfully created."
			else
				printlog "DUMP Device is not created"
				rawdump=""
			fi
		fi
	fi
}

calculate_dump_size()
{
	phys="$(echo $result_disk_pool | awk '{print $1}')"
	phys="/dev/rdsk/${phys}s0"
	size="$(fdisk -G $phys | tail -1 | awk '{print $1*$5*$6*$7}')"
	perl -e '
		my $syspool_size = $ARGV[0]/1024/1024;
		my $memsize = $ARGV[1];
		my $swap_size = $ARGV[2];
		my $dump_size = int($memsize * 0.7);
		if ($syspool_size - $dump_size - $swap_size - 1536 < int($syspool_size * 0.3)) {
			print "";
		} else {
			print "$dump_size";
		}
	' $size $sysmem $AUTOPART_SWAP_SIZE
}

activate_dump()
{
	if boolean_check $_KS_autopart_use_swap_zvol; then
		if test "x$_KS_hostname" != x; then
			savecore_dir="/var/crash/$_KS_hostname"
		else
			savecore_dir="/var/crash/myhost"
		fi
		mount -F lofs /devices $TMPDEST/devices
		mkdir -p $TMPDEST/$savecore_dir
		chmod 0700 $TMPDEST/$savecore_dir
		mkdir -p $TMPDEST/$ROOTPOOL_ZVOL_DIR
		local dump_link=`readlink $ROOTPOOL_ZVOL_DIR/$rawdump`
		cd $TMPDEST/$ROOTPOOL_ZVOL_DIR && ln -s $dump_link $rawdump && cd - 1>/dev/null 2>&1
		dumpadm -c curproc -d $ROOTPOOL_ZVOL_DIR/$rawdump -z on -r \
			$TMPDEST -s $savecore_dir -m 20% 1>/dev/null
		if [ $? -eq 0 ]; then
			printlog "Crash dump service was successfully activated."
			printlog "Dump device: $rawdump"
		else
			printlog "Crash dump service not activated."
		fi
	fi
}

extract_args()
{
	local request_prop=$1

	if test "x$PROFILE_STATUS" = "x"; then
		profile_name=$(get_auto_profile $PROFILE_DIR $PROFILE_BASE)
		if test "x$profile_name" = "x"; then
			PROFILE_STATUS="NOT_FOUND"
		else
			# Loading profile
			source $profile_name
			PROFILE_STATUS="LOADED"
		fi
	fi
	# First we try to get prop value from kernel line
	value=$(/usr/sbin/prtconf -v /devices|/usr/bin/sed -n "/$request_prop/{;n;p;}"|/usr/bin/sed -e "s/^\s*value=\|'//g")

	# Second we try to get prop value from profile
	# if it available and it not found at kernel line
	if test "x$value" = "x" -a "x$PROFILE_STATUS" = "xLOADED"; then
		value=$(deref_variable __PF_$request_prop)
	fi

	echo $value
}

deref_variable()
{
	eval var_name=\$$1
	echo $var_name
}

get_lun_by_device_id()
{
	perl -e '
		my $found;
        	for my $l (`/usr/nexenta/hddisco`) {
	        	if ($l =~ /^=(c\d+.*d\d+)/) {
	           		$found = $1;
	           		next;
			}
			if ($l =~ /^device_id\s+(\S+)/) {
		      		if ($1 =~ /\@$ARGV[0]$/) {
		      			print $found;
		      			last;
				}
			}
		}' $1
}

round_disk_size()
{
	perl -e '
		my $unrounded = $ARGV[0]/1024/1024/1024;
		my $rounded = sprintf("%.2f", $unrounded);
		print $rounded;
		' $1
}

compare_size()
{
	perl -e '
		if ($ARGV[1] <= ($ARGV[0] + 0.2) && $ARGV[1] >= ($ARGV[0] - 0.2)) {
			exit 0;
		}
		exit 1;
		' $1 $2
}

get_auto_profile()
{
	ifconfig -a | perl -e '
		for my $line (<STDIN>) {
			if ($line =~ m/ether\s+([0-9a-f:]+)/) {
				my @res = ();
				for my $field (split(/:/, $1)) {
					if (length $field == 1) {
						push @res, "0$field";
					} else {
						push @res, $field;
					}
				}
				my $mac = join("", @res);
				if (-f "$ARGV[0]/$ARGV[1].$mac") {
					print "$ARGV[0]/$ARGV[1].$mac";
					last;
				}
			}
		}
		' $1 $2
}

############# main ###############
check_components
dumpkeys | grep padenter | sed -e 's/numl /all /g' > $TMP_FILE
loadkeys $TMP_FILE

source $DEFPROFILE
if test -f ${EXTRADEB_PROFILE}; then
	source ${EXTRADEB_PROFILE}
fi
DEFAULT_PROFILE=${_KS_profile_name[$_KS_profile_selected]}
TITLE=$_KS_product_title
if test -f $REPO/machinesig; then
	devfsadm -c disk 2>/dev/null 1>&2
	rmformat 2>/dev/null 1>&2
	sync
	export MACHINESIG="`$REPO/machinesig`"
fi
DIALOG="$(dialog_cmd)"
DIALOG_WITH_ESC="$(dialog_cmd_with_escape)"

rm -f $TMP_FILE
ssh_enable=0
if test "x$(extract_args ssh_enable)" != x; then
	ssh_enable=1
	ssh_port="$(extract_args ssh_port)"
fi

svcadm disable network/ipsec/ipsecalgs > /dev/null 2>&1
svcadm disable network/ipsec/policy > /dev/null 2>&1
svcadm disable system/name-service-cache > /dev/null 2>&1
svcadm disable ssh > /dev/null 2>&1
if test "x$ssh_enable" != "x0"; then
	echo $ssh_port | egrep "^[0-9]+$" 2>/dev/null 1>&2
	if test $? -eq 0 -a $ssh_port -gt 1024; then
		egrep "^[[:space:]]*Port[[:space:]]+[0-9]+$" /etc/ssh/sshd_config 2>/dev/null 1>&2
		if test $? -eq 0; then
			sed -e "s/^\s*Port\s\+[0-9]\+/Port $ssh_port/" -i /etc/ssh/sshd_config
		else
			echo Port $ssh_port >> /etc/ssh/sshd_config
		fi
	fi
	svcadm enable -s ssh > /dev/null 2>&1
fi
sleep 5
svcadm disable system-log > /dev/null 2>&1
svcadm enable -s system-log > /dev/null 2>&1
svcadm enable datalink-management > /dev/null 2>&1
svcadm enable system/hal > /dev/null 2>&1
svcadm enable system/filesystem/rmvolmgr > /dev/null 2>&1

for i in `ls /tmp/dest.*/usr/nexenta 2>/dev/null`; do umount $i 2>/dev/null; done
for i in `ls /tmp/dest.* 2>/dev/null`; do umount $i 2>/dev/null; done

# ignore Ctrl-C
trap '' INT

if test "x${_KS_iface_ip[0]}" = xrandom; then
	ip3=$(getrand_10_200)
	sleep 2
	ip4=$(getrand_10_200)
	_KS_iface_ip[0]="192.168.$ip3.$ip4"
	_KS_iface_mask[0]="255.255.0.0"
fi

# Get parameters for full automatic installation
if test "x$(extract_args auto_install)" != x; then
	auto_install="1"
	_KS_auto_reboot="1"
	_KS_welcome_head="0"
	_KS_welcome_ks="0"
	_KS_gateway="$(extract_args gateway)"
	syspool_luns="$(extract_args syspool_luns)"
	syspool_spare="$(extract_args syspool_spare)"
	_KS_dns1="$(extract_args dns_ip_1)"
	_KS_dns2="$(extract_args dns_ip_2)"
	loghost="$(extract_args loghost)"
	logport="$(extract_args logport)"
fi

installcd=$(cat /.volid 2>/dev/null)

if test "x$installcd" = x -o "x$installcd" != "xNexenta_InstallCD"; then
	$DIALOG --title " Error " --msgbox "\nSorry, but you cannot execute $TITLE installer without first booting your system using the $TITLE InstallCD.\n\n
" 0 0
	aborted
fi

if [ $BOOT_ANYWHERE -ne 0 ]; then
	oneline_info "Boot Anywhere override is ON"
	sleep 2
fi

if [ $MEMSCRATCH -ne 0 ]; then
	oneline_info "Memory Scratch override is ON"
	sleep 2
fi

if test "x$_KS_min_mem_required" != x; then
	MIN_MEM_REQUIRED=$_KS_min_mem_required
fi

if ! check_requirements; then
	aborted
fi

if test "x$_KS_license_text" != x -a \
	"x$_KS_license_text" != x0 -a \
	"x$auto_install" = x; then
	lic_text="$REPO/$_KS_license_text"
	if ! test -f "$lic_text"; then
		lic_text=$(extract_lic_text $_KS_license_text)
	fi
	if test -f "$lic_text" && \
	   ! show_license "$lic_text"; then
		aborted
	fi
fi

if boolean_check $_KS_welcome_head; then
	welcome_head
fi

if test "x$_KS_welcome_ks" = x1; then
	welcome_ks
fi

if test "x$_KS_kbd_type" = x; then
	select_kbd
else
	SELECTED_KBD_TYPE=$_KS_kbd_type
fi

if test "x$SELECTED_KBD_TYPE" != x; then
	kbd -s $SELECTED_KBD_TYPE >/dev/null
	printlog "Keyboard layout is set to $SELECTED_KBD_TYPE"
fi

if test "x$_KS_time_zone" = x; then
	while true; do
		select_tz && break
	done
else
	apply_tz $_KS_time_zone
fi

while true; do
	cleanup_pre

	if boolean_check $_KS_detect_removable; then
		detect_removable
	fi

	if boolean_check $_KS_check_upgrade; then
		check_upgrade
	fi

	if [ $UPGRADE -eq 0 ]; then
		select_profile
		repeat=0
		while true; do
			RC=0
			if test "x$_KS_rootdisks" = x; then
				autopart_ask
				RC=$?
			else
				RC=3
			fi
			case $RC in
			0)
				echo $result_disk_pool >$DIALOG_RES
				test "x$(dialog_res)" = x && continue
				autodisk="$(dialog_res)"
				if test "x$auto_install" != "x1"; then
					message_Yn_ask "\nAre you absolutely sure that you want to repartition selected disk(s) '$autodisk $result_disk_spare'? This process will \\Z1*DESTROY*\\Zn any existing data on disk(s).\n\nPlease consult platform manual for guidance on selecting boot disks.\nContinue to automatic partitioning?\n"

				fi
				if test $? = $DIALOG_OK -o "x$auto_install" = "x1"; then
					ROOTDISK_TYPE=$_KS_rootdisk_type
					if test "x$ROOTDISK_TYPE" = x; then
						$DIALOG --yes-label ZFS --no-label UFS --title " Filesystem Type " --yesno "\nPlease select 'root' filesystem type..." 6 50
						if test $? == $DIALOG_OK; then
							ROOTDISK_TYPE="zfs"
						else
							ROOTDISK_TYPE="ufs"
						fi
					fi
					printlog "Selected '$ROOTDISK_TYPE' configuration."
					oneline_info "Auto partitioning '$autodisk' for '$ROOTDISK_TYPE' configuration..."
					if test "x$ROOTDISK_TYPE" = xufs; then
						find_zpool_by_disk_and_destroy $autodisk || continue
						if ! autopart $autodisk "ufs"; then
							format_drive $autodisk || continue
						fi
					else
						stop_requested=0
						for d in `echo $autodisk|sed -e "s/ /\n/g"`; do
							if ! find_zpool_by_disk_and_destroy $d; then
								stop_requested=1
								break
							fi
						done
						test $stop_requested == 1 && continue
						for d in `echo $autodisk|sed -e "s/ /\n/g"`; do
							autopart $d "zfs"
						done
						pool_type="pool"
						if  echo "$(dialog_res)" | grep " " >/dev/null; then
							# always # assume mirror configuration if 2+ disks selected.
							pool_type="mirror"
						fi
						autopart_zfs "$autodisk" $pool_type "$result_disk_spare" || continue
					fi
				else
					continue
				fi
				;;
			1)
				test "x$(dialog_res)" = x && continue
				autodisk="$(dialog_res)"
				$DIALOG --yes-label ZFS --no-label UFS --title " Filesystem Type " --yesno "\nPlease select 'root' filesystem type..." 6 50
				if test $? == $DIALOG_OK; then
					ROOTDISK_TYPE="zfs"
				else
					ROOTDISK_TYPE="ufs"
				fi
				printlog "Selected '$ROOTDISK_TYPE' configuration."
				find_zpool_by_disk_and_destroy $autodisk || continue
				format_drive $autodisk || continue
				if test $ROOTDISK_TYPE = "zfs"; then
					autopart_zfs $autodisk "pool" || continue
				fi
				;;
			2)
				repeat=1 && break
				;;
			3)
				test "x$(dialog_res)" = x && continue
				autodisk="$(dialog_res)"
				$DIALOG --yes-label ZFS --no-label UFS --title " Filesystem Type " --yesno "\nPlease select 'root' filesystem type..." 6 50
				if test $? == $DIALOG_OK; then
					ROOTDISK_TYPE="zfs"
				else
					ROOTDISK_TYPE="ufs"
				fi
				printlog "Selected '$ROOTDISK_TYPE' configuration."
				find_zpool_by_disk_and_destroy $autodisk || continue
				part_manual $autodisk || continue
				if test $ROOTDISK_TYPE = "zfs"; then
					autopart_zfs $autodisk "pool" || continue
				fi
				;;
			esac
			apply_profile
			create_swap
			create_dump
			install_base
			if test "x$_KS_msig_setup_enable" != "x"; then
				msig_setup
			fi
			customize_hdd_install
			break
		done
		test $repeat = 1 && continue
	else
		create_swap
		upgrade_drive || continue
		apply_profile
		upgrade_base
		customize_hdd_upgrade
	fi
	break
done

customize_X

oneline_info "Preparing System Services..."
configure_repository

install_grub

if test "x$slice_export_home" != x; then
	zfs set mountpoint=/export/home $ZPOOL_HOME
	mkdir -p $TMPDEST/etc/zfs
	cp /etc/zfs/zpool.cache $TMPDEST/etc/zfs
	printlog "Slice $slice_export_home enabled to use ZFS and mountpoint set to /export/home"
fi

if test "x$rawdump" != x; then
	oneline_info "Activating crash dump service..."
	activate_dump
fi

printlog "Saving log file ..."
cp $LOGFILE $TMPDEST/root

if [ $UPGRADE -eq 0 ]; then
	# Trigger first time startup wizard if specified via Kick-Start profile
	if test "x$_KS_startup_wizard" != x; then
		wizard_env="NIC_PRIMARY="
		test "x$auto_install" = "x1" && wizard_env="NIC_PRIMARY=$(extract_args nic_primary)"
		test "x$auto_install" = "x1" && remote_log="echo 'PXE-INST-SUCCESS' | /usr/bin/remote-logger --host=$loghost --port=$logport;"
		chmod 755 $TMPDEST/usr/bin/$_KS_startup_wizard
		echo "$remote_log $wizard_env /usr/bin/screen -q -T xterm -s /usr/bin/$_KS_startup_wizard" > $TMPDEST/$FIRSTSTART
		if test "x$_KS_show_wizard_license" = x1; then
			if test -f "$REPO/$_KS_license_text"; then
				cp $REPO/$_KS_license_text $TMPDEST/etc/license_text
				chmod 644 $TMPDEST/etc/license_text
			fi
			echo $(extract_lic_file $_KS_license_text) > $TMPDEST/$LICENSELOC
		fi
		printlog "First time startup wizard '/usr/bin/$_KS_startup_wizard' enabled."
		if test "x$_KS_model" != x; then
			cp $REPO/$_KS_model $TMPDEST/usr/lib/perl5/NZA
		fi
	fi
	if test "x$auto_install" = "x1"; then
		touch $TMPDEST/.pxe-provisioned
		cp -a /usr/nexenta/remote-logger $TMPDEST/usr/bin/
		nlm_key="$(extract_args nlm_key | sed -e 's/_/-/g')";
		if test "x$nlm_key" != x; then
			test -d "$TMPDEST/var/lib/nza" && mkdir -p $TMPDEST/var/lib/nza
			touch $TMPDEST/var/lib/nza/nlm.key
	       		echo $nlm_key > $TMPDEST/var/lib/nza/nlm.key
		fi
	fi
fi

if test -d ${EXTRADEBDIR}; then
	process_extradebs
fi

drvjobs=/.drv-queue
if test -d $drvjobs; then
	printlog "Processing driver/package installation jobs ..."
	test -d $drvjobs/kernel && cp -ar $drvjobs/kernel $TMPDEST
	test -d $drvjobs/var && cp -ar $drvjobs/var $TMPDEST
	if test -f $drvjobs/queue; then
		cp -f $drvjobs/queue $TMPDEST/var/tmp/queue.sh
		chmod 755 $TMPDEST/var/tmp/queue.sh
		chrootenv="/usr/bin/env -i PATH=/sbin:/bin:/usr/sbin:$PATH LOGNAME=root HOME=/root TERM=xterm"
		chroot $TMPDEST $chrootenv /usr/sbin/mount /proc
		chroot $TMPDEST $chrootenv /var/tmp/queue.sh
		chroot $TMPDEST $chrootenv /usr/sbin/umount /proc 2>/dev/null
	fi
fi

oneline_info "Updating Boot Archive..."
update_boot_archive

test -f $REPO/machinesig && $REPO/machinesig

if [ $UPGRADE -eq 0 ]; then
	if test $ROOTDISK_TYPE = "zfs"; then
		zfs snapshot $ZFS_ROOTFS@initial 2>/dev/null
	fi
fi

oneline_info "Cleaning up..."
cleanup_after_install

if [ $UPGRADE -eq 0 ]; then
	if [ "${RM_DISK}" != "" ]; then
		oneline_msgbox_slim Information "\nYou have installed $TITLE on a removable drive. Please make sure to modify your machine's BIOS setting(s) accordingly, such that the corresponding drive is listed first in the boot order list.\n"
	fi
	printlog "Installation complete. Exiting."
	reboot_exit "$TITLE installation is complete."
else
	oneline_msgbox_slim Information "\nYour base $TITLE packages have been upgraded. In order to upgrade the rest of the packages, please make sure to synchronize the APT repository by performing apt-get dist-upgrade (or by running Synaptic package manager) after you reboot.\n"
	printlog "Upgrade complete. Exiting."
	reboot_exit "\n$TITLE upgrade is complete.\n\nCheck `echo "$UPGRADE_LOG" | sed -e "s:$TMPDEST::"` before reboot!\n"
fi
