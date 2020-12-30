#!/bin/bash

#written by jaerdon
if [[ $EUID -ne 0 ]]; then
	printf 'Must be run as root, exiting!'
	exit 1
fi

'''
UCI CCDC Snort Installation
        _________ ______
    ___/   \     V      \
   /  ^    |\    |\      \
  /_O_/\  / /    | ‾‾‾\  |
 //     \ |‾‾‾\_ |     ‾‾
//      _\|    _\|

       zot zot, thots.
'''
echo "Warning: This takes a long time to install!"
echo "Run this in the background, otherwise you are wasting time."

install () {
	cd ~/snort_src/$1
	./configure
	make
	make install
}

mkdir ~/snort_src && cd ~/snort_src

if [ $(which yum) ]; then
	yum update -y
	yum install epel-release -y
	yum install https://www.snort.org/downloads/snort/snort-2.9.14.1-1.centos7.x86_64.rpm
	exit 0
elif [ $(which apt-get) ]; then 
	apt-get update && apt-get upgrade -y
	apt-get install -y libtool git autoconf build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev libpcap-dev zlib1g-dev pkg-config libhwloc-dev cmake bison flex
elif [ $(which dnf) ]; then
	dnf upgrade
	dnf install flex bison gcc gcc-c++ make cmake autoconf libtool libpcap-devel pcre-devel libdnet-devel hwloc-devel openssl-devel zlib-devel luajit-devel pkgconfig libnfnetlink-devel libnetfilter_queue-devel libmnl-devel 
fi

wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
	http://www.colm.net/files/ragel/ragel-6.10.tar.gz \
	https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz \
	https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz \
    https://github.com/intel/hyperscan/archive/v5.2.0.tar.gz \
    https://www.snort.org/downloads/community/snort3-community-rules.tar.gz

for file in *.tar.gz; do tar -xzf "$file"; done

install gperftools-2.7
install pcre-8.43
install ragel-6.10

mkdir ~/snort_src/hyperscan-5.2.0-build
cd hyperscan-5.2.0-build/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_71_0/ ../hyperscan-5.2.0
make
make install

cd ~/snort_src
git clone https://github.com/snort3/libdaq.git && cd libdaq
./bootstrap
install libdaq

ldconfig

cd ~/snort_src
git clone git://github.com/snortadmin/snort3.git
cd snort3
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc
cd build
make
make install

/usr/local/bin/snort -V # Snort should now be installed 

# Configure env vars
export LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\;
export SNORT_LUA_PATH=/usr/local/etc/snort

sh -c "echo 'export LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\;' >> ~/.bashrc"
sh -c "echo 'export SNORT_LUA_PATH=/usr/local/etc/snort' >> ~/.bashrc"

echo 'Defaults env_keep += "LUA_PATH SNORT_LUA_PATH"' > /etc/sudoers.d/snort-lua


# Configure network cards
printf('Enter interface name: ')
read iface
echo

cat > /lib/systemd/system/ethtool.service << EOF
[Unit]
Description=Ethtool Configration for Network Interface

[Service]
Requires=network.target
Type=oneshot
ExecStart=/sbin/ethtool -K $(iface) gro off
ExecStart=/sbin/ethtool -K ens3 lro off

[Install]
WantedBy=multi-user.target
EOF

systemctlenableethtool
service ethtool start

# Install Community Rules
cd ~/snort_src/snort3-community-rules

mkdir /usr/local/etc/snort/rules \
	/usr/local/etc/snort/builtin_rules \
	/usr/local/etc/snort/so_rules \
	/usr/local/etc/snort/lists
cp snort3-community.rules /usr/local/etc/snort/rules/
cp sid-msg.map /usr/local/etc/snort/rules/

# Enable Built-in Rules
#sed '172s/\-\-//'
	# TODO

# Run Snort
snort -c /usr/local/etc/snort/snort.lua \
	-R /usr/local/etc/snort/rules/snort3-community.rules