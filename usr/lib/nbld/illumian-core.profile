#
# illumian 1.0 Profile
#

#
# REQ_DEBS
#
REQ_DEBS="\
sunwcs \
sunwcsd \
file-gnu-coreutils \
system-kernel \
system-kernel-cpu-counters \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-power \
system-kernel-platform \
system-kernel-power \
system-kernel-secure-rpc \
system-kernel-security-gss \
system-kernel-suspend-resume \
compress-bzip2 \
compress-gzip \
crypto-ca-certificates \
database-sqlite-3 \
editor-vim \
install-beadm \
library-libffi \
library-libidn \
library-libtecla \
library-libxml2 \
library-ncurses \
library-nspr \
library-readline \
library-security-trousers \
library-zlib \
naming-ldap \
network-bridging \
network-ftp \
network-ssh \
network-ssh-ssh-key \
print-lp-print-client-commands \
release-name \
runtime-python-26 \
runtime-tcl-8 \
runtime-tk-8 \
service-fault-management \
service-file-system-smb \
service-network-dns-mdns \
service-network-network-clients \
service-network-ssh \
service-picl \
service-resource-pools \
service-security-gss \
service-security-kerberos-5 \
shell-bash \
system-boot-wanboot \
system-data-keyboard-keytables \
system-extended-system-utilities \
system-file-system-autofs \
system-file-system-nfs \
system-file-system-smb \
system-file-system-zfs \
system-kernel-secure-rpc \
system-library \
system-library-c++-sunpro \
system-library-iconv-utf-8 \
system-library-libdiskmgt \
system-library-math \
system-library-mozilla-nss \
system-library-security-gss \
system-library-security-gss-diffie-hellman \
system-library-security-gss-spnego \
system-library-security-libgcrypt \
system-library-security-libsasl \
system-library-storage-scsi-plugins \
system-network \
system-network-routing \
system-xopen-xcu4 \
system-zones \
text-doctools \
text-groff \
text-less \
text-locale \
text-texinfo \
\
system-boot-grub \
system-boot-real-mode \
system-data-hardware-registry \
media-cdrtools \
text-gnu-sed \
text-gnu-grep \
text-gawk \
archiver-gnu-tar \
system-library-gcc-44-runtime \
package-dpkg \
icore-keyring \
crypto-gnupg \
package-dpkg-apt \
library-security-libassuan \
terminal-dialog \
terminal-screen \
\
runtime-perl-510-extra \
runtime-perl-512 \
library-perl-5-sun-solaris \
"

#
# MINIMAL_CMN_DEBS
#
#
MINIMAL_CMN_DEBS="\
sunwcsd \
sunwcs \
system-library \
system-kernel \
system-kernel-platform \
package-dpkg-apt \
package-dpkg \
"

#
# STAGE0_DEBS - the content of InstallCD miniroot
#               (generally speaking, this is Installer requirements)
#
STAGE0_DEBS=""

#
# CD stage
#
STAGE0_CD="\
developer-debug-mdb \
developer-debug-mdb-module-module-qlc \
developer-dtrace \
developer-linker \
driver-network-platform \
library-libtecla \
library-security-trousers \
network-ftp \
network-ssh \
network-ssh-ssh-key \
service-hal \
service-fault-management \
service-network-dns-mdns \
service-network-network-clients \
service-network-ssh \
service-resource-pools \
system-boot-grub \
system-boot-real-mode \
system-data-hardware-registry \
system-file-system-zfs \
system-kernel \
system-kernel-cpu-counters \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-platform \
system-kernel-power \
system-kernel-secure-rpc \
system-kernel-security-gss \
system-kernel-suspend-resume \
system-library-libdiskmgt \
system-library-platform \
system-library-policykit \
system-library-processor \
system-library-math \
system-library-security-libgcrypt \
system-network \
system-network-routing \
system-scheduler-fss \
service-storage-avs-cache-management \
storage-svm \
system-library-iconv-utf-8 \
media-cdrtools \
install-beadm \
text-less \
editor-vim \
web-wget \
compress-bzip2 \
compress-gzip \
text-locale \
archiver-gnu-tar \
"

#
# CD stage
#
STAGE0_CD_END="\
text-gnu-grep \
text-gnu-sed \
file-gnu-findutils \
file-gnu-coreutils \
terminal-dialog \
terminal-screen \
hddisco \
mdisco \
shell-expect \
service-file-system-nfs \
system-file-system-nfs \
"


