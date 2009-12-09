#
# Nexenta Core Platform 2.x Profile
#

#
# STAGE0_DEBS - the content of InstallCD miniroot
#               (generally speaking, this is Installer requirements)
#
STAGE0_DEBS="screen dialog debootstrap wget sunwsshu sunwsshdu sunwesu \
    file cpio genisoimage"

#
# LOCAL_ARCHIVE_DEBS - the content of on-ISO APT repository
#                      (what will be installed by default)
#
LOCAL_ARCHIVE_DEBS=" \
    screen dialog file cpio tree bzip2 sudo vim genisoimage \
    gcc g++ util-linux libpq5 getopt\
    alien nexenta-pkgcmd \
    dput devscripts devzone\
    sunwscpu \
    sunwsprot \
    sunwgssdh sunwspnego \
    sunwntpu sunwntpr \
    sunwftpu sunwftpr sunwtftp sunwtftpr \
    sunwnisr sunwnisu \
    sunwiscsitgtr sunwiscsitgtu sunwisnsr \
    sunwsshu sunwsshdu sunwesu sunwtoo \
    sunwiir sunwiiu sunwrdcr sunwrdcu sunwscmr sunwscmu sunwspsvr sunwspsvu \
    sunwsmbfsu"

#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
product_title="NexentaCore"
os_version="v.3.0"
rootsize1="1024"
profile1="hardy-core"
lines1="3000"
desc1="Standard Core installation profile"
longdesc1=""
profiles="1"
release_file="core-release.txt"
apt_sources="http://apt.nexenta.org hardy-unstable main contrib non-free"
ks_min_mem_required="256"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
mode_type="install"
