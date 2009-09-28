#
# Nexenta Core Platform 1.x Profile
#

#
# STAGE0_DEBS - the content of InstallCD miniroot
#               (generally speaking, this is Installer requirements)
#
STAGE0_DEBS="screen dialog debootstrap wget sunwsshu sunwsshdu sunwesu \
    file cpio"

#
# LOCAL_ARCHIVE_DEBS - the content of on-ISO APT repository
#                      (what will be installed by default)
#
LOCAL_ARCHIVE_DEBS=" \
    screen dialog vim file cpio tree bzip2 sudo \
    gcc g++ \
    alien nexenta-pkgcmd \
    dput devscripts \
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
rootsize1="1024"
profile1="elatte-core"
lines1="3000"
desc1="Standard Core installation profile"
longdesc1=""
profiles="1"
dot_screenrc="hardy-dot-screenrc"
release_file="core-release.txt"
apt_sources="http://apt.nexenta.org elatte-stable main contrib non-free"
ks_min_mem_required="256"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_auto_reboot="0"
ks_use_grub_mbr="1"
mode_type="install"
