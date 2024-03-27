#!/usr/bin/env python
import passwords
import argparse
import pathlib
import printer
import utils
import base
import os

IP_USER_MAP = pathlib.Path("conf/dominion.conf")
PASSWORDS_DB = pathlib.Path("conf/passwords.db")
LOG_FILE = pathlib.Path("log/dominion.log")
BINARY = pathlib.Path("../coordinate/coordinate-linux")
WARNING = "WARNING"
SUCCESS = "SUCCESS"
ERROR = "ERROR"

def main() -> None:
    parser = argparse.ArgumentParser(description='Dominion. A python wrapper for "coordinate" to more effectively manage multiple Linux hosts.')

    parser.add_argument('-R', '--rotate', help=f'Change all passwords in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-I', '--inventory', help=f'Run Inventory on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-B', '--basic', help=f'Run "basic" inventory on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-SSH', '--ssh', help=f'SSH hardening on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-PHP', '--php', help=f'PHP hardening on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-POL', '--pwpolicy', help=f'Password policy capture on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-PII', '--pii', help=f'PII scan on all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-N', '--normalize', help=f'normalize.sh all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-IB', '--initialbase' , help=f'initial_base.sh all hosts in {IP_USER_MAP}', action='store_true')
    parser.add_argument('-PASSES', '--passwords', help=f'pass.sh for all hosts in {IP_USER_MAP}', action='store_true')

    parser.add_argument('-E', '--execute', help=f'Execute script on provided hosts: -E=/path/to/script.sh:192.168.220.12,192.168.220.13:arg1,arg2,arg3', type=str)

    parser.add_argument('-A', '--add', help=f'Add host to {IP_USER_MAP}: -A=192.168.220.12:root:password', type=str)

    parser.add_argument('-C', '--clear', help=f'Clear log file at {LOG_FILE}', action='store_true')

    args = parser.parse_args()

    if not os.path.exists(IP_USER_MAP):
        printer.message(f"{IP_USER_MAP} not found.", WARNING)
        utils.die(ERROR)
    
    if not os.path.exists(PASSWORDS_DB):
        printer.message(f"{PASSWORDS_DB} not found.", WARNING)
        utils.die(ERROR)
    
    if not os.path.exists(LOG_FILE):
        printer.message(f"{LOG_FILE} not found.", WARNING)
        utils.die(ERROR)

    if args.clear:
        utils.clean_log()

    if args.add:
        ip, username, password = args.add.split(':')[0], args.add.split(':')[1], args.add.split(':')[2]
        utils.add_host(ip, username, password)

    if args.rotate:
        data = utils.read_all()
        passwords.change_all_root_passwords(data)

    if args.inventory:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-inventory/inventory.sh"))


    if args.basic:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-inventory/baseq.sh"))

    if args.pii:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-toolbox/pii.sh"))

    if args.pwpolicy:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-toolbox/pw_pol.sh"))

    if args.ssh:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-hardening/ssh.sh"))

    if args.php:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-hardening/php.sh"))

    if args.normalize:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-toolbox/normalize.sh"))

    if args.initialbase:
        data = utils.read_all()
        base.initial_base_across_boxes(data)

    if args.passwords:
        utils.run_script_against_all_hosts(pathlib.Path("../linux-hardening/pass.sh"))

    if args.execute:
        utils.execute(args.execute)

if __name__ == "__main__":
    utils.log("Dominion started")
    printer.print_banner()
    main()
