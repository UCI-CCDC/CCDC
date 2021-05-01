#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
# UCI CCDC linux script to install our ansible base setup 
# onto a machine after it's been checked out by audit.sh

#Written by UCI CCDC linux subteam
#UCI CCDC, 2021
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

#functions to make shit prettier
banner () { printf "========================================================\n"; }

#before script execution, we need to be as sure as possible the machine is clean and secure
#centralization bad, but also good


