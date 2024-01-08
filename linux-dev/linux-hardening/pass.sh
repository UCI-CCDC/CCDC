#!/usr/bin/env bash

while IFS=: read -r username _ uid _; do
    if [ "$uid" -ge 1000 ]; then #if uid is greater than or equal to 1000
        newpass=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "15") # make a random password
	    echo "$username,$newpass"
        if command -v chpasswd >/dev/null 2>&1; then
            echo "$username:$password" | chpasswd
        else
            printf "%s\n%s\n" "$password" "$password" | passwd "$username"
        fi

    fi
done < /etc/passwd