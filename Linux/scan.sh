#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    printf 'Must be run as root, exiting!\n'	
    exit 1
fi

if [[ $# != 1 ]]; then 
    echo "Usage: $0 [subnet]"
    echo "Example: $0 10.0.2.1/24"
    exit 1
fi

rm -rf nmap
mkdir nmap && cd nmap
mkdir xml

echo "[*] Starting Nmap scan for live hosts..."
nmap -v0 -sn -n --open -oN hosts -T5 $1

echo "[*] Cleaning up live hosts..."
grep "for" hosts | cut -d " " -f 5 >> live_hosts.txt

echo "[*] Starting Nmap fast default scan on live hosts..."
nmap -v0 -F -n --open -oN scan_default -oX xml/scan_default.xml -T5 --osscan-limit --max-os-tries 1 -iL live_hosts.txt

read -p "[?] Start Aggressive scan? [y/N] " agg_scan
if [[ -z $agg_scan ]]; then 
    agg_scan="n"
fi

if [[ $agg_scan == "y" ]]; then
    echo "[*] Starting Nmap aggressive scan on live hosts..."  
    nmap -v -A -n -oN scan_aggressive -oX xml/scan_aggressive.xml -T5 -iL live_hosts.txt
fi

check_deps() {
    echo "[*] Checking dependencies for Webmap..."
# TO-DO: check for docker
}

read -p "[?] Start webmap? [Y/n] " start_webmap 

if [[ -z $start_webmap ]]; then
    start_webmap="y"
fi

if [[ $start_webmap == "y" ]]; then
    check_deps
    echo "[*] Starting webmap..."
    docker kill webmap 2>/dev/null
    docker rm webmap 2>/dev/null
    docker run -d --name webmap -h webmap -p 8000:8000 -v $PWD/xml:/opt/xml reborntc/webmap
    echo "[+] Proceed to http://localhost:8000"
    echo "[*] Generating webmap token..."
    docker exec -ti webmap /root/token
fi
