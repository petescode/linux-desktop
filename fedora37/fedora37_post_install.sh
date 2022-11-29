#!/bin/bash
: '
Notes:
    - For figuring out your custom GNOME settings
        https://askubuntu.com/questions/787451/where-does-ubuntu-gnome-store-the-keyboard-shortcuts-configuration-file

    - Format of the Firefox bookmarks file MUST conform to "bookmarks-<date>.jsonlz4" or it will not be found

    - youtube-dl replaced by yt-dlp (fork) due to abandonment and throttling

    - Changing default fonts - still relevant: https://bbs.archlinux.org/viewtopic.php?id=120604

    - Have not really figured out all the laptop lid power options. Seeing inconsistent behavior on my laptop

    - clamav-install.sh and cert-install.sh are currently benign; for future development

DEVELOPMENT:
    - need to create a separate script or at least function for writing to log file to clean up all this code
    - CAC support
    - clamav install
    - power settings
        - lid close action
        - blank screen after
        - sleep after
    
    - for power settings, when you use the Tweak tool to change lid close action on power, it actually creates this file:
       /usr/libexec/gnome-tweak-tool-lid-inhibitor
       which is a Python 3 script.
       The location of this file has moved at least 3 times in the past several years.
       May be easier to adjust settings in systemd
       See last answer (most recent and should be most accurate):
       https://unix.stackexchange.com/questions/307497/gnome-disable-sleep-on-lid-close/307498
'

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit 1
fi

logfile="/var/log/fedora37-gnome-post-install-script_$(date +"%Y-%m-%d@%H:%M").log"


##### START LOG FILE
echo -e "SCRIPT START: $(date +%c)" > $logfile
start=$(date +%s)

clear
echo -e "WARNING: Do not use Fedora while the script runs.\n\n"

##### SET HOSTNAME
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

# install Microsoft PowerShell repo
curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo && echo -e "$(date +%T) installed Microsoft PowerShell repository" >> $logfile

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


##### UPDATE EXISTING PACKAGES
clear
echo -e "\nUPDATE EXISTING PACKAGES\n"
dnf update -y


##### UPDATE/INSTALL MULTIMEDIA CODECS
clear
echo -e "\nUPDATE & INSTALL MULTIMEDIA CODECS\n"

# requires RPM Fusion repos https://rpmfusion.org/Configuration/
dnf groupupdate multimedia --setop="install_weak_deps=False" -y
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
    "gnome-screenshot"
    "gnome-tweaks"
    "golang"
    "keepassxc"
    "nmap"
    "nss-tools"
    "papirus-icon-theme"
    "perl-Image-ExifTool"
    "pinta"
    "p7zip"
    "smartmontools"
    "sqlite"
    "terminator"
    "vim"
    "wireshark"
    "wodim"
    "yt-dlp"
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


##### GNOME 43 settings

# https://help.gnome.org/admin/system-admin-guide/stable/dconf-custom-defaults.html.en

# desktop settings
settings_file="/etc/dconf/db/local.d/01-gnome_settings"
cp ./gnome_settings $settings_file
# success test
if [[ -f $settings_file ]]; then
    echo -e "$(date +%T) GNOME: set default settings - config file is $settings_file" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to create file $settings_file but did not succeed" >> $logfile
fi

# so the Nautilus changes work fine as long as the user has not opened Nautilus once already before the script is run
# in that case, something is overriding


# NEEDS REVIEW
# did they or did they not work? commenting this out for testing
#runuser --login $(logname) --command 'gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"' 


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

sleep 1 && dconf update


##### laptop lid close
# but this would work all the time, not just when plugged into power
#https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
#https://unix.stackexchange.com/questions/307497/gnome-disable-sleep-on-lid-close
logind="/etc/systemd/logind.conf"
sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g' $logind && echo -e "$(date +%T) set laptop lid switch settings in $logind" >> $logfile

# success test
# bad test - refine plz
#if [[ egrep "^HandleLidSwitch" $logind ]]; then
#    echo -e "$(date +%T) set laptop lid close settings in $logind" >> $logfile
#else
#    echo -e "$(date +%T) ERROR: attempted to modify file $logind but did not succeed" >> $logfile
#fi


