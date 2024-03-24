
import argparse
import subprocess
import xml.etree.ElementTree as ET
from multiprocessing import Manager
from concurrent.futures import ProcessPoolExecutor
from collections import defaultdict
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
    print('\n===================================================\n')

def run_scan(subnet: str, arguments, scan_name: str) -> str:
    '''
    Takes in subnet in the form "172.16.100.0/24"
    runs a fast scan and then outputs results in xml format in the file: "nmap-fast-x.x.x.0.xml" and
    returns the filename
    '''
    file_to_write = f"nmap-{scan_name}-{subnet[:-3]}.xml"

    args = ['nmap', '--min-rate', '3000']
    args.extend(arguments)
    args.extend(['-oX', file_to_write, subnet])
        

    subprocess.run(
        args = args,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    return file_to_write



def read_scan_file(filepath, print_web_hosts: bool) -> dict:
    host_map = defaultdict(list)
    linux_web_hosts = []
    windows_web_hosts = []
    unknown_web_hosts = []
    tree = ET.parse(filepath)
    root = tree.getroot()
    for host in root.iter("host"):
        os_type = get_os_from_fast_scan(host)
        ip_address = get_ip_from_file(host)
        host_map[os_type].append(ip_address)

        if check_if_web(host):
            if os_type == 'linux' or os_type == 'linux-domain':
                linux_web_hosts.append(ip_address)
            elif os_type == 'windows' or os_type == 'windows-dc':
                windows_web_hosts.append(ip_address)
            else:
                unknown_web_hosts.append(ip_address)
    if print_web_hosts:
        print(f'{bcolors.YELLOW}LINUX WEB HOSTS:{bcolors.ENDC}', linux_web_hosts)
        print(f'{bcolors.OKBLUE}WINDOWS WEB HOSTS:{bcolors.ENDC}', windows_web_hosts)
        print('UNKOWN WEB HOSTS:', unknown_web_hosts)
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
    is_windows = "3389" in open_ports or "5985" in open_ports or ("135" in open_ports and "445" in open_ports)
    is_linux = '22' in open_ports
    if '88' in open_ports or '389' in open_ports:
        if is_windows:
            return 'windows-dc'
        elif is_linux:
            return 'linux-domain'
        else:
            return 'unkown-domain'
    elif is_windows:
        return 'windows'
    elif is_linux:
        return 'linux'
    return 'unknown'
    

def get_ip_from_file(host) -> str:

    for address in host.iter("address"):
        if address.attrib["addrtype"] == "ipv4":
            return address.attrib["addr"]
    
    return None

def merge_maps(host_maps: list[dict]) -> dict:

    new_map = defaultdict(list)
    for host_map in host_maps:
        for os in host_map:
            new_map[os].extend(host_map[os])
    #sort all the ip addresses
    for os in new_map:
        new_map[os].sort()
    return new_map


def map_subnet(subnet: str, args: list[str], scan_name: str, print_web_hosts: bool) -> dict:
    scan_file = run_scan(subnet, args, scan_name)
    print(f'{scan_name} scan file: {scan_file}')
    host_map = read_scan_file(scan_file, print_web_hosts)
    return host_map


def add_to_hosts_maps(host_maps, subnet, args, scan_name, print_web_hosts):
    h_map = map_subnet(subnet, args, scan_name, print_web_hosts)
    host_maps.append(h_map)


def discover_hosts(subnets: list[str], args, dominion_pass: str, print_web_hosts: bool, scan_name):

    with Manager() as manager:
        host_maps = manager.list()
        with ProcessPoolExecutor() as executor:
            
            procs = [executor.submit(add_to_hosts_maps, host_maps, subnet, args, scan_name, print_web_hosts) for subnet in subnets.split(',')]
            for proc in procs:
                result = proc.result()
        host_maps = list(host_maps)


    merged_maps = merge_maps(host_maps)

    print('Windows Machines:', merged_maps['windows'])
    print('likely windows DC:', merged_maps['windows-dc'])

    print('Linux domain', merged_maps['linux-domain'])

    if dominion_pass:
        print('Linux Machines:')
        for machine in merged_maps['linux']:
            print(machine, 'root', dominion_pass, 22)
        for machine in merged_maps['linux-domain']:
            print(machine, 'root', dominion_pass, 22)
    else:
        print('Linux Machines:', merged_maps['linux'])
    
    if scan_name == 'fast':
        print('Unknown machines: ', merged_maps['unknown'])
        print('Unkown Domain:', merged_maps['unknown-domain'])
    
    f = open(f'host-{scan_name}', "a")
    s = str(merged_maps) + '\n'
    f.write(s)
    f.close()
                

        

    


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--subnets', type=str, required=True, help="List of subnets to map, seperated by commas")
    parser.add_argument('-d', '--dominion', type=str, required=False, help="The default password, so that linux machines can be dumped in dominion style")
    parser.add_argument('-w', '--web', action='store_true', required=False, help="set this to enable scanning for web hosts")

    args = parser.parse_args()

    print(f'{bcolors.OKGREEN}fast scan results:{bcolors.ENDC}')

    nmap_args = ['-p', '22,88,135,389,445,3389,5985', '-sV']

    if args.web:
        nmap_args[1] += ',80,443'

    discover_hosts(args.subnets, nmap_args, args.dominion, args.web, 'fast')

    print_sep()

    nmap_args.append('-Pn')

    print(f'{bcolors.OKCYAN}long scan results:{bcolors.ENDC}')

    discover_hosts(args.subnets, nmap_args, args.dominion, args.web, 'long')

 





