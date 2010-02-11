#
# NexentaStor 3.x Profile (ZFS Storage Appliance)
#

#
# REQ_DEBS
#
#
REQ_DEBS="pciutils nexenta-keyring zlib1g gnupg sunwpiclr sunwdtrc sunwdtrp sunwrcmdc nexenta-sunw"

#
# MINIMAL_CMN_DEBS
#
#
MINIMAL_CMN_DEBS="vim sunwsshu sunwsshdu bzip2 mkisofs sudo"

#
# STAGE0_EXCLUDE_DEBS
#
#
STAGE0_EXCLUDE_DEBS="alien sunwmpsvplr sunwmpathadm python nexenta-pkgcmd dpkg-dev debhelper libdb4.2 tasksel tasksel-data libhal-dev libhal-storage-dev libsigc++-1.2-dev python2.5 sunwmmsr sunwmmsu myamanet-rf aptitude sunwdtrc info manpages sunwrcmdc sunwfmd sunwpkgcmdsu sunwdtrp libssl0.9.7 man-db nano sunwsmbsu sunwsmbsr sunwsmbskr patch sunwdrmr sunwdsdr sunwdsdu sunwiscsir sunwiscsiu sunwima sunwimac sunwimacr sunwimar sunwmpapi sunwmpapir sunwmdb sunwmdbr sunwxwdv sunwtnetd sunwhea sunwiir sunwiiu sunwrdcr sunwrdcu sunwscmr sunwscmu sunwspsvr sunwspsvu sunwdtrc"

#
# STAGE0_DEBS - the content of InstallCD miniroot
#               (generally speaking, this is Installer requirements)
#
STAGE0_DEBS="screen dialog debootstrap wget sunwsshu sunwsshdu sunwesu sunwixgbe \
	     file cpio genisoimage sed sunwcsu"

#
# LOCAL_ARCHIVE_DEBS - the content of on-ISO APT repository
#                      (what will be installed by default)
#
LOCAL_ARCHIVE_DEBS=" \
		screen dialog vim file cpio tree bzip2 joe unzip genisoimage \
		nmc nms nms-dev nmv nmv-theme-nexenta \
		alien nexenta-pkgcmd sunwlibc \
		sunwndmpu sunwndmpr ndmpcopy \
		sunwsmbfsu \
		sunwstmf \
		sunwscpu \
		sunwixgbe sunwixgb \
		sunwgssdh sunwspnego \
		sunwntpu sunwntpr \
		sunwftpu sunwftpr sunwtftp sunwtftpr \
		sunwnisr sunwnisu \
		sunwisnsr sunwisnsadm \
		sunwsshu sunwsshdu sunwesu sunwtoo \
		rsync mtx snmpd rcs star \
		samba samba-common winbind smbclient"
#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
product_title="NexentaStor"
model_id="STOR_UNIFIED"
model_name="ZFS Storage Appliance"
os_version="v3.0"
sw_version="v3.0.0"
grub_n_title="NexentaStor Appliance"
grub_s_title="NexentaStor Appliance"
rootsize1="1024"
profile1="appliance"
lines1="3200"
desc1="NexentaStor Appliance installation profile"
longdesc1=""
profiles="1"
dot_screenrc="nza-dot-screenrc"
release_file="nza-release.txt"
apt_sources="http://apt.nexentastor.org hardy-testing main contrib non-free"
plugin_sources=
builtin_plugins_dir="$extra_dir/extradebs"
builtin_plugins="nlm-eval nms-delorean nmc-delorean"
ks_min_mem_required="512"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
ks_license_text="nlm-eval:/etc/license_text.iso"
ks_welcome_head="1"
ks_welcome_ks="0"
ks_check_upgrade="0"
ks_scripts="nza-ks-scripts"
ks_detect_removable="0"
ks_root_passwd="nexenta"
ks_user_name="admin"
ks_user_passwd="nexenta"
ks_hostname="myhost"
ks_domainname="mydomain"
ks_iface_ip0="192.168.1.111"
ks_iface_mask0="255.255.255.0"
ks_ifaces="0"
ks_need_network="1"
ks_autopart_use_swap_zvol="1"
ks_autopart_export_home="0"
ks_gateway="0"
ks_dns1="0"
ks_dns2="0"
ks_use_dhcp="0"
ks_use_ipv6="0"
ks_time_zone="US/Pacific"
ks_kbd_type="US-English"
ks_startup_wizard="nza-wizard.nmc"
ks_machinesig="machinesig-nza3"
ks_show_wizard_license="1"
mode_type="install"
