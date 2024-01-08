#!/usr/bin/env bash

sys=$(command -v service)
if [[ $? -ne 0 ]]; then
  sys=$(command -v systemctl)
  if [[ $? -ne 0 ]]; then
    sys="/etc/rc.d/sshd"
    cmd="none"
  else
    cmd="systemctl"
  fi
else
  cmd="service"
fi

sed -i -E '/PubkeyAuthentication yes/d' /etc/ssh/sshd_config
sed -i -E '/PermitEmptyPasswords yes/d' /etc/ssh/sshd_config
sed -i -E '/PubkeyAuthentication no/d' /etc/ssh/sshd_config
sed -i -E '/PermitEmptyPasswords no/d' /etc/ssh/sshd_config
echo "PubkeyAuthentication no" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

if [[ "$(tail -1 /etc/ssh/sshd_config)" == "PermitEmptyPasswords no" ]] && [[ "$(tail -2 /etc/ssh/sshd_config | head -1)" == "PubkeyAuthentication no" ]]; then
  echo "Successfully changed config files"
else
  echo "Did not properly change config files"
fi
if [[ "${cmd}" == "systemctl" ]]; then
  $sys restart ssh 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "Successfully restarted ssh"
  else
    $sys restart sshd 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "Successfully restarted sshd"
    else
      echo "systemctl could not restart sshd/ssh"
    fi
  fi
elif [[ "${cmd}" == "service" ]]; then
  $sys ssh restart 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "Successfully restarted ssh"
  else
    $sys sshd restart 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "Successfully restarted ssh"
    else
      echo "service could not restart sshd/ssh"
    fi
  fi
else
  $sys restart 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "/etc/rc.d/sshd successfully restarted ssh"
  else
    echo "/etc/rc.d/sshd could not restart ssh"
  fi
fi