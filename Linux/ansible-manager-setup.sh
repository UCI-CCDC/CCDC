#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
# A script to deploy ansible, dependencies, and help 
# speed up setup of ansible manager machine. 

#Written by UCI CCDC Linux subteam
#UCI CCDC, 2021
########################################################

# variable declarations
USER="root"
TEMP_PASS=""
# text file created from nmap scanner, should solely contain linux machine IPs
LINUX_IPS=$(cat /root/setup/linux_IPs.txt)


# check for root privs
if [[ $EUID -ne 0 ]]; then
        printf 'Must be run as root, exiting!\n'
        exit 1
fi


# installation

############################
# todo, install from local packages only currently not working
############################



# ssh key setup

#generate id_rsa with no terminal input
ssh-keygen -q -t rsa -N '' <<< $'\ny' >/dev/null 2>&1

if command -v ssh-copy-id  &> /dev/null; then
    #run ssh copy id for each machine in IP list
    for IP in $LINUX_IPS; do
        ssh-copy-id -i /root/.ssh/id_rsa.pub "$IP" -n
    done

else
    echo "ssh-copy-id could not be found, keys not deployed"
fi
