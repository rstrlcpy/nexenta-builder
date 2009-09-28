
DESKTOP_CMN_DEBS="x-window-system-core menu mime-support \
    gdm gnome-session gnome-panel gnome-terminal gksu \
    gnome-desktop-environment nautilus metacity synaptic evolution gaim \
    firefox-gnome-support nexenta-artwork nexenta-sounds gnome-cups-manager \
    gs gs-common gs-gpl xterm firefox update-notifier hwdb-client gdebi \
    gnome-spell aspell-en totem-gstreamer-firefox-plugin"

LOCAL_ARCHIVE_DEBS="dialog ${DESKTOP_CMN_DEBS} abiword gnumeric \
    sunwtnetc sunwesu sunwtoo sunwsshu"

STAGE0_DEBS="bastet screen dialog debootstrap wget sunwsshu sunwesu \
    links file"
