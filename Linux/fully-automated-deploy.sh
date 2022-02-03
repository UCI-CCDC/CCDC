#!/bin/bash

# I AM BROKEN AND DO NOT WORK YET. SORRY
echo "this script is currently non functional. oops"
exit 0;

########################################################
# https://github.com/UCI-CCDC/CCDC
#UCI CCDC linux script for automation of automation of setup
# meta-meta automation

#Written by UCI CCDC linux subteam
#UCI CCDC, 2022
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make prettier
banner () { printf "========================================================\n"; }



#actual functions for actual things
updateOS() {
    
    ## Install & update utilities
    if [ $(command -v apt-get) ]; then # Debian based
        apt-get update -y -q
    elif [ $(command -v yum) ]; then
        yum update
    elif [ $(command -v pacman) ]; then 
        pacman -Syy
        pacman -Su
    elif [ $(command -v apk) ]; then # Alpine
        apk update
        apk upgrade
    fi

}


harden() { 
    printf "We are now doing system hardening\n"

    read -r -p "Are you sure? The harden script is currently non-functional, as of March 02 [Y/n] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            wget https://raw.githubusercontent.com/UCI-CCDC/CCDC2020/master/harden.sh -O harden.sh && bash harden.sh

            ;;
        *)
            exit 1;;
    esac
    # I know this is shit but I really don't care anymore 
    #I'm lazy af, this calls the hardening script and runs it. Hope it works
}


backup_config_dirs() {
        # Takes 1 argument - Array of strings of paths that need to be backed up.

        # Get paths that exist
        local -n dir_arr=$1
        dir_str=""

        for path in ${dir_arr[@]};
        do
		# Add path to string if it is a directory or file
                [[ -d $path ]] && dir_str="$dir_str $path"
                [[ -f $path ]] && dir_str="$dir_str $path"
        done
	
	# Don't do anything if string is empty (None of the paths exist for current user)
        [ -z "$dir_str" ] && echo "No backup Created. User does not have any of the specified files." && return

        # Make backup in /Backups directory in Home
        mkdir -p ~/Backups
        version="$(find ~/Backups -name "$HOSTNAME-config-dir-backup-[0-9]*\.tgz" | wc -l)"
        tar -czf ~/Backups/$HOSTNAME-config-dir-backup-$version.tgz $dir_str
}



#below should both be false
ShouldUpdate=false

# To see if this is the first time running the script.
# Useful for backing up config directories.
[[ ! -e ./auditlog.log ]] && touch auditlog.log && echo 0 > auditlog.log # This is only 0 temporarily if the log didn't exist yet.
timesRun=$(echo $(head -n 1 "./audit.log") + 1 | bc -l)
echo $timesRun > auditlog.log

while getopts :hdxa option
do
case "${option}" in
h) 
    printf "\n UCI CCDC Automated Deployment Script\n"

    printf "    ==============Options==============\n"
    printf " -h     Prints this help menu\n"
    printf " -a     Set up Ansible server on this machine\n"
    printf " -w     Set up Wazuh Manager (server) on this machine\n"
    printf " -n     Run wazuh agent deployment against network\n"
    printf " -x     Runs hardening script (broke)\n"
    printf " -d     Runs Debsums to check file validity on debian based systems\n"

    printf "\n\n\n"
    exit 1;;
x)
    harden          #calls hardening function above
    exit 1;;


#debsums flag
d)
    printf "Checking file validity using debsums"

    apt install -y debsums

    echo "File validity output of debsums" >> $outFile
    debsums -c | $adtfile
    exit 1;;

# install ansible server
a)
    printf "Ansible flag selected, Installing ansible server on this machine\n\n"

    #download ansible script
    wget https://raw.githubusercontent.com/UCI-CCDC/CCDC/testing/Linux/ansible-setup.sh
    echo ""
    chmod +x ansible-setup.sh
    bash ansible-setup.sh

    printf "\nExiting deployment script now\n"
    exit 1;;

# wazuh server installation
a)
    printf "Installing wazuh manager through unattended installation script\n\n"

    #download ansible script
    wget https://raw.githubusercontent.com/UCI-CCDC/CCDC/testing/Linux/ansible-setup.sh
    echo ""
    chmod +x ansible-setup.sh
    bash ansible-setup.sh

    printf "\nExiting deployment script now\n"
    exit 1;;


#handles incorrect flags, 
\?) echo "incorrect syntax, use -h for help"
    exit 1;;

#handles when no argument is passed for a flag that requires one
:)  echo "invalid option: -$OPTARG requires an argument"
    exit 1;;
esac
done



echo '
        _________ ______
    ___/   \     V     \
   /  ^    |\    |\     \
  /_O_/\  / /    | ‾‾\  |
 //     \ |‾‾‾\_ |     ‾‾
//      _\|    _\|

        zoot zoot!'






















#generate inv directory, audit.txt, and set up variables for redirection
printf "\n*** generating inv direcory and audit.txt in your root home directory\n"
mkdir -p /root/inv/ 
adtfile="tee -a /root/inv/audit-$(hostname).txt"



echo -e "\n\e[92m"
echo "Hostname: $(hostname)" | $adtfile
echo -e "\e[0m"

echo "Date: $(date)" >> $outFile

# this is not compatible with distros that don't use the os-release file; /etc/*release would make it compatible, but I am not sure about 
# the validity of the formatting
osOut=$(cat /etc/*-release | grep -w "PRETTY_NAME" | cut -d "=" -f 2)

printf "This machine's OS is "
echo -e "\e[31m"

echo $osOut | $adtfile
echo -e "\e[0m"

echo -e "\e[95m***IP ADDRESSES***\e[0m"
echo "Most recent IP: $(hostname -I | awk '{print $1}')"
echo "All IP Addresses: $(hostname -I)" | $adtfile

## /etc/sudoers
if [ -f /etc/sudoers ] ; then
    printf "\nSudoers File:\n"
    sudo awk '!/#(.*)|^$/' /etc/sudoers 
    echo ""
fi 




banner >> $outFile
printf "\n\n" >> $outFile


#these if statements make sure that updates are executed at the end of the script running, instead of the beginning
if [ "$ShouldUpdate" = "true" ]; then
    updateOS
fi
