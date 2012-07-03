#
# NexentaStor 4.x Profile (Open Storage Appliance)
#

#
# REQ_DEBS
#
REQ_DEBS="\
    sunwcsd \
    system-data-keyboard-keytables \
    system-extended-system-utilities \
    system-library-iconv-utf-8 \
    system-data-terminfo \
    libssl0.9.8 \
    libxml2 \
    system-library-math \
    sunwcs \
    service-fault-management \
    system-library-storage-scsi-plugins \
    system-library \
    sensible-utils \
    text-locale \
    bash \
    debianutils \
    release-name \
    nexenta-ldconfig \
    libidn11 \
    wget \
    binutils \
    debootstrap \
    libgcc1 \
    lib64gcc1 \
    libstdc++6 \
    lib64stdc++6 \
    liblzma2 \
    xz-utils \
    coreutils \
    package-svr4 \
    package-dpkg \
    libncurses5 \
    gzip \
    sed \
    grep \
    tar \
    mawk \
    install-info \
    libusb \
    libgcrypt11 \
    libgpg-error0 \
    libksba8 \
    libpth20 \
    libldap-2.4-2 \
    gpgv \
    gnupg \
    debian-archive-keyring \
    nexenta-keyring \
    package-dpkg-apt \
    gettext-base \
    perl-base \
    perl-modules \
    perl \
    debconf-i18n \
    debconf \
    liblocale-gettext-perl \
    libtext-iconv-perl \
    libtext-wrapi18n-perl \
    libtext-charwidth-perl \
    dialog \
    libdb4.6 \
    libdb4.8 \
    system-library \
    sysv-rc \
    sysvinit \
    libbz2-1.0 \
    lib64z1 \
    zlib1g \
    ntp \
    python2.6 \
    python2.6-minimal \
    libpython2.6 \
    "
#    nmv-meta"

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
STAGE0_CD="
system-kernel \
system-kernel-platform \
\
libtspi1 \
service-network-ssh \
network-ssh \
network-ssh-ssh-key \
network-ftp \
driver-network-platform \
\
system-boot-grub \
system-boot-real-mode \
system-data-hardware-registry \
system-file-system-nfs \
system-file-system-smb \
system-file-system-zfs \
system-header \
system-ipc \
system-management-intel-amt \
system-network \
system-network-spdadm \
system-scheduler-fss \
system-storage-fibre-channel-port-utility \
system-storage-luxadm \
system-storage-sasinfo \
system-trusted \
system-trusted-global-zone \
\
service-file-system-nfs \
service-file-system-smb \
service-hal \
service-network-dns-mdns \
service-network-load-balancer-ilb \
service-resource-pools \
service-storage-avs-cache-management \
service-storage-fibre-channel-fc-fabric \
\
service-storage-removable-media \
\
system-library-libdiskmgt \
system-library-libfcoe \
system-library-platform \
system-library-policykit \
system-library-processor \
system-library-security-gss \
system-library-security-libsasl \
system-library-storage-fibre-channel-hbaapi \
system-library-storage-fibre-channel-libsun-fc \
system-library-storage-ima \
system-library-storage-ima-header-ima \
system-library-storage-libmpapi \
system-library-storage-libmpscsi-vhci \
\
storage-avs-point-in-time-copy \
storage-avs-remote-mirror \
storage-mpathadm \
\
system-kernel-cpu-counters \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-power \
system-kernel-secure-rpc \
system-kernel-security-gss \
system-kernel-suspend-resume \
system-kernel-ultra-wideband \
\
developer-debug-mdb \
developer-linker \
developer-dtrace \
developer-debug-mdb-module-module-qlc \
library-libtecla \
system-data-terminfo \
ncurses-term \
"

#
# CD stage
#
STAGE0_CD_END="\
storage-svm \
grep \
sed \
findutils \
adduser \
screen \
mawk \
pciutils \
passwd \
file \
tar \
mkisofs \
machinesig \
perl-compiler-kit \
"