#
# STAGE0_APTINST
#
STAGE0_APTINST="$STAGE0_CD \
naming-ldap \
network-bridging \
network-ipfilter \
network-iscsi-initiator \
network-iscsi-iser \
network-iscsi-target \
network-netcat \
network-telnet \
service-fault-management-smtp-notify \
service-fault-management-snmp-notify \
service-file-system-nfs \
service-file-system-smb \
service-network-dhcp \
service-network-dhcp-datastore-binfiles \
service-network-ftp \
service-network-legacy \
service-network-load-balancer-ilb \
service-network-network-servers \
service-network-nis \
service-network-slp \
service-network-smtp-sendmail \
service-network-telnet \
service-network-tftp \
service-network-uucp \
service-network-wpa \
service-picl \
service-resource-cap \
service-resource-pools-poold \
service-security-gss \
service-security-kerberos-5 \
service-storage-fibre-channel-fc-fabric \
service-storage-isns \
service-storage-media-volume-manager \
service-storage-ndmp \
service-storage-removable-media \
service-storage-virus-scan \
storage-avs-point-in-time-copy \
storage-avs-remote-mirror \
storage-metassist \
storage-mpathadm \
storage-stmf \
system-accounting-legacy \
system-boot-network \
system-boot-wanboot \
system-boot-wanboot-internal \
system-data-keyboard-keytables \
system-data-terminfo \
system-dtrace-tests \
system-extended-system-utilities \
system-fault-management-eversholt-utilities \
system-file-system-autofs \
system-file-system-nfs \
system-file-system-ntfsprogs \
system-file-system-smb \
system-file-system-udfs \
system-file-system-zfs-tests \
system-flash-fwflash \
system-fru-id \
system-fru-id-platform \
system-io-tests \
system-ipc \
system-kernel-dtrace-providers \
system-kernel-dtrace-providers-xdt \
system-kernel-rsmops \
system-library-install-libinstzones \
system-library-libfcoe \
system-library-security-gss \
system-library-security-gss-diffie-hellman \
system-library-security-gss-spnego \
system-library-security-libsasl \
system-library-security-rpcsec \
system-library-storage-fibre-channel-libsun-fc \
system-library-storage-ima \
system-library-storage-ima-header-ima \
system-library-storage-libmpscsi-vhci \
system-library-storage-scsi-plugins \
system-library-svm-rcm \
system-management-intel-amt \
system-management-pcitool \
system-management-snmp-sea-sea-config \
system-management-wbem-data-management \
system-network-http-cache-accelerator \
system-network-ipqos \
system-network-ipqos-ipqos-config \
system-network-nis \
system-network-ppp \
system-network-ppp-pppdump \
system-network-ppp-tunnel \
system-network-routing-vrrp \
system-network-spdadm \
system-network-udapl \
system-network-udapl-udapl-tavor \
system-network-wificonfig \
system-remote-shared-memory \
system-security-kerberos-5 \
system-storage-fibre-channel-port-utility \
system-storage-luxadm \
system-storage-parted \
system-storage-sasinfo \
system-tnf \
system-xopen-xcu4 \
system-xopen-xcu6 \
system-xvm-ipagent \
system-zones \
system-zones-brand-s10 \
system-zones-brand-sn1 \
system-zones-internal \
"

STAGE0_APTINST_OLD=" \
"

#
# LOCALES
#
LOCALES="\
locale-af \
locale-ar \
locale-as \
locale-az \
locale-be \
locale-bg \
locale-bg-extra \
locale-bn \
locale-bo \
locale-bs \
locale-ca \
locale-ca-extra \
locale-cs \
locale-cs-extra \
locale-da \
locale-da-extra \
locale-de \
locale-de-extra \
locale-el \
locale-el-extra \
locale-en \
locale-en-extra \
locale-es \
locale-es-extra \
locale-et \
locale-fi \
locale-fi-extra \
locale-fil \
locale-fr \
locale-fr-extra \
locale-ga \
locale-gu \
locale-he \
locale-hi \
locale-hr \
locale-hr-extra \
locale-hu \
locale-hu-extra \
locale-hy \
locale-id \
locale-ii \
locale-is \
locale-is-extra \
locale-it \
locale-it-extra \
locale-ja \
locale-ka \
locale-kk \
locale-km \
locale-kn \
locale-ko \
locale-kok \
locale-lt \
locale-lt-extra \
locale-lv \
locale-lv-extra \
locale-mk \
locale-mk-extra \
locale-ml \
locale-mn \
locale-mr \
locale-ms \
locale-mt \
locale-nb \
locale-ne \
locale-nl \
locale-nl-extra \
locale-nn \
locale-or \
locale-pa \
locale-pl \
locale-pl-extra \
locale-pt \
locale-pt-extra \
locale-ro \
locale-ru \
locale-ru-extra \
locale-sa \
locale-si \
locale-sk \
locale-sl \
locale-sq \
locale-sq-extra \
locale-sr \
locale-sv \
locale-sv-extra \
locale-ta \
locale-te \
locale-th \
locale-th-extra \
locale-tr \
locale-tr-extra \
locale-ug \
locale-uk \
locale-ur \
locale-vi \
locale-zh-cn \
locale-zh-hk \
locale-zh-mo \
locale-zh-sg \
locale-zh-tw \
"

