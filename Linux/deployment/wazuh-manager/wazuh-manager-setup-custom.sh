#!/bin/bash

# basic setup of wazuh manager machine
# run this AFTER installing wazuh manager
# this might end up in an ansible playbook, idk


echo "setting up wazuh manager configuration"

echo "copying over custom rules"
cp files/local_rules.xml /var/ossec/etc/rules/local_rules.xml

echo "adding agent.conf to configuration"
cp files/agent.conf /var/ossec/etc/shared/default/agent.conf

echo "adding correct permissions to agent.conf"
chown ossec:ossec /var/ossec/etc/shared/default/agent.conf
chmod 640 /var/ossec/etc/shared/default/agent.conf

echo "copying suspicious-programs"
cp files/suspicious-programs /var/ossec/etc/lists/suspicious-programs

echo "modifying server ossec.conf file with location of suspicious-programs"
if ! test -f "/var/ossec/etc/backup_ossec.conf"; then
    echo "ossec not backed up; this should be first exec of script"
    mv /var/ossec/etc/ossec.conf /var/ossec/etc/backup_ossec.conf
    awk '/<ruleset>/ {$0=$0"\n    <list>etc/lists/suspicious-programs</list>"}1' backup_ossec.conf > ossec.conf
else
    echo "we've already modified it, nevermind"
fi


read -r -p "do you want to restart the wazuh-manager process?: " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        systemctl restart wazuh-manager
        ;;
    *)
        echo "ok bye then"
        exit 0;;
esac
