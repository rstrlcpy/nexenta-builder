#
# NexentaStor 3.x Profile (Virtual Storage Appliance)
#

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
		nmc nlm-eval nms nms-dev nmv nmv-theme-nexenta \
		alien nexenta-pkgcmd sunwlibc lib64z1-dev \
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
		samba samba-common winbind smbclient \
		vmware-tools"
#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
product_title="NexentaStor"
model_id="STOR_VIRTUAL"
model_name="Virtual Storage Appliance"
os_version="v3.0"
sw_version="software v3.0.0"
grub_n_title="Nexenta Storage Appliance"
grub_s_title="Nexenta Storage Appliance"
rootsize1="1024"
profile1="hardy-nza"
lines1="3200"
desc1="Unified Storage Appliance installation profile"
longdesc1=""
profiles="1"
dot_screenrc="nza-dot-screenrc"
release_file="nza-release.txt"
apt_sources="http://apt.nexentastor.org hardy-testing main contrib non-free"
ks_min_mem_required="512"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
ks_license_text="nlm-eval:/etc/license_text.vm"
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
ks_show_wizard_license="1"
mode_type="install"