#
# STAGE0_HDD_END
#
#
STAGE0_HDD_END="\
service-network-ntp \
system-library-dbus \
library-nspr \
security-sudo \
package-svr4 \
library-perl-5-sun-solaris \
file-gnu-findutils \
$LOCALES
"

#
# STAGE0_DRIVERS -
#
#
STAGE0_DRIVERS="\
driver-audio-audio810 \
driver-audio-audiocmi \
driver-audio-audioemu10k \
driver-audio-audiohd \
driver-audio-audioixp \
driver-audio-audiols \
driver-audio-audiop16x \
driver-audio-audiosolo \
driver-audio-audiovia823x \
driver-audio-audiovia97 \
driver-audio \
driver-crypto-dca \
driver-crypto-dprov \
driver-crypto-tpm \
driver-firewire \
driver-graphics-agpgart \
driver-graphics-atiatom \
driver-graphics-av1394 \
driver-graphics-dcam1394-devfsadm-dcam1394 \
driver-graphics-dcam1394 \
driver-graphics-drm \
driver-graphics-usbvc \
driver-i86pc-fipe \
driver-i86pc-ioat \
driver-i86pc-platform \
driver-network-afe \
driver-network-amd8111s \
driver-network-arn \
driver-network-atge \
driver-network-ath \
driver-network-atu \
driver-network-bfe \
driver-network-bge \
driver-network-bnx \
driver-network-bnxe \
driver-network-bpf \
driver-network-chxge \
driver-network-dmfe \
driver-network-e1000g \
driver-network-efe \
driver-network-elxl \
driver-network-emlxs \
driver-network-fcip \
driver-network-fcoe \
driver-network-fcoei \
driver-network-fcoet \
driver-network-fcp \
driver-network-fcsm \
driver-network-fp \
driver-network-hermon \
driver-network-hme \
driver-network-hxge \
driver-network-ib \
driver-network-ibdma \
driver-network-ibp \
driver-network-igb \
driver-network-iprb \
driver-network-ipw \
driver-network-iwh \
driver-network-iwi \
driver-network-iwk \
driver-network-iwp \
driver-network-ixgb \
driver-network-ixgbe \
driver-network-mwl \
driver-network-mxfe \
driver-network-myri10ge \
driver-network-nge \
driver-network-ntxn \
driver-network-nxge \
driver-network-ofk \
driver-network-pcan \
driver-network-pcwl \
driver-network-platform \
driver-network-qlc \
driver-network-ral \
driver-network-rds \
driver-network-rdsv3 \
driver-network-rge \
driver-network-rpcib \
driver-network-rtls \
driver-network-rtw \
driver-network-rum \
driver-network-rwd \
driver-network-rwn \
driver-network-sdp \
driver-network-sdpib \
driver-network-sfe \
driver-network-srpt \
driver-network-tavor \
driver-network-uath \
driver-network-ural \
driver-network-urtw \
driver-network-usbecm \
driver-network-vr \
driver-network-wpi \
driver-network-xge \
driver-network-yge \
driver-network-zyd \
driver-pcmcia \
driver-serial-pcser \
driver-serial-usbftdi \
driver-serial-usbsacm \
driver-serial-usbser-edge \
driver-serial-usbser \
driver-serial-usbsksp-usbs49-fw \
driver-serial-usbsksp \
driver-serial-usbsprl \
driver-storage-aac \
driver-storage-adpu320 \
driver-storage-ahci \
driver-storage-amr \
driver-storage-arcmsr \
driver-storage-ata \
driver-storage-bcm-sata \
driver-storage-blkdev \
driver-storage-cpqary3 \
driver-storage-glm \
driver-storage-lsimega \
driver-storage-marvell88sx \
driver-storage-mega-sas \
driver-storage-mpt-sas \
driver-storage-mr-sas \
driver-storage-nv-sata \
driver-storage-pcata \
driver-storage-pmcs \
driver-storage-sbp2 \
driver-storage-scsa1394 \
driver-storage-sdcard \
driver-storage-ses \
driver-storage-si3124 \
driver-storage-smp \
driver-storage-sv \
driver-usb-ugen \
driver-usb \
driver-x11-winlock \
driver-x11-xsvc \
driver-xvm-pv \
"

#
# STAGE0_EXCLUDE_DEBS -
#
#
STAGE0_EXCLUDE_DEBS=""

#
# LOCAL_ARCHIVE_DEBS - the content of on-ISO APT repository
#                      (what will be installed by default)
#
LOCAL_ARCHIVE_DEBS=""



#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
company_title="Nexenta"
product_title="illumian"
os_version="v1.0"
sw_version="1.0a5"
sw_description="(based on illumos)"
rootsize1="1024"
profile1="illumian-core"
lines1="3000"
desc1="Standard iCore installation profile"
longdesc1=""
profiles="1"
release_file="core-release.txt"
apt_sources="http://apt.illumian.org/illumian illumian-unstable main contrib non-free"
ks_min_mem_required="256"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
ks_autopart_use_swap_zvol="1"
mode_type="install"
