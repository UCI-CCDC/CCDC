#!/bin/bash
#Written by Charles Wu
echo "Make sure this is run in the same directory as the CCDC Repo"
echo "==========Installing Basic Dependencies=========="
mkdir offline-gen-dependencies
tar xzvf offline-gen-dependencies.tgz -C offline-gen-dependencies
dpkg -i offline-gen-dependencies/*.deb
dpkg -i offline-gen-dependencies/*.deb
echo "========== Deploying Ansible =========="
tar xzvf ansible-dl.tgz
dpkg -i ansible-dl/*.deb

echo "========== Deploying Wazuh =========="
#locate all 4 files
MANAGER_PATH=$(find / -name wazuh-manager_4.3.9-1_debian_amd64.deb)
DASHBOARD_PATH=$(find / -name wazuh-dashboard_4.3.9-1_amd64.deb)
INDEXER_PATH=$(find / -name wazuh-indexer_4.3.9-1_amd64.deb)
MANAGER2_PATH=$(find / -name wazuh-manager_4.3.9-1_amd64.deb)
FILEBEAT_PATH=$(find / -name filebeat-oss-7.10.2-amd64.deb)
#install 1 by 1
echo MANAGER PATH + $MANAGER_PATH
dpkg -i $MANAGER_PATH
dpkg -i $DASHBOARD_PATH
dpkg -i $INDEXER_PATH
dpkg -i $MANAGER2_PATH
dpkg -i $FILEBEAT_PATH


dpkg -i $MANAGER_PATH
dpkg -i $DASHBOARD_PATH
dpkg -i $INDEXER_PATH
dpkg -i $MANAGER2_PATH
dpkg -i $FILEBEAT_PATH

echo "========== Attempting to start Wazuh Services =========="
systemctl enable --now wazuh-manager.service
systemctl enable --now wazuh-indexer-performance-analyzer.service

systemctl enable --now wazuh-indexer.service
systemctl enable --now wazuh-dashboard.service


