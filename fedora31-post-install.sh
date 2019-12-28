#!/bin/bash
: '
DEVELOPMENT:
    - should we use different package arrays for packages from default repos, tainted repos, proprietary, etc?

'

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit 1
fi

logfile="/root/post-install.log"

##### START LOG FILE
echo -e "SCRIPT START: $(date +%c)" > $logfile


##### INSTALL REPOS
# RPM Fusion free and nonfree https://rpmfusion.org/Configuration/
if dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y; then
    echo -e "$(date +%T) finished installing RPM Fusion free and nonfree repositories" >> $logfile
else
    echo -e "$(date +%T) ERROR: failed installing RPM Fusion free and nonfree repositories - exiting" >> $logfile
    exit 1
fi

# RPM Fusion tainted repos
if dnf install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted -y; then
    echo -e "$(date +%T) finished installing RPM Fusion free tainted and nonfree tainted repositories" >> $logfile
else
    echo -e "$(date +%T) ERROR: failed installing RPM Fusion free tainted and nonfree tainted repositories - exiting" >> $logfile
    exit 1
fi


##### INSTALL PACKAGES
# array of packages to install
declare -a packages=(
    "vim"
    "terminator"
    "smartmontools"
    "gnome-tweaks"
)

for i in ${packages[@]}; do
    echo $i
done