##### NEEDS UPDATE (reporting)
# set terminator settings
# https://www.systutorials.com/docs/linux/man/5-terminator_config/
terminator_dir="/home/$(logname)/.config/terminator"
mkdir --parents $terminator_dir
cp ./terminator_config "$terminator_dir/config"
chown --recursive $(logname):$(logname) $terminator_dir


##### DISABLE TELEMETRY FOR POWERSHELL AND DOTNET
# not installed here but in case they get installed in the future
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1

files=$(find /home -type f -name ".bash_profile")
for i in $files; do
  bash -c "echo "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> $i" && echo -e "$(date +%T) set disable telemetry settings for .Net CLI" >> $logfile
  bash -c "echo "POWERSHELL_TELEMETRY_OPTOUT=1" >> $i" && echo -e "$(date +%T) set disable telemetry settings for PowerShell" >> $logfile
done


##### SET TELEMETRY FOR VISUAL STUDIO CODE
codefile="/home/$(logname)/.config/Code/User/settings.json"
mkdir --parents "/home/$(logname)/.config/Code/User"
cp ./vscode_settings.json $codefile
chown --recursive $(logname):$(logname) "/home/$(logname)/.config/Code"

# success test
if grep -q "telemetry" $codefile; then
    echo -e "$(date +%T) GNOME: set telemetry settings for Visual Studio Code" >> $logfile
else
    echo -e "$(date +%T) ERROR: attempted to set telemetry settings for Visual Studio Code but did not succeed" >> $logfile
fi


##### SETUP GOLANG DEVELOPMENT ENVIRONMENT
mkdir --parents "/home/$(logname)/go" && chown $(logname):$(logname) "/home/$(logname)/go"
echo 'export GOPATH=$HOME/go' >> "/home/$(logname)/.bashrc" \
&& echo -e "$(date +%T) configured golang" >> $logfile


##### FIREFOX SETTINGS

# FIREFOX BOOKMARKS
# If places.sqlite is missing then Firefox will 
#   rebuild the bookmarks from the most recent JSON backup in the bookmarkbackups folder 
ff_profile_dir=$(find "/home/$(logname)/.mozilla/firefox" -type d -name "*default-release")
cp ./bookmarks-2022-11-13.jsonlz4 $ff_profile_dir/bookmarkbackups/

### NEEDS UPDATE
# does not work when Firefox was left open
# kill firefox process before proceeding
pkill --full firefox && sleep 1
rm $ff_profile_dir/places.sqlite

echo -e "$(date +%T) set Firefox bookmarks" >> $logfile
### need to put a failure clause in here - log file did not show that this had failed

# FIREFOX ALL USER SETTINGS
# https://github.com/arkenfox/user.js
# http://kb.mozillazine.org/User.js_file
cp ./user.js $ff_profile_dir/ && echo -e "$(date +%T) set Firefox preferences via user.js" >> $logfile

# FIREFOX INSTALL CERTIFICATES



##### CHROME SETTINGS
# CHROME INSTALL CERTIFICATES
# need to do an if exists logic on this, or this script cant be run multiple times in a row


##### VM directories prepare
mkdir --parents "/home/$(logname)/Documents/VMs/ISOs"
chown --recursive $(logname):$(logname) "/home/$(logname)/Documents/VMs"

# NEEDS REVIEW - for testing
# need to remove the existing user settings so it reloads from the new defaults that you've just setup
# otherwise, existing user settings override the defaults and no change occurs
rm /home/$(logname)/.config/dconf/user

# have to delete the thumbnail cache or changes will not take effect
# thumbnail directory does not get created until a preview is generated in Nautilus for the first time
rm -r /home/$(logname)/.cache/thumbnails/


##### REPORTING
stop=$(date +%s)
runtime=$((stop-start))
echo -e "SCRIPT END: $(date +%c)" >> $logfile
echo -e "RUN TIME: $runtime seconds (~$(($runtime / 60)) minutes)" >> $logfile
#clear
#cat $logfile


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