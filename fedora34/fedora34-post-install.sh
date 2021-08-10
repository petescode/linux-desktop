#!/bin/bash
: '
Notes:
    - No more nVidia support in this script
    - Fedora 34 shipped with GNOME 40, which is a big departure from previous GNOME versions; hence a lot of changes around GNOME settings

    - Changing default fonts - still relevant: https://bbs.archlinux.org/viewtopic.php?id=120604

    - Did not find info for MS Teams telemetry, might not be there - revisit this one day

DEVELOPMENT:
    - work on GNOME settings
    - add PS1 variable
    - LS_COLORS
    - CAC support
    - download and install displaylink-rpm
    - clamav setup
    - disable bluetooth

    - add logging for all these new features
'

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit 1
fi

logfile="/var/log/fedora34-gnome-post-install-script_$(date +"%Y-%m-%d@%H:%M").log"


##### START LOG FILE
echo -e "SCRIPT START: $(date +%c)" > $logfile
start=$(date +%s)


##### SET HOSTNAME
clear
current_name=$(hostnamectl status --static)
echo -e "Current hostname: $current_name"
read -r -p $'\nWould you like to change the hostname? [y/n]\n(Default is no)\n' response
response_lower=${response,,} #tolower
if [[ "$response_lower" =~ ^(yes|y)$ ]]; then
    echo -e "\nSet hostname of this machine: "
    read new_hostname
    hostnamectl set-hostname $new_hostname && "$(date +%T) set hostname to $new_hostname" >> $logfile
fi


##### SET GIT INFO
clear
read -r -p $'\nWould you like to set your git account info? [y/n]\n(Default is no)\n' response
response_lower=${response,,} #tolower
if [[ "$response_lower" =~ ^(yes|y)$ ]]; then
    echo -e "\nSet git username: "
    read git_user
    
    echo -e "\nSet git email: "
    read git_email

# EOF offsetting is weird so it needs to be spaced to the left like this
    gitfile="/home/$(logname)/.gitconfig"
cat > $gitfile << EOF
[user]
    name = $git_user
    email = $git_email
EOF
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

# Microsoft Teams repo
cat > /etc/yum.repos.d/teams.repo << EOF
[teams]
name=teams
baseurl=https://packages.microsoft.com/yumrepos/ms-teams
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
if [[ -f /etc/yum.repos.d/teams.repo ]]; then
    echo -e "$(date +%T) installed Microsoft Teams repository" >> $logfile
else
    echo -e "$(date +%T) ERROR (FATAL): failed installing Microsoft Teams repository" >> $logfile
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
    "ansible"
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
    "powershell"
    "teams"
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

# desktop settings
settings_file="/etc/dconf/db/local.d/01-gnome-settings"
cp ./gnome-settings $settings_file
# success test
if [[ -f $settings_file ]]; then
    echo -e "$(date +%T) GNOME: set default settings - config file is $settings_file" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $settings_file but did not succeed" >> $logfile
fi

# need to remove the existing user settings so it reloads from the new defaults that you've just setup
# otherwise, existing user settings override the defaults and no change occurs
rm /home/$(logname)/.config/dconf/user

# have to delete the thumbnail cache or changes will not take effect
# thumbnail directory does not get created until a preview is generated in Nautilus for the first time
rm -r /home/$(logname)/.cache/thumbnails/

# default file associations with applications
mimeapps="/home/$(logname)/.config/mimeapps.list"
cp ./mimeapps.list $mimeapps
chown $(logname):$(logname) $mimeapps
# success test
if [[ -f $mimeapps ]]; then
    echo -e "$(date +%T) GNOME: set default settings for application file associations" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $mimeapps but did not succeed" >> $logfile
fi

dconf update


##### DISABLE TELEMETRY FOR POWERSHELL AND DOTNET
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1

files=$(find /home -type f -name ".bash_profile")
for i in $files; do
  bash -c "echo "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> $i"
  bash -c "echo "POWERSHELL_TELEMETRY_OPTOUT=1" >> $i"
done


##### DISABLE TELEMETRY FOR VISUAL STUDIO CODE
# vscode builds the directory structure the first time you launch code
su -c 'code &' $(logname) # need to run this as the user or the directory structure gets built for root
sleep 3
killall code
codefile="/home/$(logname)/.config/Code/User/settings.json"
cat >> $codefile << EOF
{
    "telemetry.enableCrashReporter": false,
    "telemetry.enableTelemetry": false
}
EOF
# success test
if grep -q "telemetry" $codefile; then
    echo -e "$(date +%T) GNOME: set disable telemetry settings for Visual Studio Code" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to set disable telemetry settings for Visual Studio Code but did not succeed" >> $logfile
fi


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
