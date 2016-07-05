### xiangshang-online ansible部署说明
#### 以tomcat-home为例
``` yml
---
- hosts: "{{host}}"                                 # 主机组变量名
  gather_facts: False                               # 关闭setup搜索
  vars:
    pro_name: "tomcat-home"                         # 项目名称(必须)
    docbase: "/xiangshang/data/home"                # 自定义项目程序路径(如果按照默认路径，使用dirname参数)
    log_path: "/xiangshang/logs/home"               # 日志路径
  pre_tasks:
    - name: 判断apr是否安装
      stat: path=/usr/local/apr/
      register: apr
    - name: 判断jdk是否安装
      stat: path=/xiangshang/app/jdk1.7.0_79
      register: jdk
  roles:
    - role: jdk_install                             # 判断jdk是否安装
      when: not jdk.stat.exists
    - role: tomcat_native_install                   # 判断apr是否安装
      when: not apr.stat.exists
    - role: tomcat_install                          # 安装tomcat
    - {role: edit_conf, tags: ["copy_server", "copy_context", "copy_catalina", "copy_srv"]}   # 配置文件
    - role: zabbix_tomcat                           # zabbix 添加tomcat监控
  post_tasks:
    - name: 赋权tomcat权限
      file: path=/xiangshang/app/{{pro_name}} recurse=yes owner=tomcat group=tomcat mode=755 state=directory
    - name: 添加自启
      shell: chkconfig --level 35 {{pro_name}} on
```
**执行命令格式**:
`ansible-playbook -i ./hosts tomcat-test.yml -e "host=test-02"`

#### jdk安装
**执行命令格式**:
` ansible-playbook -i ./hosts jdk_install.yml -e "host=test-02"

#### tomcat-native安装
``` yml
---
- hosts: "{{host}}"
  remote_user: root
  pre_tasks:
    - name: 安装native判断jdk是否安装
      stat: path=/xiangshang/app/jdk1.7.0_79
      register: jdk
  roles:
    - role: jdk_install
      when: not jdk.stat.exists                  # 判断是否安装jdk
    - role: tomcat_native_install
```
**执行命令格式**:
`ansbile-playbook -i ./hosts tomcat_native_install.yml -e "host=test-02"`

#### tomcat配置文件部署
``` yml
---
- hosts: "{{host}}"
  gather_facts: False
  roles:
    - edit_conf
```
**执行命令格式**:
`ansible-playbook -i ./hosts copy_tomcat_conf.yml --tags="copy_server" -e "host=test-02 pro_name=tomcat-home"`

**说明**:
**tags:**
  - copy_server: 拷贝server.xml使用
  - copy_context: 拷贝context.xml使用
  - copy_srv: 拷贝tomcat启动脚本使用
  - copy_catalina：拷贝catalina.sh使用
