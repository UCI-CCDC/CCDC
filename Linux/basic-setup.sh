#!/bin/bash

########################################################
# https://github.com/UCI-CCDC/CCDC
# this is a trash script for a bunch of the auditing and hardening stuff i want to implement better later on. 
# basically a placeholder of the commands for now. 
# THIS SCRIPT WILL LIKELY BREAK THINGS

#Written by jbokor
#UCI CCDC, 2021
########################################################


if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!\n'
	exit 1
fi

# read -r -p "Are you sure? The harden script is currently non-functional, as of March 02 [Y/n] " response
# case "$response" in
#     [yY][eE][sS]|[yY]) 
#         wget https://raw.githubusercontent.com/UCI-CCDC/CCDC2020/master/harden.sh -O harden.sh && bash harden.sh
# 
#         ;;
#     *)
#         exit 1;;
# esac

################################
# bashrc setup
################################
# set root prompt to my default with red color
echo "export PS1='\[\e[31m\]\u@\h:\w\$ \[\e[0m\]'" >> /root/.bashrc
echo "alias sl='ls $LS_OPTIONS'" >> /root/.bashrc
echo "alias ll='ls $LS_OPTIONS -l'" >> /root/.bashrc
echo "alias la='ls $LS_OPTIONS -la'" >> /root/.bashrc
#echo "" >> /root/.bashrc

source /root/.bashrc

################################
# vim setup
################################
touch /root/.vimrc
echo "\" Basic vimrc " >> /root/.vimrc
# spaces instead of tabs
echo "set tabstop=4 shiftwidth=4 expandtab" >> /root/.vimrc
# syntax highlighting
echo "syntax on" >> /root/.vimrc
# fixes coloring issues that occur sometimes in ssh
echo "set background=dark" >> /root/.vimrc
# enables line numbering
echo "set number" >> /root/.vimrc
# prevents possible security issue
echo "set nomodeline" >> /root/.vimrc

echo ".bashrc and .vimrc updated"



# check if webmin is there