#
# STAGE0_APTINST
#
STAGE0_APTINST=" \
service-fault-management \
system-data-keyboard-keytables \
system-extended-system-utilities \
system-library-storage-scsi-plugins \
libxml2 \
system-library-math \
\
system-kernel \
system-kernel-platform \
\
system-boot-grub \
system-boot-real-mode \
system-data-hardware-registry \
system-file-system-nfs \
system-file-system-smb \
system-file-system-zfs \
system-header \
system-ipc \
system-management-intel-amt \
system-network \
system-network-spdadm \
system-scheduler-fss \
system-storage-fibre-channel-port-utility \
system-storage-luxadm \
system-storage-sasinfo \
system-trusted \
system-trusted-global-zone \
\
service-file-system-nfs \
service-file-system-smb \
service-hal \
service-network-dns-mdns \
service-network-load-balancer-ilb \
service-resource-pools \
service-storage-avs-cache-management \
service-storage-fibre-channel-fc-fabric \
service-storage-media-volume-manager \
service-storage-removable-media \
service-storage-virus-scan \
\
system-library-libdiskmgt \
system-library-libfcoe \
system-library-platform \
system-library-policykit \
system-library-processor \
system-library-security-gss \
system-library-security-libsasl \
system-library-storage-fibre-channel-hbaapi \
system-library-storage-fibre-channel-libsun-fc \
system-library-storage-ima \
system-library-storage-ima-header-ima \
system-library-storage-libmpapi \
system-library-storage-libmpscsi-vhci \
\
storage-avs-point-in-time-copy \
storage-avs-remote-mirror \
storage-mpathadm \
\
system-kernel-cpu-counters \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-power \
system-kernel-secure-rpc \
system-kernel-security-gss \
system-kernel-suspend-resume \
system-kernel-ultra-wideband \
\
developer-debug-mdb \
developer-linker \
developer-dtrace \
developer-debug-mdb-module-module-qlc \
\
system-file-system-autofs \
\
library-libtecla \
system-library-install-libinstzones \
install-beadm \
\
system-kernel-dtrace-providers \
\
libtspi1 \
service-network-ssh \
network-ssh \
network-ssh-ssh-key \
network-ftp \
\
network-bridging \
network-iscsi-initiator \
network-iscsi-iser \
network-iscsi-target \
network-netcat \
network-telnet \
network-ipfilter \
\
system-accounting-legacy \
system-boot-grub \
system-boot-network \
system-boot-real-mode \
system-boot-wanboot-internal \
system-boot-wanboot \
system-data-hardware-registry \
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
system-file-system-zfs \
system-flash-fwflash \
system-fru-id-platform \
system-fru-id \
system-header-header-agp \
system-header-header-audio \
system-header-header-firewire \
system-header-header-picl \
system-header-header-storage \
system-header-header-ugen \
system-header-header-usb \
system-header \
system-io-tests \
system-ipc \
system-kernel-cpu-counters \
system-kernel-dtrace-providers-xdt \
system-kernel-dtrace-providers \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-platform \
system-kernel-power \
system-kernel-rsmops \
system-kernel-secure-rpc \
system-kernel-security-gss \
system-kernel-suspend-resume \
system-kernel-ultra-wideband \
system-kernel \
system-library-install-libinstzones \
system-library-libdiskmgt-header-libdiskmgt \
system-library-libdiskmgt \
system-library-libfcoe \
system-library-platform \
system-library-policykit \
system-library-processor \
system-library-security-gss-diffie-hellman \
system-library-security-gss-spnego \
system-library-security-gss \
system-library-security-libsasl \
system-library-security-rpcsec \
system-library-storage-fibre-channel-hbaapi \
system-library-storage-fibre-channel-libsun-fc \
system-library-storage-ima-header-ima \
system-library-storage-ima \
system-library-storage-libmpapi \
system-library-storage-libmpscsi-vhci \
system-library-storage-scsi-plugins \
system-library-svm-rcm \
system-library \
system-management-intel-amt \
system-management-pcitool \
system-management-snmp-sea-sea-config \
system-management-wbem-data-management \
system-network-http-cache-accelerator \
system-network-ipqos-ipqos-config \
system-network-ipqos \
system-network-nis \
system-network-ppp-pppdump \
system-network-ppp-tunnel \
system-network-ppp \
system-network-routing-vrrp \
system-network-routing \
system-network-spdadm \
system-network-udapl-udapl-tavor \
system-network-udapl \
system-network-wificonfig \
system-network \
system-remote-shared-memory \
system-scheduler-fss \
system-security-kerberos-5 \
system-storage-fibre-channel-port-utility \
system-storage-luxadm \
system-storage-parted \
system-storage-sasinfo \
system-tnf \
system-trusted-global-zone \
system-trusted \
system-xopen-xcu4 \
system-xopen-xcu6 \
system-xvm-ipagent \
system-zones-brand-s10 \
system-zones-brand-sn1 \
system-zones-internal \
system-zones \
\
service-fault-management-smtp-notify \
service-fault-management-snmp-notify \
service-fault-management \
service-file-system-nfs \
service-file-system-smb \
service-hal \
service-network-dhcp-datastore-binfiles \
service-network-dhcp \
service-network-dns-mdns \
service-network-ftp \
service-network-legacy \
service-network-load-balancer-ilb \
service-network-network-clients \
service-network-network-servers \
service-network-nis \
service-network-slp \
service-network-smtp-sendmail \
service-network-ssh \
service-network-telnet \
service-network-tftp \
service-network-uucp \
service-network-wpa \
service-picl \
service-resource-cap \
service-resource-pools-poold \
service-resource-pools \
service-security-gss \
service-security-kerberos-5 \
service-storage-avs-cache-management \
service-storage-fibre-channel-fc-fabric \
service-storage-isns \
service-storage-media-volume-manager \
service-storage-ndmp \
service-storage-removable-media \
service-storage-virus-scan \
\
storage-avs-point-in-time-copy \
storage-avs-remote-mirror \
storage-metassist \
storage-mpathadm \
storage-stmf \
storage-svm \
"

