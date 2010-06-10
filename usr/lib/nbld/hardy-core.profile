#
# Nexenta Core Platform 3.x Profile
#

#
# REQ_DEBS
#
#
REQ_DEBS="pciutils nexenta-keyring zlib1g libnspr4-0d libnss3-1d gnupg sunwpiclr \
	sunwdtrc sunwdtrp sunwrcmdc nexenta-sunw pkg-config libkrb53 libstdc++6-4.2-dev"

#
# MINIMAL_CMN_DEBS
#
#
MINIMAL_CMN_DEBS="vim sunwsshu sunwsshdu bzip2 mkisofs sudo sed sunwcsu"

#
# STAGE0_DEBS - the content of InstallCD miniroot
#               (generally speaking, this is Installer requirements)
#
STAGE0_DEBS="screen dialog debootstrap wget sunwsshu sunwsshdu sunwesu \
	     file cpio genisoimage"

#
# STAGE0_EXCLUDE_DEBS -
#
#
STAGE0_EXCLUDE_DEBS="alien sunwmpsvplr sunwmpathadm python nexenta-pkgcmd dpkg-dev debhelper tasksel tasksel-data libhal-dev libhal-storage-dev python2.5  myamanet-rf aptitude sunwdtrc info manpages sunwrcmdc sunwfmd sunwpkgcmdsu sunwdtrp libssl0.9.7 man-db nano sunwsmbsu sunwsmbsr sunwsmbskr patch sunwdrmr sunwdsdr sunwdsdu sunwiscsir sunwiscsiu sunwima sunwimac sunwimacr sunwimar sunwmpapi sunwmpapir sunwmdb sunwmdbr sunwxwdv sunwtnetd sunwhea sunwiir sunwiiu sunwrdcr sunwrdcu sunwscmr sunwscmu sunwspsvr sunwspsvu sunwdtrc sunwpowertop"

#
# LOCAL_ARCHIVE_DEBS - the content of on-ISO APT repository
#                      (what will be installed by default)
#
LOCAL_ARCHIVE_DEBS=" \
    screen dialog file cpio tree bzip2 sudo vim genisoimage \
    gcc g++ util-linux libpq5 getopt python2.4\
    lib64stdc++6 \
    alien nexenta-pkgcmd \
    dput devscripts \
    sunwscpu \
    sunwsprot \
    sunwgssdh sunwspnego \
    sunwntpu sunwntpr \
    sunwftpu sunwftpr sunwtftp sunwtftpr \
    sunwnisr sunwnisu \
    sunwisnsr \
    sunwsshu sunwsshdu sunwesu sunwtoo \
    sunwiir sunwiiu sunwrdcr sunwrdcu sunwscmr sunwscmu sunwspsvr sunwspsvu \
    sunwsmbfsu"

#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
product_title="NexentaCore"
os_version="v3.0"
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
ks_autopart_use_swap_zvol="1"
mode_type="install"
