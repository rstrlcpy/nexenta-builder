NM_PLUGINS="\
nmv-autosync \
nmc-autosync \
nmv-comstar \
nmc-comstar \
nmv-autosmart \
nmc-autosmart \
nms-rrdaemon \
remote-rep \
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

company_title="Eisoo"
product_title="Eisoo"
desc1="EISOO OS Appliance installation profile"
ks_scripts="eisoo-ks-scripts"
