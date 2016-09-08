#!/usr/bin/env python
#coding=utf-8

import json
import urllib2
import sys
from urllib2 import Request,urlopen,URLError,HTTPError
import os
import socket
import fcntl
import struct




def get_ip_address(ifname='em1'):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        return socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0X8915, struct.pack('256s', ethname[:15]))[20:24])
    except:
        ips = os.popen("/sbin/ifconfig | grep \"inet addr\" | grep -v \"127.0.0.1\" | awk -F \":\" '{print $2}' | awk '{print $1}'").readlines()
        if len(ips) > 0:
            return ips[0]
    return ''


#用户认证信息,最终目的是需要得到一个SESSIONID
#下面是生成一个JSON格式的数据:用户名和密码
def zabbix_login(zabbix_user, zabbix_pass, zabbix_url, zabbix_header, auth_code):
    auth_data = json.dumps(
        {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params":
            {
                "user": zabbix_user,
                "password": zabbix_pass
            },
            "id": 0
        })
    request = urllib2.Request(zabbix_url, auth_data)
    for key in zabbix_header:
        request.add_header(key, zabbix_header[key])
    try:
        result = urllib2.urlopen(request)
    except HTTPError, e:
        print 'The server could not fulfill the request,Error code:', e.code
    except URLError, e:
        print 'We failed to reach a server.Reason:', e.reason
    else:
        response = json.loads(result.read())
        result.close()

    if 'result' in response:
        auth_code = response['result']
        return auth_code
    else:
        print response['error']['data']



def zabbix_auto_add_host(host_name,local_ip,auth_code):
    # 自动添加host，自动加入组group-live-uxdata-linux and link linux template
    # template-uxdata-linux-basic 10146
    json_data = {
        "method": "host.create",
        "params": {'groups': [{'groupid': '16'}],
                   'host': local_ip,
                   'name': host_name,
                   #'proxy_hostid':'10107',  #代理服务器
                   'interfaces': [{'dns': '',
                                   'ip': local_ip,
                                   'main': 1,
                                   'port': '10050',
                                   'type': 1,
                                   'useip': 1
                                   }],
                   'templates': [{'templateid': '10146'}]  # 用到的模板

                   }
    }

    json_base = {
        "jsonrpc": "2.0",
        "auth": auth_code,
        "id": 1
    }

    json_data.update(json_base)

    if len(auth_code) == 0:
        sys.exit(1)
    if len(auth_code) != 0:
        get_host_data = json.dumps(json_data)
        request = urllib2.Request(zabbix_url, get_host_data)
        for key in zabbix_header:
            request.add_header(key, zabbix_header[key])
        try:
            result = urllib2.urlopen(request)
        except URLError as e:
            if hasattr(e, 'reason'):
                print 'We failed to reach a server'
                print 'Reason:', e.reason
            elif hasattr(e, 'code'):
                print 'The server could not fulfill the request'
                print 'Error code:', e.code
        else:
            response = json.loads(result.read())
            result.close()
            print "host %s added successfully to zabbix" % (host_name)

def get_host_id(host_name):
    json_data = {
    "method": "host.get",
    "params": {
        "output": "hostid",
        "filter": {
            "host": [
                host_name,
            ]
        }
        },
    }

    json_base = {
        "jsonrpc": "2.0",
        "auth": auth_code,
        "id": 1
    }

    json_data.update(json_base)

    if len(auth_code) == 0:
        sys.exit(1)
    if len(auth_code) != 0:
        get_host_data = json.dumps(json_data)
        request = urllib2.Request(zabbix_url, get_host_data)
        for key in zabbix_header:
            request.add_header(key, zabbix_header[key])
        try:
            result = urllib2.urlopen(request)
        except URLError as e:
            if hasattr(e, 'reason'):
                print 'We failed to reach a server'
                print 'Reason:', e.reason
            elif hasattr(e, 'code'):
                print 'The server could not fulfill the request'
                print 'Error code:', e.code
        else:
            response = json.loads(result.read())["result"][0]['hostid']
            result.close()
            return response

def zabbix_auto_link_template(template_id,host_id,auth_code):
    # 自动添加host，自动加入组group-live-uxdata-linux and link linux template
    # template-uxdata-linux-basic 10117
    json_data = {
        "method": "template.massadd",
        "params": {
            "templates": [
                {
                    "templateid": template_id
                }
            ],
            "hosts": [
                {
                    "hostid": host_id
                },

            ]
        },

    }

    json_base = {
        "jsonrpc": "2.0",
        "auth": auth_code,
        "id": 1
    }

    json_data.update(json_base)

    if len(auth_code) == 0:
        sys.exit(1)
    if len(auth_code) != 0:
        get_host_data = json.dumps(json_data)
        request = urllib2.Request(zabbix_url, get_host_data)
        for key in zabbix_header:
            request.add_header(key, zabbix_header[key])
        try:
            result = urllib2.urlopen(request)
        except URLError as e:
            if hasattr(e, 'reason'):
                print 'We failed to reach a server'
                print 'Reason:', e.reason
            elif hasattr(e, 'code'):
                print 'The server could not fulfill the request'
                print 'Error code:', e.code
        else:
            response = json.loads(result.read())
            result.close()
            print "template  %s is added successfully to host %s" % (template_id,host_id)



if __name__ == '__main__':
    #zabbix的地址,用户名,密码
    zabbix_url="http://zabbix.xs.prd/api_jsonrpc.php"
    zabbix_header={"Content-Type":"application/json"}
    zabbix_user="admin"
    zabbix_pass="xxxxxx"
    auth_code=""
    #temlate id list
    temlates = {'lvs':'10118',
    'mysql':'10123',
    'mysql-slave':'10124',
    'nginx':'10125',
    'php':'10126',
    'redis':'10127',
    'squid':'10128',
    'tomcat':'10083',
    'memecached':'10120',
    'tomcat-home2.0': '10169',
    'tomcat-listener': '10184',
    'tomcat-messager': '10183',
    'tomcat-mgmt': '10181',
    'tomcat-mobile': '10172',
    'tomcat-opm': '10185',
    'tomcat-pay': '10187',
    'tomcat-payadmin': '10179',
    'tomcat-service': '10177',
    'tomcat-task': '10182',
    'tomcat-usercenter': '10186',
    'tomcat-wap': '10173',
    'youcai-app': '10189',
    'youcai-core': '10192',
    'youcai-mgmt': '10190',
    'youcai-task': '10191',
    'youcai-wap': '10188',
    'tomcat-engine': '10175',
    }

    # 获取IP和hostname
    host_name = os.popen('hostname').readlines()[0].strip()
    if "lv" in host_name:
        local_ip = get_ip_address('eth0').strip()
    else:
        local_ip = get_ip_address('bond0').strip()


    #zabbix login
    auth_code = zabbix_login(zabbix_user, zabbix_pass, zabbix_url, zabbix_header, auth_code)

    #auto add host to zabbix
    if sys.argv[1] == 'add':
        zabbix_auto_add_host(host_name,local_ip,auth_code)
    elif sys.argv[1] == 'link':
        host_id = get_host_id(local_ip)
        template_id = temlates[sys.argv[2]]
        zabbix_auto_link_template(template_id,host_id,auth_code)
    else:
        print "wrong parameters"

