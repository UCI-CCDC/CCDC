#!/usr/bin/env bash
### RUN BELOW SCRIPT TO DOWNLOAD
### wget -O splunk-8.0.2-a7f645ddaf91-Linux-x86_64.tgz 'https://splk.it/2TNfwRD'
###
groupadd splunk
useradd -d /opt/splunk -m -g splunk splunk
tar -xvf splunk-8.0.2-a7f645ddaf91-Linux-x86_64.tgz
cp -rp splunk/* /opt/splunk/
chown -R splunk: /opt/splunk
echo "set up splunk user and group"
echo "see part 3 of splunk in playbook"
