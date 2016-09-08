#!/bin/bash

MYHOME=`pwd`
SOFT_URL='http://10.30.0.14'
LOG_PATH='/root/initial.log'
#取内网IP地址
PRIVATEIP=`ifconfig|sed -n '2p'|awk '{print $2}'|awk -F: '{print $2}'`




if [ $# -ne 1 ];then
    echo "please input a hostname"
    echo "Usage:$0 {live-sl-lc-web-u6-i0-10}"
    exit 1
fi


#config dns

cat <<EOF>/etc/resolv.conf 
nameserver 10.30.0.51
nameserver 114.114.114.114
EOF




#设置hostname
hostname $1
sed -i '/HOSTNAME=.*/s/^/#/' /etc/sysconfig/network
sed -i "/HOSTNAME/aHOSTNAME=$1" /etc/sysconfig/network

##add directory
mkdir -p /xs/soft/
mkdir -p /xs/app/
mkdir -p /xs/logs/
mkdir -p /xs/webapps/
mkdir -p /xs/scripts/
mkdir -p /xs/backup/

#安装基础软件包
yum -y install openssl openssl-devel telnet vim* lrzsz sysstat iptraf ntpdate libselinux-python iftop gcc gcc-c++ autoconf  openssl


#install iftop
yum -y install flex byacc  libpcap ncurses ncurses-devel libpcap-devel
cd /xs/soft/
wget ${SOFT_URL}/iftop-0.17.tar.gz
tar -xzvf iftop-0.17.tar.gz
cd iftop-0.17
./configure && make && make install


#关闭selinux
/bin/cp /etc/selinux/config /etc/selinux/config.bak
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
/etc/init.d/iptables stop
chkconfig --level 35 iptables off

#关闭IPV6
cat <<EOF>>/etc/modprobe.d/dist.conf
alias net-pf-10 off
alias ipv6 off
EOF

cat <<snake>> /etc/sysconfig/network 
NETWORKING_IPV6=no
IPV6_AUTOCONF=no
snake
/sbin/chkconfig --level 345 ip6tables off
setenforce 0

#修改时区为shanghai时间
cd ${MYHOME}
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#加入计划任务
echo "0 */2 * * * /usr/sbin/ntpdate -s -b -p 8 -u ntp.xs.prd >/dev/null 2>&1" >>/var/spool/cron/root
chmod 600 /var/spool/cron/root


#删除不必要的用户
for USER in adm lp sync shutdown halt operator games
do
    userdel $USER
done

#删除不必要的用户组

for GROUP in adm lp games dip
do
    groupdel $GROUP
done


#usermod -s /sbin/nologin username


#关闭不需要的服务
for i in `ls /etc/rc3.d/S*`
do
              CURSRV=`echo $i|cut -c 15-`
echo $CURSRV
case $CURSRV in
          local | crond |iptables | haldaemon | network | sshd | syslog | sendmail | nfs | portmap | xinetd | kudzu | apmd | acpid)
      echo "Skip Needed service!"
      ;;
      *)
          echo "change $CURSRV to off"
          chkconfig --level 2345 $CURSRV off
          service $CURSRV stop
      ;;
esac
done




#修改系统内核参数
#===========================================================================
echo "ulimit -SHn 65536" >> /etc/rc.local
echo ulimit -HSn 65536 》/root/.bash_profile

/bin/cp /etc/sysctl.conf /etc/sysctl.conf.bak

sed -i "s/net.ipv4.tcp_syncookies =/#net.ipv4.tcp_syncookies =/" /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 300" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 5120 65000" >> /etc/sysctl.conf
echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem=4096 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem=4096 65536 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 10" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 30000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_no_metrics_save=1" >> /etc/sysctl.conf
echo "net.core.somaxconn = 262144" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_orphans = 262144" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 262144" >> /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syn_retries = 2" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
sysctl -p
 
####open files max
if [[ -z `grep 'hard nofile 65536' /etc/security/limits.conf` ]]
then
        #禁止core dump   ore dump会耗费大量的磁盘空间
        echo '* soft core 0' >> /etc/security/limits.conf
        echo '* hard core 0' >> /etc/security/limits.conf
        echo '* soft nofile 65536' >> /etc/security/limits.conf 
        echo '* hard nofile 65536' >> /etc/security/limits.conf
        ulimit -SHn 65536
fi

##xsadmin
groupadd admin
useradd -g admin xsadmin
mkdir -p /home/xsadmin/.ssh && chmod 700 /home/xsadmin/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4PQHKIGvVUv+chQ6tXKG7vYUNah1RLMRyZrnPHhOZg8Lao8NQBWJym//hWl+/olsHKbz7lRyVa8Qs8BpXQeOqQWlfoYSbSMr95YVUqLz+ESdNqYDD5w+tExeJgXWVfXeZNPfaJf+V1k2Bkj2oULPMvFAg14mHXTdrwyYzaJrur1V/ooCeKk3ePJP7fMXNM3Ya0eklBkEY0jyU8iFZaCSjvEtvuUZ9alRN41vxMj0Y69Zs3BWAEZha0zMuWEzXWAwvTlQ6b/XD9QbmtBl+ldYv6mzYch1QPRjbI2X4fxjg2fiecxK8jP+3gkVuMmZXVJgKjjBX3UoYgvWQEphYuMO+w== root@web">>/home/xsadmin/.ssh/authorized_keys && chmod 600 /home/xsadmin/.ssh/authorized_keys && chown -R xsadmin:admin /home/xsadmin/


#2、配置sshd
ssh_cf="/etc/ssh/sshd_config"
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i -e '74 s/^/#/' -i -e '76 s/^/#/' $ssh_cf
sed -i "s/#UseDNS yes/UseDNS no/" $ssh_cf
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 300/g" $ssh_cf
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 0/g" $ssh_cf
sed -i "s/#Port 22/Port 8000/g" $ssh_cf
#echo "PermitRootLogin no" >> $ssh_cf
echo "MaxAuthTries 3" >> $ssh_cf
echo "PubkeyAuthentication yes" >> $ssh_cf
echo "AuthorizedKeysFile .ssh/authorized_keys" >> $ssh_cf
echo "IgnoreRhosts yes" >> $ssh_cf


##配置sudo
sed -i 's/#Cmnd_Alias/Cmnd_Alias/' /etc/sudoers
sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
sed -i 's/# %sys/ %sys/' /etc/sudoers
cat <<EOF >> /etc/sudoers


Defaults:xsadmin       !requiretty
%admin     ALL=(ALL)       NOPASSWD: ALL
EOF



##sshd reload生效
/etc/init.d/sshd reload

##给bash_history增加时间列
echo 'HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "' >>/etc/bashrc


##zabbix 基础模板配置
cd /xs/soft/
wget ${SOFT_URL}/zabbix.tgz
tar -xzf zabbix.tgz
yum -y install unixODBC.x86_64
#rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/6/x86_64/zabbix-agent-3.0.3-1.el6.x86_64.rpm   
yum -y install zabbix-agent
#mkdir -p /etc/zabbix/script
rsync -av zabbix/ /etc/zabbix/
chown -R zabbix.zabbix /etc/zabbix/
chmod -R 755 /etc/zabbix/
chkconfig --level 35 zabbix-agent on
/etc/init.d/zabbix-agent restart

##自动注册zabbix
cd /xs/soft/
wget ${SOFT_URL}/zabbix_autoadd_linux.py
/usr/bin/python  zabbix_autoadd_linux.py add
rm -f zabbix_autoadd_linux.py
rm -f /root/initial.sh
