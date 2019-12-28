#!/bin/bash
: '
DEVELOPMENT:
    - should we use different package arrays for packages from default repos, tainted repos, proprietary, etc?
    - try using "dnf shell" to run all dnf commands at once
    - work on GNOME settings
    - add 3rd party repos
    - install nvidia repo
        - first see if nvidia is on the machine
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
    echo -e "$(date +%T) ERROR (FATAL): failed installing RPM Fusion free and nonfree repositories - exiting" >> $logfile
    exit 1
fi

# RPM Fusion tainted repos
if dnf install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted -y; then
    echo -e "$(date +%T) finished installing RPM Fusion free tainted and nonfree tainted repositories" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing RPM Fusion free tainted and nonfree tainted repositories - exiting" >> $logfile
    exit 1
fi

# Flatpak repo
if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    echo -e "$(date +%T) finished installing Flathub repository" >> $logfile
    flathub=true
else
    echo -e "$(date +%T) ERROR: failed installing Flathub repository - continuing without it" >> $logfile
    flathub=false
fi

# nVidia repo (if needed)
if [[ $(lspci | grep -i nvidia) ]]; then
    echo "nVidia hardware detected!"
fi


##### REMOVE UNWANTED PACKAGES


##### INSTALL PACKAGES
# requires RPM Fusion repos https://rpmfusion.org/Configuration/
dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf groupupdate sound-and-video -y

# requires RPM Fusion tainted repos https://rpmfusion.org/Configuration/
dnf install libdvdcss -y
dnf install \*-firmware -y
# firmware install causes errors, but apparently is a bug with package in one of tainted repos that has a report open for it; do not expect this to be an issue forever


# array of packages to install from default repos
declare -a packages=(
    "vim"
    "terminator"
    "smartmontools"
    "gnome-tweaks"
    "dnf-utils"
    "perl-Image-ExifTool"
    "darktable"
    "arc-theme"
)

declare -a fusion_packages=(
    "fuse-exfat"
    "libdvdcss"
)

# installs all packages with one command
dnf install $(echo ${packages[@]}) -y


# install Flatpaks, if the Flathub repo installed correctly
if [[ $flathub = true ]]; then
    # install Discord Flatpak
    flatpak install flathub com.discordapp.Discord -y && echo -e "$(date +%T) finished installing Discord Flatpak" >> $logfile

    # install Slack Flatpak
    flatpak install flathub com.slack.Slack -y && echo -e "$(date +%T) finished installing Slack Flatpak" >> $logfile
else
    echo -e "$(date +%T) could not install Discord Flatpak due to no Flathub repo" >> $logfile
    echo -e "$(date +%T) could not install Slack Flatpak due to no Flathub repo" >> $logfile
fi