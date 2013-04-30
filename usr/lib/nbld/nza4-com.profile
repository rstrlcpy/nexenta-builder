NM_PLUGINS="\
nmv-autosync \
nmc-autosync \
nmv-comstar \
nmc-comstar \
nmv-autosmart \
nmc-autosmart \
nms-rrdaemon \
remote-rep \
nmc-rsf-cluster \
nms-rsf-cluster \
nmv-rsf-cluster \
ns-i18n-rsf-cluster \
rsf-1 \
nlm-com \
"

source $NBLD_LIBDIR/nza4.profile

ks_disable_services="\
system/zones:default \
system/zones-monitoring:default \
network/shell:default \
network/login:rlogin \
network/finger:default \
network/telnet:default \
network/dns/multicast:default \
application/font/fc-cache:default \
system/device/audio:default \
"
product_type='Enterprise Edition'
