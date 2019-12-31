#!/bin/bash
: '
Notes:
    - nVidia installation assumes non-legacy hardware
    - nVidia drivers install from RPM Fusion repos - not fedora-workstation-repositories
    - For more info on Fedora Workstation Repositories (Chrome lives here): https://fedoraproject.org/wiki/Workstation/Third_Party_Software_Repositories

DEVELOPMENT:
    - work on GNOME settings
        - keyboard shortcut for terminal
        - move window buttons to left
        - set theme (arc-theme)
        - Search & Preview --> Thumbnail --> size > 60M
        - sort folders before files
    - add PS1 variable
    - LS_COLORS
    - desired hostname (user input)
'

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit 1
fi

logfile="/var/log/fedora31-gnome-post-install-script.log"


##### START LOG FILE
echo -e "SCRIPT START: $(date +%c)" > $logfile
start=$(date +%s)


##### INSTALL REPOS
# RPM Fusion free and nonfree https://rpmfusion.org/Configuration/
clear
echo -e "\nINSTALL NEW REPOSITORIES\n"

if dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y; then
    echo -e "$(date +%T) installed RPM Fusion free and nonfree repositories" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing RPM Fusion free and nonfree repositories - exiting" >> $logfile
    exit 1
fi

# RPM Fusion tainted repos
if dnf install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted -y; then
    echo -e "$(date +%T) installed RPM Fusion free tainted and nonfree tainted repositories" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing RPM Fusion free tainted and nonfree tainted repositories - exiting" >> $logfile
    exit 1
fi

# Flatpak repo
if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    echo -e "$(date +%T) installed Flathub repository" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing Flathub repository - exiting" >> $logfile
    exit 1
fi

# Microsoft Visual Studio Code repo https://code.visualstudio.com/docs/setup/linux
rpm --import https://packages.microsoft.com/keys/microsoft.asc && echo -e "$(date +%T) imported Microsoft signing key" >> $logfile

if echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo; then
    echo -e "$(date +%T) installed Visual Studio Code repository" >> $logfile
    echo -e "    \`-----> remember to disable telemetry options once installed" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing Visual Studio Code repository - exiting" >> $logfile
    exit 1
fi

# Google Chrome repo 
if dnf install fedora-workstation-repositories -y && dnf config-manager --set-enabled google-chrome; then
    echo -e "$(date +%T) installed Fedora Workstation/Third Party repositories" >> $logfile
    echo -e "$(date +%T) set Google Chrome repo as enabled" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing Fedora Workstation/Third Party repositories - exiting" >> $logfile
    exit 1
fi


##### REMOVE UNWANTED PACKAGES
clear
echo -e "\nREMOVE UNWANTED PACKAGES\n"
sleep 1

declare -a unwanted_packages=(
    "cheese"
    "gnome-boxes"
    "gnome-contacts"
    "gnome-maps"
    "rhythmbox"
    "simple-scan"
)

# removes all packages with one command
dnf remove $(echo ${unwanted_packages[@]}) -y && \
echo -e "$(date +%T) removed the following packages:\n$(for i in ${unwanted_packages[@]}; do echo "  $i"; done)" >> $logfile
dnf autoremove -y
dnf clean all


##### UPDATE EXISTING PACKAGES
clear
echo -e "\nUPDATE EXISTING PACKAGES\n"
dnf update -y


##### UPDATE/INSTALL MULTIMEDIA CODECS
clear
echo -e "\nUPDATE & INSTALL MULTIMEDIA CODECS\n"

# requires RPM Fusion repos https://rpmfusion.org/Configuration/
dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf groupupdate sound-and-video -y


##### INSTALL FIRMWARE UPDATES
clear
echo -e "\nINSTALL FIRMWARE UPDATES\n"

# requires RPM Fusion tainted repos https://rpmfusion.org/Configuration/
dnf install \*-firmware -y
# firmware install causes errors, but apparently is a bug with package in one of tainted repos that has a report open for it; do not expect this to be an issue forever


##### INSTALL NEW PACKAGES
clear
echo -e "\nINSTALL NEW PACKAGES\n"

# nVidia drivers (if needed)
if [[ $(lspci | grep -i nvidia) ]]; then
    echo -e "$(date +%T) nVidia hardware detected, marking drivers for installation" >> $logfile
    nvidia=true
fi

# array of packages to install from repos
declare -a packages=(
    "vim"
    "terminator"
    "smartmontools"
    "gnome-tweaks"
    "dnf-utils"
    "perl-Image-ExifTool"
    "darktable"
    "arc-theme"
    "icedtea-web"
    "pinta"
    "youtube-dl"
    "p7zip"
    "keepassxc"
    "nmap"
    "wireshark"
)

declare -a group_packages=(
    "--with-optional virtualization"
)

if [[ $nvidia = true ]]; then
    declare -a fusion_packages=(
        "fuse-exfat"
        "libdvdcss"
        "vlc"
        "python-vlc"
        "xorg-x11-drv-nvidia-390xx"
    )
else
    declare -a fusion_packages=(
        "fuse-exfat"
        "libdvdcss"
        "vlc"
        "python-vlc"
    )
fi

declare -a proprietary_packages=(
    "code"
    "google-chrome-stable"
)

# install each package from each array in one command
if dnf install $(echo ${packages[@]} ${fusion_packages[@]} ${proprietary_packages[@]}) -y; then
    echo -e "$(date +%T) installed the following packages:
$(for i in ${packages[@]}; do echo "  $i"; done) \
    \n$(for i in ${fusion_packages[@]}; do echo "  $i"; done) \
    \n$(for i in ${proprietary_packages[@]}; do echo "  $i"; done)" >> $logfile
else
    # something failed
    echo -e "$(date +%T) ERROR: problems occurred when trying to install the following packages:
$(for i in ${packages[@]}; do echo "  $i"; done) \
    \n$(for i in ${fusion_packages[@]}; do echo "  $i"; done) \
    \n$(for i in ${proprietary_packages[@]}; do echo "  $i"; done)" >> $logfile
    
    echo -e "\`-------------> check /var/log/dnf.log for more details" >> $logfile
fi

# install group packages
dnf groupinstall $(echo ${group_packages[@]}) -y && \
echo -e "$(date +%T) installed the following package groups:\n$(for i in "${group_packages[@]}"; do echo "  $i"; done)" >> $logfile

# install Flatpaks
if flatpak install flathub com.discordapp.Discord -y; then
    echo -e "$(date +%T) installed Discord Flatpak" >> $logfile
else
    echo -e "$(date +%T) ERROR: failed installing Discord Flatpak" >> $logfile
fi

if flatpak install flathub com.slack.Slack -y; then
    echo -e "$(date +%T) installed Slack Flatpak" >> $logfile
else
    echo -e "$(date +%T) ERROR: failed installing Slack Flatpak" >> $logfile
fi


##### SET DEFAULT GNOME SETTINGS
# using here-doc to create new file with content

# enable min,max window buttons & set position to the left
cat > /etc/dconf/db/local.d/00-local-settings << EOF
# Custom default gnome settings for all local users
[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:'
EOF

dconf update


##### REPORTING
stop=$(date +%s)
runtime=$((stop-start))
echo -e "SCRIPT END: $(date +%c)" >> $logfile
echo -e "RUN TIME: $runtime seconds (~$(($runtime / 60)) minutes)" >> $logfile
clear
cat $logfile

# add reboot