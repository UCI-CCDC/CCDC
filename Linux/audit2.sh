#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
#UCI CCDC linux script for inventory & common operations

#Written by UCI CCDC linux subteam
#UCI CCDC, 2022
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make shit prettier
banner () { printf "========================================================\n"; }

# add other files that need backup here
COMMON_CONFIG_PATHS=("~/var/www/html" "~/etc/nginx" "pam")


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


#FINISH ME PLS
installPackages() {
    #packages to install, independent of package manager
    packages="sudo nmap tmux tree vim hostname htop clamav lynis"

    printf "this function will be used to install important/essential packages on barebones systems"
        if [ $(command -v apt-get) ]; then # Debian based
            apt-get install $packages -y -q
            #debian only packages
            apt-get install debsums
        elif [ $(command -v yum) ]; then
            yum -y install $packages 
        elif [ $(command -v pacman) ]; then 
            yes | pacman -S $packages
        elif [ $(command -v apk) ]; then # Alpine
            apk update
            apk upgrade
            apk add bash vim man-pages mdocml-apropos bash-doc bash-completion util-linux pciutils usbutils coreutils binutils findutils attr dialog dialog-doc grep grep-doc util-linux-doc pciutils usbutils binutils findutils readline lsof lsof-doc less less-doc nano nano-doc curl-doc 
            apk add $packages
        fi
}

scannmap() {
    # Downloads and runs scan.sh
    printf "Now downloading and running scan.sh for nmap scans\n"

    wget https://raw.githubusercontent.com/UCI-CCDC/CCDC/master/Linux/scan.sh -O scan.sh
    echo ""
    chmod +x scan.sh
    bash scan.sh
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
ShouldInstall=false

# To see if this is the first time running the script.
# Useful for backing up config directories.
[[ ! -e ./auditlog.log ]] && touch auditlog.log && echo 0 > auditlog.log # This is only 0 temporarily if the log didn't exist yet.
timesRun=$(echo $(head -n 1 "./auditlog.log") + 1 | bc -l) #this line has errors
echo $timesRun > auditlog.log

# this is the flag statement
while getopts :huixnsar:m: option
do
case "${option}" in
h) 
    printf "\n UCI CCDC 2020 Linux Inventory Script\n"
    printf "Note: all flags other than the update functions will result in the main script not being run.\n"

    printf "    ==============Options==============\n"
    printf " -h     Prints this help menu\n"
    printf " -n     Downloads and runs NMAP script (scan.sh)\n"
    printf " -j     Runs Jacob's custom NMAP command\n"
    printf " -m     Runs custom NMAP command, but IP subnet must be passed as an argument (ex: -m 192.168.1.0)\n"
    printf " -u     Installs updates based on system version\n"
    printf " -i     Installs updates AND useful packages\n"
    printf " -s     Backups MYSQL databases and config files\n"
    printf " -r     Restore MYSQL database from backup tar archive (passed as argument)\n"
    printf " -d     Runs Debsums to check file validity on debian based systems\n"
    printf " -a     Downloads and runs ansible installation and setup script\n"

    printf "\n\n\n"
    exit 1;;
u) 
    ShouldUpdate=true
    ;;
i) 
    ShouldUpdate=true
    ShouldInstall=true
    ;;

#download and run scan.sh
n)
    scannmap
    exit 1;;

#automatic nmap scan - goes to invalid syntax instead of here
j) 
    printf "Running NMAP command, text and visual xml output created in current directory"
    nmap -p- -Anvv -T4 -oN nmapOut.txt -oX nmapOutVisual.xml $(hostname -I | awk '{print $1}')/24
    exit 1;;

#nmap with manual ip specification
m) 
    printf "Running NMAP command with user specificed subnet, text and visual xml output created in current directory"
    nmap -p- -Anvv -T4 -oN nmapOut.txt -oX nmapOutVisual.xml $OPTARG/24
    exit 1;;

#mysql backup flag
s)
    printf "Backing up MYSQL databases and config files\n"
    # Config File Backups
    [[ $timesRun == 1 ]] && backup_config_dirs COMMON_CONFIG_PATHS  # backup if this is the first time running audit.sh

    # SQL backups    
    mkdir -p $HOME/sql-backup
        
    read -s -p "Enter root password for mysql database  " pass
    for db in $(mysql -u root -p$pass -e 'show databases' --skip-column-names); do
        mysqldump --skip-lock-tables -u root -p$pass "$db" > "$HOME/sql-backup/$db.sql"
    done
    cp  -r /etc/mysql /$HOME/sql-backup/
    tar -czf $HOME/$HOSTNAME-sqlbackup.tgz $HOME/sql-backup

    exit 1;;

#mysql restore flag
r)
    printf "Restoring MYSQL database from $OPTARG \n"
    #sql database recovery, not yet verified to work
    
    read -s -p "Enter root pass: " pass
    printf "\n"
    mkdir restore-sql

    tar -xzf "$OPTARG" -C restore-sql/
    for db in $(find restore-sql/ -name *.sql); do
        bdb=$(basename $db)
        mysql -u root -p$pass -e "create database ${bdb%.sql};"
        mysql -u root -p$pass ${bdb%.sql} < "$db"
    done

    exit 1;;

