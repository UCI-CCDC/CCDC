#!/bin/bash
########################################################
# https://github.com/UCI-CCDC/CCDC2020
# script raw is at https://raw.githubusercontent.com/UCI-CCDC/CCDC2021/master/makeforwarder.sh
#UCI CCDC setup script for splunk client setup 

#Written by UCI CCDC linux subteam
#UCI CCDC, 2021
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

if [[ $# -lt 1 ]]; then
	printf 'Must specify a forward-server! (This is the server Splunk-enterprise is on)\nex: sudo ./makeforwarder.sh 192.168.0.5'
	exit 1
fi

# Install Splunk
wget -O splunkforwarder-8.0.2-a7f645ddaf91-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.2&product=universalforwarder&filename=splunkforwarder-8.0.2-a7f645ddaf91-Linux-x86_64.tgz&wget=true'
tar -xzvf splunkforwarder-8.0.2-a7f645ddaf91-Linux-x86_64.tgz -C /opt
cd /opt/splunkforwarder/bin
./splunk start --accept-license # User will have to input creds here

./splunk add forward-server "$1":9997 # User will have to input the same creds here
./splunk set deploy-poll "$1":8089 # User will have to input the same creds here

# Recommended Splunk Configs
if [ -f /var/log/syslog ]; then
    ./splunk add monitor /var/log/syslog
fi
if [ -f /var/log/messages ]; then
    ./splunk add monitor /var/log/messages
fi
if [ -d /var/log/apache ]; then
    ./splunk add monitor /var/log/apache/access.log
    ./splunk add monitor /var/log/apache/error.log
fi

# Add Splunk user
useradd -d /opt/splunkforwarder splunk
groupadd splunk
usermod -a -G splunk splunk

# Set Splunk to start as Splunk user
./splunk enable boot-start -user splunk
#which systemd && ./splunk enable boot-start -systemd-managed 1 -user splunk 
chown -R splunk /opt/splunkforwarder

sed -i 's/"$SPLUNK_HOME\/bin\/splunk" start --no-prompt --answer-yes/su - splunk -c '\''"$SPLUNK_HOME\/bin\/splunk" start --no-prompt --answer-yes'\''/g' /etc/init.d/splunk
sed -i 's/"$SPLUNK_HOME\/bin\/splunk" stop/su - splunk -c '\''"$SPLUNK_HOME\/bin\/splunk" stop'\''/g' /etc/init.d/splunk
sed -i 's/"$SPLUNK_HOME\/bin\/splunk" restart/su - splunk -c '\''"$SPLUNK_HOME\/bin\/splunk" restart'\''/g' /etc/init.d/splunk
sed -i 's/"$SPLUNK_HOME\/bin\/splunk" status/su - splunk -c '\''"$SPLUNK_HOME\/bin\/splunk" status'\''/g' /etc/init.d/splunk

su - splunk -c '/opt/splunkforwarder/bin/splunk restart'
