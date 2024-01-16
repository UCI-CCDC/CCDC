#!/usr/bin/env python

import dominion
import random 
import printer
import utils

def change_all_root_passwords(data: dict) -> None:
    for ip, (username, password, port) in data.items():

        # get random password from passwords.db
        pass_data = get_random_password()
        pass_num, new_password = pass_data[0], pass_data[1]

        # change password on remote host
        try: 
            utils.run_script(ip, username, password, port, "../linux-toolbox/pass_for.sh", utils.map_args_to_env_vars([username, new_password]))
        except:
            printer.message(f"Failed to change {username}'s password on {ip} to {new_password} ({pass_num}) | port: {port}", dominion.ERROR)
            utils.log(f"Failed to change {username}'s password on {ip} to {new_password} ({pass_num}) from {password} | port: {port}")
            continue

        if utils.yes_or_no(f"Did the script run successfully?"): 
            printer.message(f"Changed {username}'s password on {ip} to {new_password} ({pass_num}) | port: {port}", dominion.SUCCESS)
            utils.log(f"Changed {username}'s password on {ip} to {new_password} ({pass_num}) from {password} | port: {port}")
            update_password_in_config(ip, username, new_password, port)
            remove_used_password(new_password)
        else:
            printer.message(f"Failed to change {username}'s password on {ip} to {new_password} ({pass_num}) | port: {port}", dominion.ERROR)
            utils.log(f"Failed to change {username}'s password on {ip} to {new_password} ({pass_num}) from {password} | port: {port}")

def get_random_password() -> str:
    with open(dominion.PASSWORDS_DB, 'r') as file:
        passwords = file.readlines()

    if passwords:
        selected_password = random.choice(passwords)
        return selected_password.split(',')[0].strip(), selected_password.split(',')[1].strip()
    else:
        utils.log("No passwords available in passwords.db")
        raise ValueError("No passwords available in passwords.db")


def remove_used_password(used_password: str) -> None:
    with open(dominion.PASSWORDS_DB, 'r') as file:
        lines = file.readlines()

    with open(dominion.PASSWORDS_DB, 'w') as file:
        for line in lines:
            if line.strip().split(',')[1] == used_password:
                continue
            file.write(line)

def update_password_in_config(ip: str, username: str, password: str, port: int) -> None:
    with open(dominion.IP_USER_MAP, 'r') as file:
        lines = file.readlines()

    for i, line in enumerate(lines):
        if line.strip().startswith('#'):
            continue

        parts = line.split()
        if len(parts) == 4 and parts[0] == ip and parts[1] == username and parts[3] == str(port):
            lines[i] = f"{ip} {username} {password} {str(port)}\n"


    with open(dominion.IP_USER_MAP, 'w') as file:
        file.writelines(lines)
