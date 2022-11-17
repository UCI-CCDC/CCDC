#!/bin/bash
# Wazuh - Yara active response
# Copyright (C) 2015-2022, Wazuh Inc.
#
# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.
#------------------------- Gather parameters -------------------------#

# Static active response parameters
LOCAL=`dirname $0`

# Extra arguments
read -r INPUT_JSON
YARA_PATH=$(echo $INPUT_JSON | jq -r .parameters.extra_args[1])
YARA_RULES=$(echo $INPUT_JSON | jq -r .parameters.extra_args[3])
FILENAME=$(echo $INPUT_JSON | jq -r .parameters.alert.syscheck.path)
COMMAND=$(echo $INPUT_JSON | jq -r .command)

# Move to the active response folder
cd $LOCAL
cd ../

# Set LOG_FILE path
PWD=`pwd`
LOG_FILE="${PWD}/../logs/active-responses.log"

#----------------------- Analyze parameters -----------------------#

if [[ ! $YARA_PATH ]] || [[ ! $YARA_RULES ]]
then
  echo "wazuh-yara: ERROR - Yara active response error. Yara path and rules parameters are mandatory." >> ${LOG_FILE}
  exit
fi

#------------------------ Analyze command -------------------------#
if [ ${COMMAND} = "add" ]
then
  # Send control message to execd
  printf '{"version":1,"origin":{"name":"yara","module":"active-response"},"command":"check_keys", "parameters":{"keys":[]}}\n'

  read RESPONSE
  COMMAND2=$(echo $RESPONSE | jq -r .command)
  if [ ${COMMAND2} != "continue" ]
  then
    echo "wazuh-yara: INFO - Yara active response aborted." >> ${LOG_FILE}
    exit 1;
  fi
fi

#------------------------- Main workflow --------------------------#

# Execute Yara scan on the specified filename
yara_output="$("${YARA_PATH}"/yara -w -r "$YARA_RULES" "$FILENAME")"

if [[ $yara_output != "" ]]
then
  # Iterate every detected rule and append it to the LOG_FILE
  while read -r line; do
  echo "wazuh-yara: INFO - Scan result: $line" >> ${LOG_FILE}
  done <<< "$yara_output"
fi

exit 1;

