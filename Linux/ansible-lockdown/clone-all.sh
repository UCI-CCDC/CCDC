#!/bin/bash
#
# clone all relevant git repos automatically & remove their git directories

git clone https://github.com/ansible-lockdown/RHEL7-CIS
git clone https://github.com/ansible-lockdown/RHEL8-CIS
git clone https://github.com/ansible-lockdown/UBUNTU18-CIS
git clone https://github.com/ansible-lockdown/UBUNTU20-CIS
git clone https://github.com/ansible-lockdown/APACHE-2.4-CIS
git clone https://github.com/ansible-lockdown/POSTGRES-12-CIS

# remove all git repository files from each dir
find . -name ".git" | xargs rm -rf
