#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
    echo -e "\nScript must be run as root! Exiting..."
    exit
fi

# array of packages to install
declare -a packages=(
    "vim"
    "terminator"
    "smartmontools"
)

for i in ${packages[@]}; do
    echo $i
done