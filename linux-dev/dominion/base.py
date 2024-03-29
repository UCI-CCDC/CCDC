#!/usr/bin/env python

import dominion
import printer
import utils

def initial_base_across_boxes(data: dict):
    IB_BACKUP_PATH = input("Enter the path to backup the initial base to (e.g /etc/backup/): ")
    QUIET = utils.yes_or_no("Do you want to run this in quiet mode? (y/n): ")
    
    for ip, (username, password, port) in data.items():
        if QUIET:
            utils.run_script(ip, username, password, port, "../linux-toolbox/initial_base.sh", utils.map_args_to_env_vars([IB_BACKUP_PATH, "QUIET"]))
        else:
            utils.run_script(ip, username, password, port, "../linux-toolbox/initial_base.sh", utils.map_args_to_env_vars([IB_BACKUP_PATH]))
        printer.message(f"Ran initial_base.sh on {ip} with backup path {IB_BACKUP_PATH}", dominion.SUCCESS)
        utils.log(f"Ran initial_base.sh on {ip} with backup path {IB_BACKUP_PATH}")

    printer.message(f"Initial base ran on all hosts with backup path {IB_BACKUP_PATH}", dominion.SUCCESS)
