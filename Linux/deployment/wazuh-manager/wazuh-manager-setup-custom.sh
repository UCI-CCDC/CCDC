#!/bin/bash

# basic setup of wazuh manager machine
# run this AFTER installing wazuh manager
# this might end up in an ansible playbook, idk


echo "setting up wazuh manager configuration"

echo "copying over custom rules"
cp files/local_rules.xml /var/ossec/ruleset/rules/local_rules.xml

echo "adding agent.conf to configuration"
cp files/agent.conf /var/ossec/etc/shared/default/agent.conf

echo "adding correct permissions to agent.conf"
chown ossec:ossec /var/ossec/etc/shared/default/agent.conf
chmod 640 /var/ossec/etc/shared/default/agent.conf

cp files/suspicious-programs.txt /var/ossec/etc/lists/suspicious-programs.txt

read -r -p "do you want to restart the wazuh-manager process?" response
case "$response" in
    [yY][eE][sS]|[yY]) 
        systemctl restart wazuh-manager
        ;;
    *)
        echo "ok bye then"
        exit 0;;
esac
