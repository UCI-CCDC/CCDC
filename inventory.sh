#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC2020
# script raw is at https://git.io/uciccdc20
# to install: wget https://git.io/uciccdc20 -O inv.sh && chmod +x inv.sh
#UCI CCDC linux script for inventory & common operations

#Written by UCI CCDC linux subteam
#UCI CCDC, 2020
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make shit prettier
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


#FINISH ME PLS
installPackages() {
    packages="sudo nmap tmux tshark vim hostname htop clamav"
    printf "this function will be used to install important/essential packages on barebones systems"
        if [ $(command -v apt-get) ]; then # Debian based
            apt-get install $packages -y -q

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


#below should both be false
ShouldUpdate=false
ShouldInstall=false

# this fucker is the flag statement
while getopts :huixnsr:m: option
do
case "${option}" in
h) 
    printf "\n UCI CCDC 2020 Linux Inventory Script\n"
    printf "Note: all flags other than the update functions will result in the main script not being run.\n"

    printf "    ==============Options==============\n"
    printf " -h     Prints this help menu\n"
    printf " -n     Runs Jacob's custom NMAP command\n"
    printf " -m     Runs custom NMAP command, but IP subnet must be passed as an argument (ex: -m 192.168.1.0)\n"
    printf " -x     Runs hardening script\n"
    printf " -u     Installs updates based on system version\n"
    printf " -i     Installs updates AND useful packages\n"
    printf " -s     Backups MYSQL databases and config files\n"
    printf " -r     Restore MYSQL database from backup tar archive (passed as argument)\n"

    printf "\n\n\n"
    exit 1;;
u) 
    ShouldUpdate=true
    ;;
i) 
    ShouldUpdate=true
    ShouldInstall=true
    ;;

x)
    harden          #calls hardening function above
    exit 1;;

n) 
    printf "Running NMAP command, text and visual xml output created in current directory"
    nmap -p- -Anvv -T4 -oN nmapOut.txt -oX nmapOutVisual.xml $(hostname -I | awk '{print $1}')/24
    exit 1;;

m) 
    printf "Running NMAP command with user specificed subnet, text and visual xml output created in current directory"
    nmap -p- -Anvv -T4 -oN nmapOut.txt -oX nmapOutVisual.xml $OPTARG/24
    exit 1;;

s)
    printf "Backing up MYSQL databases and config files\n"
    
    mkdir -p $HOME/sql-backup
        
    read -s -p "Enter root password for mysql database  " pass
    for db in $(mysql -u root -p$pass -e 'show databases' --skip-column-names); do
        mysqldump -u root -p$pass "$db" > "$HOME/sql-backup/$db.sql"
    done
    cp  -r /etc/mysql /$HOME/sql-backup/
    tar -czf $HOME/$HOSTNAME-sqlbackup.tgz $HOME/sql-backup

    exit 1;;

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


#both of these are error handling. The top one handles incorrect flags, the bottom one handles when no argument is passed for a flag that requires one
\?) echo "incorrect syntax, use -h for help"
    exit 1;;

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

      zot zot, thots.'


#generate inv directory, audit.txt, and set up variables for redirection
printf "\n*** generating inv direcory and audit.txt in your root home directory\n"
mkdir $HOME/inv/ >&/dev/null;       #creates directory; stderr is redirected in the case that directory already exists
outFile="$HOME/inv/audit-$(hostname).txt"
touch outFile
adtfile="tee -a $HOME/inv/audit-$(hostname).txt"



echo -e "\n\e[92m"
echo "Hostname: $(hostname)" | $adtfile
echo -e "\e[0m"

echo "Date: $(date)" >> $outFile

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


# I stole this from jordan
minid=$(grep "^UID_MIN" /etc/login.defs || echo 1000)n
maxid=$(grep "^UID_MAX" /etc/login.defs || echo 60000)
printf "========================================================\n| Users List | Key: \033[01;34mUID = 0\033[0m, \033[01;32mUser\033[0m, \033[01;33mCan Login\033[0m, \033[01;31mNo Login\033[0m |\n========================================================\n"
awk -F':' -v minuid="${minid#UID_MIN}" -v maxuid="${maxid#UID_MAX}" '{
if ($7=="/bin/false" || $7=="/sbin/nologin") printf "\033[1;31m%s\033[0m\n", $1; 
else if ($3=="0") printf "\033[01;34m%s\033[0m\n", $1; 
else if ($3 >= minuid && $3 <= maxuid) printf "\033[01;32m%s\033[0m\n", $1; 
else printf "\033[01;33m%s\033[0m\n", $1; 
}' /etc/passwd | column

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

#saves services to variable, prints them out to terminal in blue
printf '\n***services you should cry about***\n'
services=$(ps aux | grep -i 'docker\|samba\|postfix\|dovecot\|smtp\|psql\|ssh\|clamav\|mysql\|bind9\|apache\|smbfs\|samba\|openvpn\|splunk' | grep -v "grep")
echo -e "\e[34m"
echo "Services on this machine:" >> $outFile
echo $services | $adtfile
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



# this string prints the current system time and date "\033[01;30m$(date)\033[0m: %s\n"