#debsums flag - goes to invalid syntax instead of here
d)
    printf "Checking file validity using debsums"

    apt install -y debsums

    echo "File validity output of debsums" >> $outFile
    debsums -c | $adtfile
    exit 1;;

a)
    printf "Ansible flag selected, fetching Ansible script\n\n"

# this block of commented code will check if the harden script has been run on the machine. 
#   if not, it'll ask the user if they want to run it, and then download it and run it. 
#   it's a good idea to have something like this here bc the management machine needs to be 
#   as secure as possible. 
#
#    if ! test -f "/root/inv/harden-$(hostname)"; then
#        printf "as of May 1, 2021 harden script is not functional. Don't say yes yet.\n"
#        printf "or do, I dare you\n"
#        read -r -p "Looks like harden script has not been called yet. Calling it first is HIGHLY recommended. Would you like to call that now? [Y/n]: " response
#        case "$response" in
#            [yY][eE][sS]|[yY]) 
#                wget https://raw.githubusercontent.com/UCI-CCDC/CCDC2021/master/harden.sh -O harden.sh && \
#                bash harden.sh
#
#                ;;
#            *)
#                ;;
#        esac
#        printf "\n"
#    fi

    #download ansible script
    wget https://raw.githubusercontent.com/UCI-CCDC/CCDC/master/Linux/deployment/ansible-setup.sh
    echo ""
    chmod +x ansible-setup.sh
    bash ansible-setup.sh

    printf "\nExiting audit script now\n"
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
outFile="$HOME/inv/audit-$(hostname).txt"
adtfile="tee -a /root/inv/audit-$(hostname).txt"



echo -e "\n\e[92m"
echo "Hostname: $(hostname)" | $adtfile
echo -e "\e[0m"

echo "Date: $(date)" >> $outFile

# this is not compatible with distros that don't use the os-release file; /etc/*release would make it compatible, but I am not sure about 
# the validity of the formatting
osOut=$(cat /etc/os-release | grep -w "PRETTY_NAME" | cut -d "=" -f 2)

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


minid=$(grep "^UID_MIN" /etc/login.defs || echo 1000)n
maxid=$(grep "^UID_MAX" /etc/login.defs || echo 60000)
printf "========================================================\n| Users List | Key: \033[01;34mUID = 0\033[0m, \033[01;32mUser\033[0m, \033[01;33mCan Login\033[0m, \033[01;31mNo Login\033[0m |\n========================================================\n"
awk -F':' -v minuid="${minid#UID_MIN}" -v maxuid="${maxid#UID_MAX}" '{
if ($7=="/bin/false" || $7=="/sbin/nologin") printf "\033[1;31m%s\033[0m\n", $1; 
else if ($3=="0") printf "\033[01;34m%s\033[0m\n", $1; 
else if ($3 >= minuid && $3 <= maxuid) printf "\033[01;32m%s\033[0m\n", $1; 
else printf "\033[01;33m%s\033[0m\n", $1; 
}' /etc/passwd | column

#look for users in listed groups
printf "\n[  \033[01;35mUser\033[0m, \033[01;36mGroup\033[0m  ]\n" && grep "sudo\|adm\|bin\|sys\|uucp\|wheel\|nopasswdlogin\|root" /etc/group | awk -F: '{printf "\033[01;35m" $4 "\033[0m : \033[01;36m" $1 "\033[0m\n"}' | column

# ## Less Fancy /etc/shadow
echo -e "\n\e[93m***Passwordless accounts***\e[0m\n"
awk -F: '($2 == "") {print}' /etc/shadow # Prints accounts without passwords

echo -e "\n\e[93m***USERS IN SUDO GROUP***\e[0m\n"
echo "Users in sudo group:" >> $outFile
grep -Po '^sudo.+:\K.*$' /etc/group | $adtfile

printf "\n\e[93m***USERS IN ADMIN GROUP***\e[0m\n"
echo "Users in Admin Group:" >> $outFile
grep -Po '^admin.+:\K.*$' /etc/group | $adtfile

printf "\n\e[93m***USERS IN WHEEL GROUP***\e[0m\n"
echo "Users in Wheel Group:" >> $outFile
grep -Po '^wheel.+:\K.*$' /etc/group | $adtfile

printf "\n\e[35mCrontabs\e[0m\n"
sudo grep -R . /var/spool/cron/crontabs/
for user in $(cut -f1 -d: /etc/passwd); do crontab -u "$user" -l 2> >(grep -v 'no crontab for'); done

# we should be using lsof -i here, but again, no idea if it is compatible
#saves services to variable, prints them out to terminal in blue
printf '\n***services you should cry about***\n'
services=$(ps aux | grep -i 'docker\|samba\|postfix\|dovecot\|smtp\|psql\|ssh\|clamav\|mysql\|bind9\|apache\|smbfs\|samba\|openvpn\|splunk\|nginx\|mysql\|mariadb\|ftp\|slapd\|amavisd\|wazuh' | grep -v "grep")
echo -e "\e[34m"
echo "Services on this machine:" >> $outFile
echo "$services" | $adtfile
echo -e "\e[0m" #formatting so audit file is less fucked with the color markers

banner >> $outFile
printf "\n\n" >> $outFile


#these if statements make sure that updates are executed at the end of the script running, instead of the beginning
if [ "$ShouldUpdate" = "true" ]; then
    updateOS
fi

if [ "$ShouldInstall" = "true" ]; then
    installPackages
fi

