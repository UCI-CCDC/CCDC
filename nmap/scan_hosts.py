
import argparse
import subprocess
import threading
import xml.etree.ElementTree as ET
import time
from multiprocessing import Manager

# import concurrent.futures
# from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import ProcessPoolExecutor

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    YELLOW = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_sep():
    print('=========================================================================================')

def run_fast_scan(subnet: str) -> str:
    '''
    Takes in subnet in the form "172.16.100.0/24"
    runs a fast scan and then outputs results in xml format in the file: "nmap-fast-x.x.x.0.xml" and
    returns the filename
    '''
    file_to_write = f"nmap-fast-{subnet[:-3]}.xml"

    nmap = subprocess.run(
        args=[
            "nmap",
            "-p",
            "22,80,88,135,443,445,3389,5985",
            "--min-rate",
            '3000'
            '-sV',
            # '-Pn',
            "-oX",
            file_to_write,
            subnet
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return file_to_write



def read_scan_file(filepath, identify_os_type: 'function') -> dict:
    '''reads the scan results from filepath, and uses the function the identifies the 
     correct os type to returns a dictionary of the scan results based on OS type.
     It will also print out the hosts that have websites'''
    host_map = { 'windows': [],'windows-dc':[], 'linux': [], 'unknown': []}
    web_hosts = []
    tree = ET.parse(filepath)
    root = tree.getroot()
    for host in root.iter("host"):
        os_type = identify_os_type(host)
        ip_address = get_ip_from_file(host)
        host_map[os_type].append(ip_address)
        if check_if_web(host) and os_type == 'linux':
            web_hosts.append(ip_address)
    print(f'{bcolors.YELLOW}LINUX WEB HOSTS:{bcolors.ENDC}', web_hosts)
    return host_map



def check_if_web(host) -> bool:
    for port_node in host.find("ports"):
        state = port_node.find("state").attrib["state"]
        if state == "open":
            port_num = port_node.attrib["portid"]
            if port_num == '80' or port_num == '443':
                return True

def get_os_from_fast_scan(host) -> str:
    '''gets the os by checking the port. If 22 is open, it is linux, if 3389/445 is open, it is windows. If neither, it is unkown'''
    open_ports= []
    for port_node in host.find("ports"):
        state = port_node.find("state").attrib["state"]
        if state == "open":
            port_num = port_node.attrib["portid"]
            open_ports.append(port_num)

    if '88' in open_ports:
        return 'windows-dc'
    elif "3389" in open_ports or "5985" in open_ports or ("135" in open_ports and "445" in open_ports):
        return 'windows'
    elif "22" in open_ports:
        return 'linux'
    return 'unknown'




def get_ip_from_file(host) -> str:

    for address in host.iter("address"):
        if address.attrib["addrtype"] == "ipv4":
            return address.attrib["addr"]
    
    return None

def merge_maps(host_maps: list[dict]) -> dict:

    new_map = { 'windows': [], 'windows-dc': [], 'linux': [], 'unknown': []}
    for host_map in host_maps:
        for os in host_map:
            new_map[os].extend(host_map[os])
    #sort all the ip addresses
    for os in new_map:
        new_map[os].sort()
    return new_map


def map_subnet(subnet: str) -> dict:

    fast_scan_file = run_fast_scan(subnet)
    print(fast_scan_file)
    host_map = read_scan_file(fast_scan_file, get_os_from_fast_scan)
    return host_map


def add_to_hosts_maps(host_maps, subnet):
    map = map_subnet(subnet)
    host_maps.append(map)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--subnets', type=str, required=True, help="List of subnets to map, seperated by commas")
    parser.add_argument('-d', '--dominion', type=str, required=False, help="The default password, so that linux machines can be dumped in dominion style")

    args = parser.parse_args()

    

    threads = []

    with Manager() as manager:
        host_maps = manager.list()
        web_hosts = manager.list()
        with ProcessPoolExecutor() as executor:
            
            procs = [executor.submit(add_to_hosts_maps, host_maps, subnet) for subnet in args.subnets.split(',')]


            for proc in procs:
                result = proc.result()
        host_maps = list(host_maps)





    merged_maps = merge_maps(host_maps)

    print('Windows Machines:', merged_maps['windows'])
    print('likely DC:', merged_maps['windows-dc'])


    if args.dominion:
        print('Linux Machines:')
        for machine in merged_maps['linux']:
            print(machine, 'root', args.dominion, 22)
    else:
        print('Linux Machines:', merged_maps['linux'])
    
    f = open("hosts.txt", "w")
    f.write(str(merged_maps))
    





