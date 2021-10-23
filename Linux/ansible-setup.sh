#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
# UCI CCDC linux script to install our ansible base setup 
# onto a machine after it's been checked out by audit.sh

#Written by UCI CCDC linux subteam
#UCI CCDC, 2021
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make shit prettier
banner () { printf "========================================================\n"; }

#generate inv/ dir if doesn't already exist; define outfile for script output
mkdir -p /root/inv/ 
outFile="$HOME/inv/ansiblescriptlog-$(hostname).txt"
adtfile="tee -a /root/inv/ansiblescriptlog-$(hostname).txt"
touch $outFile


######################################################
#before script execution, we need to be as sure as possible the machine is clean and secure
#centralization bad, but also good
######################################################


# check if ansible is installed. If not, install it. 
if ! ansible_location="$(type -p "ansible")" || [[ -z $ansible_location]]; then
    if [ $(command -v apt-get) ]; then # Debian based
        #add repo to /etc/apt/sources.list
        echo "" >> /etc/apt/sources.list
        echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
        #gnupg is required for key add procedure
        apt install gnupg -y
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        #update package lists and install it
        apt-get update -y 
        apt install ansible

    elif [ $(command -v yum) ]; then
        yum update
        yum install ansible
    elif [ $(command -v dnf) ]; then
        dnf update
        dnf install ansible
    elif [ $(command -v pacman) ]; then 
        pacman -Syy
        pacman -Su
        pacman -S ansible
    fi
fi
 
