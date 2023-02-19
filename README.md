# Linux Desktop
For code that automates tasks for the Linux Desktop - primarily Fedora GNOME.
Initial setup, repo management, package installation, GNOME preferences, etc.
## Fedora 37
I've updated my Fedora post-install script to the current latest, Fedora 37.
This script needs to be run with sudo or as root. It's meant to be run immediately after installing a default Fedora 37 GNOME installation.
It will setup repos, install packages, and change GNOME default settings such as themes, icons, window button placement, etc.
Arrays are available for easily adding or removing packages to be modified.
The script writes log messages to a file in /var/log for review once it's complete.