#
# STAGE0_HDD_END
#
#
STAGE0_HDD_END="\
libsunw-kstat-perl \
libsunw-intrs-perl \
\
grep \
sed \
findutils \
tar \
adduser \
screen \
mawk \
pciutils \
sudo \
less \
sysvinit \
passwd \
lsb-base \
package-dpkg \
file \
rsync \
mkisofs \
util-linux \
procps \
\
diffutils \
man-db \
vim \
\
dbus \
libdbus-glib-1-2 \
libglib2.0-0 \
\
nexenta-lsof \
tmux \
bzip2 \
ntp "

NMPKGS="\
ttf-freefont \
libfontconfig1 \
libpoppler5 \
poppler-utils \
xpdf-utils \
libjson-perl \
libdb4.8 \
sqlite3 \
libdtrace-perl \
libdbd-sqlite3-perl \
apache2 \
libnet-dbus-perl \
perl-compiler-kit \
\
python-elementtree \
python-kid \
python-turbokid \
python-turbogears \
python-sqlobject \
\
nms \
nms-dev \
nmc \
rrs \
nmdtrace \
nmu \
nlm-com \
nbs \
nmv \
python-genshi \
python-tgmochikit \
"

#REQ_DEBS="$REQ_DEBS $NMPKGS"
STAGE0_HDD_END="$STAGE0_HDD_END $NMPKGS"

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
driver-network-arbel \
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
driver-network-eoib \
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
LOCAL_ARCHIVE_DEBS="\
"
#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
company_title="Nexenta"
product_title="NexentaStor"
model_id="STOR_UNIFIED"
model_name="HPC Open Storage Appliance"
os_version="v4.0"
sw_version="v4.0.1"
rootsize1="1024"
profile1="hpc-appliance"
lines1="10000"
desc1="NexentaStor Appliance installation profile"
longdesc1=""
profiles="1"
dot_screenrc="nza-dot-screenrc"
release_file="nza4-release.txt"
apt_sources="http://nexenta.com/apt-nza siddy-stable main contrib non-free"
plugin_sources=
builtin_plugins_dir="$extra_dir/extradebs"
builtin_plugins="nmc-hpc nms-hpc-ds nms-hpc-mds"
#builtin_plugins="nlm-com nmc-storagelink nms-storagelink nms-delorean nmc-delorean nms-autosync nmc-autosync nmv-autosync remote-rep nms-rrdaemon nms-comstar nmc-comstar nmv-comstar nms-autosmart nmc-autosmart nmv-autosmart"
ks_min_mem_required="768"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_disable_motd="1"
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
ks_license_text="nlm-com:/etc/license_text"
ks_welcome_head="1"
ks_welcome_ks="0"
ks_check_upgrade="0"
ks_scripts="nza-ks-scripts"
ks_detect_removable="0"
ks_root_passwd="nexenta"
ks_user_name="admin"
ks_user_passwd="nexenta"
ks_hostname="myhost"
ks_domainname="mydomain.com"
ks_iface_ip0="random"
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
