#
# NexentaStor 4.x Profile (Open Storage Appliance)
#

COMMON_REQ_DEBS="\
sunwcs \
sunwcsd \
shell-bash \
package-dpkg \
package-dpkg-apt \
terminal-dialog \
terminal-screen \
system-kernel \
system-kernel-platform \
system-kernel-dynamic-reconfiguration-i86pc \
system-kernel-power \
system-management-pcitool \
system-library-platform \
system-library-policykit \
system-library-processor \
system-network \
system-file-system-udfs \
system-tnf \
service-hal \
system-boot-real-mode \
system-data-hardware-registry \
release-name \
"

DRIVERS_DEBS="\
driver-crypto-dca \
driver-crypto-dprov \
driver-crypto-tpm \
driver-firewire \
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
driver-xvm-pv \
driver-storage-pvscsi \
driver-network-vmxnet3s \
driver-ipmi \
network-aoe-initiator \
network-aoe-target \
network-ipfilter \
storage-aoe \
"

NZA_DEBS="\
nbs \
nms \
nmdtrace \
nmu \
nmc \
nmv-theme-nexentaplain \
nmv \
$NM_PLUGINS \
"

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
locale-zh-cn-extra \
locale-zh-hk \
locale-zh-mo \
locale-zh-sg \
locale-zh-tw \
"

HDD_WORKAROUND_DEBS="\
network-iscsi-iser \
system-file-system-nfs \
web-wget \
"

HDD_REQ_DEBS="\
$COMMON_REQ_DEBS \
$NZA_DEBS \
$LOCALES \
$HDD_WORKAROUND_DEBS \
package-dpkg-apt-clone \
diagnostic-nexenta-collector \
developer-debug-mdb \
developer-debug-mdb-module-module-qlc \
developer-linker \
security-sudo \
system-xvm-ipagent \
system-xvm-xvmstore \
system-kernel-cpu-counters \
system-kernel-dtrace-providers \
system-kernel-dtrace-providers-xdt \
system-kernel-suspend-resume \
system-file-system-autofs \
service-fault-management-snmp-notify \
system-file-system-zfs-tests \
runtime-perl-510-extra \
"

CD_REQ_DEBS="\
$COMMON_REQ_DEBS \
file-gnu-findutils \
file-gnu-coreutils \
text-gawk \
text-gnu-grep \
text-gnu-sed \
hddisco \
mdisco \
machinesig \
shell-expect \
library-perl-5-compiler-kit \
service-file-system-nfs \
system-file-system-nfs \
network-ssh \
network-ssh-ssh-key \
service-network-ssh \
system-extended-system-utilities \
"


#
# Various installer-specific settings
# (see nbld-bootstrap source code for details)
#
company_title="Nexenta"
product_title="NexentaStor"
model_id="STOR_UNIFIED"
model_name="Open Storage Appliance"
os_version="4.0"
sw_version="4.0.0"
rootsize1="1024"
profile1="appliance"
lines1="3000"
desc1="NexentaStor Appliance installation profile"
longdesc1=""
profiles="1"
dot_screenrc="nza-dot-screenrc"
ks_license_text="nexenta-eula:/etc/nexenta-eula.txt"
ks_min_mem_required="768"
ks_rootdisk_type="zfs"
ks_rootdisks=
ks_disable_motd="1"
ks_auto_reboot="0"
ks_use_grub_mbr="1"
ks_autopart_manual="0"
ks_welcome_head="1"
ks_welcome_ks="0"
ks_check_upgrade="0"
ks_scripts="nza-ks-scripts"
ks_detect_removable="0"
ks_root_passwd="nexenta"
ks_user_name="admin"
ks_user_passwd="nexenta"
ks_hostname="myhost"
ks_domainname="mydomain.local"
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
ks_disable_missing_drivers_warning="1"
mode_type="install"
