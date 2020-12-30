#!/bin/bash

#testing

'''
        _________ ______
    ___/   \     V      \
   /  ^    |\    |\      \
  /_O_/\  / /    | ‾‾‾\  |
 //     \ |‾‾‾\_ |     ‾‾
//      _\|    _\|

      zot zot, thots.
'''

if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

log () { printf "\033[01;30m$(date +"%T")\033[0m: $1\n"; }

declare -a checkfiles=(~/.ssh/authorized_keys /root/.ssh/authorized_keys)

log "SYSTEM INFORMATION"
uname -a
lsb_release -a
cat /proc/version

## Fancy /etc/passwd
minid=$(grep "^UID_MIN" /etc/login.defs)
maxid=$(grep "^UID_MAX" /etc/login.defs)
printf "========================================================\n| Users List | Key: \033[01;34mUID = 0\033[0m, \033[01;32mUser\033[0m, \033[01;33mCan Login\033[0m, \033[01;31mNo Login\033[0m |\n========================================================\n"
awk -F':' -v minuid="${minid#UID_MIN}" -v maxuid="${maxid#UID_MAX}" '{
if ($7=="/bin/false" || $7=="/sbin/nologin") printf "\033[1;31m%s\033[0m\n", $1; 
else if ($3=="0") printf "\033[01;34m%s\033[0m\n", $1; 
else if ($3 >= minuid && $3 <= maxuid) printf "\033[01;32m%s\033[0m\n", $1; 
else printf "\033[01;33m%s\033[0m\n", $1; 
}' /etc/passwd | column

## /etc/group
printf "[  \033[01;35mUser\033[0m, \033[01;36mGroup\033[0m  ]\n" && grep "sudo\|adm\|bin\|sys\|uucp\|wheel\|nopasswdlogin\|root" /etc/group | awk -F: '{printf "\033[01;35m" $4 "\033[0m : \033[01;36m" $1 "\033[0m\n"}' | column
printf "To delete users/groups, use \033[01;30msudo userdel -r $user\033[0m and \033[01;30msudo groupdel $user\033[0m\n"

## /etc/sudoers
log "Sudoers"
sudo awk '!/#(.*)|^$/' /etc/sudoers

## Less Fancy /etc/shadow
log "Passwordless accounts: "
awk -F: '($2 == "") {print}' /etc/shadow # Prints accounts without passwords
echo;

log "IP Addresses:" # Okay I stole this one from Morgan, I'll make it prettier later
ip addr | awk '/^[0-9]+:/ { sub(/:/,"",$2); iface=$2 } /^[[:space:]]*inet / { split($2, a, "/"); print iface" : "a[1]; }'
printf "\n"

for i in ${checkfiles[@]}; do [ -s $i ] && log "\033[01;31mWARNING: $i HAS ACCESSIBLE INFORMATION\033[0m\n"; done

## Find world-writeable files
#log "List all world-writeable files?"
#read -n 1 -r; echo; if [[ $REPLY =~ ^[Yy]$ ]]; then find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print; fi

## Find no-owner files
log "List all no-owner files? (This will take a while!) Y/n"
read -n 1 -r; echo; if [[ $REPLY =~ ^[Yy]$ ]]; then find / -xdev \( -nouser -o -nogroup \) -print; fi

log "List all user files? Y/n"
read -n 1 -r; echo; if [[ $REPLY =~ ^[Yy]$ ]]; then grep -R /home; fi

log "Ports"
sudo ss -ln
printf "To close ports: \033[01;30msudo lsof -i :$port\033[0m, remember to kill the process with \033[01;30mkillall -9 $program\033[0m and remove.\n"

log "Cronjobs:"
sudo grep -R . /var/spool/cron/crontabs/
for user in $(cut -f1 -d: /etc/passwd); do crontab -u $user -l; done

log "Services:"
which service && service --status-all
which initctl && initctl list
which systemctl && systemctl list-unit-files --type service
which rc-status && rc-status --servicelist # Alpine
#ls /etc/init.d/
ls /etc/init/*.conf

systemctl list-unit-files --type service | grep enabled > servicesList.txt

watch -d systemctl list-timers
