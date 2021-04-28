#!/bin/bash
#########################################################
# https://github.com/UCI-CCDC/CCDC2021
# script raw is at https://raw.githubusercontent.com/UCI-CCDC/CCDC2021/master/splunk-ent-install.sh
#UCI CCDC splunk server setup script

#Written by UCI CCDC linux subteam
#UCI CCDC, 2021
########################################################

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
