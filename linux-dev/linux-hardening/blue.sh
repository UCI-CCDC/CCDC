#!/bin/sh

HOSTNAME=$(hostname || cat /etc/hostname)
echo -e "HOST: $HOSTNAME"
echo "------------------"

if [ -n "$1" ]; then 
    REVERT=true
elif [ -n "$BBB" ]; then
    REVERT=true
else
    REVERT=false
fi

if [ "$REVERT" = true ]; then
    cp /opt/passwd.bak /etc/passwd
else
    cp /etc/passwd /opt/passwd.bak
    chmod 644 /opt/passwd.bak

    if ! which rbash >/dev/null ; then
        ln -sf /bin/bash /bin/rbash
    fi

    if command -v bash >/dev/null ; then
        head -1 /etc/passwd > /etc/pw
        sed -n '1!p' /etc/passwd | sed 's/\/bin\/.*sh$/\/bin\/rbash/g' >> /etc/pw
        mv /etc/pw /etc/passwd
        chmod 644 /etc/passwd
    fi

    for homedir in /home/* ; do 
        echo 'PATH=""' >> $homedir/.*shrc 
        echo 'export PATH' >> $homedir/.*shrc
        if command -v apk >/dev/null; then
            echo 'export PATH' >> $homedir/.profile
        fi
    done

    echo "ITS SO BLUE"
fi

sys=$(command -v service || command -v systemctl || command -v rc-service)

if [ "$REVERT" = true ]; then
    $sys cron start || $sys restart cron
    echo "cron started"
else
    $sys cron stop || $sys stop cron
    echo "cron stopped"
fi
