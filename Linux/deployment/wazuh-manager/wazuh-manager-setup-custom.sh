#!/bin/bash

# basic setup of wazuh manager machine


read -r -p "ARE THE CONFIG FILES EXACTLY HOW YOU WANT THEM?: " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        break
        ;;
    *)
        echo "fix them and come back soon"
        exit 0;;
esac

# start actual script
echo "setting up wazuh manager configuration"

echo "copying over custom rules"
cp files/local_rules.xml /var/ossec/etc/rules/local_rules.xml

echo "adding agent.conf to configuration"
cp files/agent.conf /var/ossec/etc/shared/default/agent.conf

echo "adding correct permissions to agent.conf"
chown wazuh:wazuh /var/ossec/etc/shared/default/agent.conf
chmod 640 /var/ossec/etc/shared/default/agent.conf

echo "copying suspicious-programs list to location"
cp files/suspicious-programs /var/ossec/etc/lists/suspicious-programs

echo "modifying server ossec.conf file with location of suspicious-programs"
if ! test -f "/var/ossec/etc/backup_ossec.conf"; then
    echo "ossec not backed up yet; this should be first exec of script"
    mv /var/ossec/etc/ossec.conf /var/ossec/etc/backup_ossec.conf
    cp /var/ossec/etc/backup_ossec.conf /root/backup_ossec-$(date +"%H:%M").conf
    awk '/<ruleset>/ {$0=$0"\n    <list>etc/lists/suspicious-programs</list>"}1' /var/ossec/etc/backup_ossec.conf > /var/ossec/etc/ossec.conf
else
    echo "we've already modified it, nevermind"
fi

# https://documentation.wazuh.com/current/user-manual/capabilities/system-calls-monitoring/audit-configuration.html
echo "adding custom audit cdb keys to /var/ossec/etc/lists/audit-keys"
if ! test -f "/root/.audit-keys-old"; then
    echo "audit-keys haven't been updated yet! updating now"
    cp /var/ossec/etc/lists/audit-keys /root/.audit-keys-old
    cat files/audit-keys >> /var/ossec/etc/lists/audit-keys
else
    echo "we've already added our cdb keys, nevermind"
fi

echo "install packages that help in troubleshooting"
apt-get install tree -y

echo "\n\n"
read -r -p "Do you want to restart the wazuh-manager process?: " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        systemctl restart wazuh-manager
        ;;
    *)
        echo "ok bye then"
        exit 0;;
esac
