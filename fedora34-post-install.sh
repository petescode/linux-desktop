#!/bin/bash
: '
Notes:
    - No more nVidia support in this script
    - Fedora 34 shipped with GNOME 40, which is a big departure from previous GNOME versions; hence a lot of changes around GNOME settings
        - At this time, I cant find solid documentation on programatically changing GNOME 40 settings
        - Previous methods using dconf files/directories are not working
        - Need to revisit this once GNOME 40 has matured

    - Changing default fonts - still relevant: https://bbs.archlinux.org/viewtopic.php?id=120604

DEVELOPMENT:
    - work on GNOME settings
        - keyboard shortcut for terminal
        - Search & Preview --> Thumbnail --> size > 60M
        - sort folders before files
    - ubuntu fonts
    - add PS1 variable
    - LS_COLORS
    - CAC support
    - Microsoft Teams\
    - make hostnamectl optional
'

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit 1
fi

logfile="/var/log/fedora34-gnome-post-install-script.log"


##### START LOG FILE
echo -e "SCRIPT START: $(date +%c)" > $logfile
start=$(date +%s)


##### SET HOSTNAME
current_name=$(hostnamectl status --static)
echo -e "Current hostname: $current_name"
read -r -p $'\nWould you like to change the hostname? [y/n]\n(Default is no)\n' response
response_lower=${response,,} #tolower
if [[ "$response_lower" =~ ^(yes|y)$ ]]; then
    echo -e "\nSet hostname of this machine: "
    read new_hostname
    hostnamectl set-hostname $new_hostname && "$(date +%T) set hostname to $new_hostname" > $logfile
fi


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

# Microsoft PowerShell core repo https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1#fedora
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo && echo -e "$(date +%T) installed Microsoft PowerShell repository" >> $logfile

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


##### INSTALL NEW PACKAGES
clear
echo -e "\nINSTALL NEW PACKAGES\n"

# array of packages to install from repos
declare -a packages=(
    "darktable"
    "dconf-editor"
    "dnf-utils"
    "gnome-tweaks"
    "icedtea-web"
    "keepassxc"
    "nmap"
    "perl-Image-ExifTool"
    "pinta"
    "p7zip"
    "smartmontools"
    "terminator"
    "vim"
    "wireshark"
    "youtube-dl"
    "papirus-icon-theme"
    "powershell"
)

declare -a group_packages=(
    "--with-optional virtualization"
)

declare -a fusion_packages=(
    "fuse-exfat"
    "libdvdcss"
    "python-vlc"
    "vlc"
)

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

##### GNOME 40 settings

# https://help.gnome.org/admin/system-admin-guide/stable/dconf-custom-defaults.html.en

# font settings
# need to account for "Legacy Window Titles" (see gnome-tweaks)
fonts="/etc/dconf/db/local.d/01-fonts"
cat > $fonts << EOF
# Custom default GNOME settings for fonts
[org/gnome/desktop/interface]
font-name='DejaVu Sans Book 11'
monospace-font-name='DejaVu Sans Mono 11'
document-font-name='DejaVu Sans 11'
EOF
# success test
if [[ -f $fonts ]]; then
    echo -e "$(date +%T) GNOME: set default fonts to DejaVu" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $fonts but did not succeed" >> $logfile
fi

# nautilus settings (the window explorer)
# thumbnail limit doesn't seem to work anymore (see dconf editor)
nautilus="/etc/dconf/db/local.d/02-nautilus"
cat > $nautilus << EOF
# Custom default GNOME settings for Nautilus
[org/gnome/nautilus/preferences]
default-folder-viewer='list-view'
thumbnail-limit='200'
EOF
# success test
if [[ -f $nautilus ]]; then
    echo -e "$(date +%T) GNOME: set default settings for Nautilus" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $nautilus but did not succeed" >> $logfile
fi

# desktop settings
desktop="/etc/dconf/db/local.d/03-desktop"
cat > $desktop << EOF
# Custom default GNOME settings for desktop
[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:appmenu'
theme='Adwaita-dark'
titlebar-font='DejaVu Sans Bold 11'
EOF
# success test
if [[ -f $desktop ]]; then
    echo -e "$(date +%T) GNOME: set default settings for desktop" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $desktop but did not succeed" >> $logfile
fi

# tray settings seem to be at org.gnome.shell.favorite-apps

dconf update


##### DISABLE MICROSOFT TELEMETRY
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1

files=$(find /home -type f -name ".bash_profile")
for i in $files; do
  bash -c "echo "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> $i"
  bash -c "echo "POWERSHELL_TELEMETRY_OPTOUT=1" >> $i"
done


##### REPORTING
stop=$(date +%s)
runtime=$((stop-start))
echo -e "SCRIPT END: $(date +%c)" >> $logfile
echo -e "RUN TIME: $runtime seconds (~$(($runtime / 60)) minutes)" >> $logfile
clear
cat $logfile


##### REBOOT
echo
read -p "Press ENTER to proceed with reboot"
echo -e "\nLog file saved to: $logfile"
echo -e "\nRebooting in 5 seconds..."
tick=4
while [[ $tick -le 4 && $tick -ge 0 ]]; do
    echo $tick
    sleep 1
    ((tick-=1))
done

systemctl reboot