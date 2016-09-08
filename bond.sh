#!/bin/bash


bonddir=/etc/sysconfig/network-scripts/
IP="$1"
time=`date +%Y%m%d`

cd "$bonddir"

zhunbei(){
	mkdir oldfile
	mv ifcfg-em1 oldfile/ifcfg-em1"$time"
	mv ifcfg-em2 oldfile/ifcfg-em2"$time"
}

em1(){
cat >> "$bonddir"ifcfg-em1 << EOF
DEVICE=em1
ONBOOT=yes
TYPE=Ethernet
BOOTPROTO=static
USERCTL=no
MASTER=bond0
SLAVE=yes
IPV6INIT=no
EOF
}

em2(){
cat >> "$bonddir"ifcfg-em2 << EOF
DEVICE=em2
ONBOOT=yes
TYPE=Ethernet
BOOTPROTO=static
USERCTL=no
MASTER=bond0
SLAVE=yes
IPV6INIT=no
EOF
}

bond(){
cat >> "$bonddir"ifcfg-bond0 << EOF
DEVICE=bond0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
USERCTL=no
PEERDNS=yes
IPV6INIT=no
IPADDR="$IP"
NETMASK=255.255.255.0
GATEWAY=10.30.0.254
BONDING_OPTS="miimon=80 mode=0"
EOF
}

modprobe(){
cat >> /etc/modprobe.d/modprobe.conf << EOF
alias bond0 bonding
options bonding mode=0 miimon=200
EOF
}

if [ -z "$IP" ];then
	echo "请输入要设置的IP '10.30.X'"
else
	zhunbei
	em1
	em2
	bond
	modprobe
	/etc/init.d/network restart
	ifconfig
fi
