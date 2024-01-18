#!/usr/bin/env python

import dominion
import printer
import time
import os 

def clean_log() -> None:
    with open(dominion.LOG_FILE, 'w') as file:
        file.write('')
    file.close()

def die(type: str) -> None:
    if type == dominion.ERROR:
        printer.message("Exiting...", dominion.ERROR)
        raise SystemExit(1)
    else:
        printer.message("Exiting...", dominion.SUCCESS)
        raise SystemExit(0)

def log(string: str) -> None:
    current_time = time.localtime()

    with open(dominion.LOG_FILE, 'a') as file:
        file.write(f'[LOG-{time.strftime("%H:%M:%S", current_time)}] {string}' + '\n')
    file.close()

def run_script(ip: str, username: str, password: str, port: int, script: str, env_vars=None) -> None:
    if env_vars:
        os.system(f"{dominion.BINARY} -t {ip} -u {username} -p {password} -E {env_vars} -P {port} -T 60 -R -S -y {script}")
    else:
        os.system(f"{dominion.BINARY} -t {ip} -u {username} -p {password} -P {port} -T 60 -R -S -y {script}")

def run_script_against_all_hosts(script: str) -> None:
    data = read_all()
    for ip, (username, password, port) in data.items():
        run_script(ip, username, password, port, script)

def read_all() -> dict:
    data = {}
    with open(dominion.IP_USER_MAP, 'r') as file:
        for line in file:
            if line.strip().startswith('#'):
                continue

            host, username, password, port = line.split()
            data[host] = (username, password, port)
    file.close()
    return data

def map_args_to_env_vars(args: list) -> str:
    alphabet = [x for x in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    env_vars = ""
    for n, arg in enumerate(args): env_vars += f"{alphabet[n]*3}={arg},"
    return env_vars[:-1]

def is_host_in_config(ip: str) -> bool:
    data = read_all()
    if ip in data:
        return True
    else:
        return False

def yes_or_no(question: str) -> bool:
    while True:
        reply = str(input(question+' (y/n): ')).lower().strip()
        if reply[:1] == 'y':
            return True
        if reply[:1] == 'n':
            return False

def interactive_add_host(ip=None, username=None, password=None, port=None) -> None:
    if ip == None: ip = input("Enter host IP: ")
    if username == None: username = input("Enter username: ")
    if password == None: password = input("Enter password: ")
    if port == None: port = input("Enter port: ")
    add_host(ip, username, password, port)
    return (ip, username, password, port)

def add_host(ip: str, username: str, password: str, port: int) -> None:
    with open(dominion.IP_USER_MAP, 'a') as file:
        file.write(f"{ip} {username} {password} {str(port)}\n")
    file.close()

def execute(exec_string: str) -> None:
    script, hosts, env_vars = None, None, None
    script = exec_string.split(':')[0]
    hosts = exec_string.split(':')[1].split(',')
    if len(exec_string.split(':')) == 3:
        env_vars = exec_string.split(':')[2].split(',')

    for host in hosts:
        data = read_all()
        if is_host_in_config(host):
            ip, (username, password, port) = host, data[host]
            if env_vars:
                printer.message(f"Executing '{script}' on {ip} with ({map_args_to_env_vars(env_vars)}) using {username}/{password} | port: {port}")
                run_script(ip, username, password, port, script, map_args_to_env_vars(env_vars))
            else:
                printer.message(f"Executing '{script}' on {ip} using {username}/{password} | port: {port}")
                run_script(ip, username, password, port, script)
        else:
            printer.message(f"Host {host} not found in {dominion.IP_USER_MAP}", dominion.ERROR)
            if yes_or_no(f"Add {host} to {dominion.IP_USER_MAP}?"):
                ip, username, password, port = interactive_add_host(host)
                if env_vars:
                    printer.message(f"Executing '{script}' on {ip} with ({map_args_to_env_vars(env_vars)}) using {username}/{password} | port: {port}")
                    run_script(ip, username, password, port, script, map_args_to_env_vars(env_vars))
                else:
                    printer.message(f"Executing '{script}' on {ip} using {username}/{password} | port: {port}")
                    run_script(ip, username, password, port, script)
            else: 
                continue
