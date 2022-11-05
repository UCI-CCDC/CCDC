#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
# UCI CCDC linux script to install our ansible base setup 
# onto a machine after it's been checked out by audit.sh

#Written by UCI CCDC linux subteam
#UCI CCDC, 2021
########################################################


# * MUST make sure machine has sudo installed, othewise install will fail. 

if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make shit prettier
banner () { printf "========================================================\n"; }

#generate inv/ dir if doesn't already exist; define outfile for script output
mkdir -p /root/inv/ 
outFile="/root/inv/ansiblescriptlog-$(hostname).txt"
adtfile="tee -a /root/inv/ansiblescriptlog-$(hostname).txt"
touch $outFile

# define basic vars for script usage
mkdir -p /root/setup
linux_ip_file="/root/setup/linux_IPs.txt"
touch $linux_ip_file
LINUX_IPS=$(cat $linux_ip_file)

######################################################
#before script execution, we need to be as sure as possible the machine is clean and secure
#centralization bad, but also good
######################################################

# create ansible.cfg in home directory
touch ~/.ansible.cfg
echo "[ssh_connection]" >> ~/.ansible.cfg
echo "ssh_args = -o StrictHostKeyChecking=accept-new" >> ~/.ansible.cfg

mkdir -p /etc/ansible/

# check if ansible is installed. If not, install it. 
if ! command -v ansible &> /dev/null; then
    if [ $(command -v apt-get) ]; then # Debian based
        #add repo to /etc/apt/sources.list
        echo "" >> /etc/apt/sources.list
        echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main"
        #gnupg is required for key add procedure
        apt-get update -y 
        apt install gnupg -y
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        #update package lists and install it
        apt install ansible -y

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
 
# generate ssh key for ansible to use for login, no interaction needed
# key is named id_rsa by default; will overwrite any other ssh keys but makes deployment MUCH easier
ssh-keygen -q -t rsa -f "/root/.ssh/id_rsa" -C "ansible-key" -N '' <<< $'\ny' >/dev/null 2>&1

#check if linux ip list file is empty
if ! [ -s $linux_ip_file ]; then
    # if not empty and ssh-copy id is valid, copy key to all ips in list
    if command -v ssh-copy-id  &> /dev/null; then
        #run ssh copy id for each machine in IP list
        for IP in $LINUX_IPS; do
            ssh-copy-id -i /root/.ssh/id_rsa.pub "$IP"
        done

    else
        echo "ssh-copy-id command not valid, keys not deployed"
    fi
else 
    echo "$linux_ip_file is empty, no hosts to copy pubkey to"

fi
