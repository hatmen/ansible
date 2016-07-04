#!/bin/bash
#

result=`grep "jdk1.7.0_79" /etc/profile`

if [ "$result"x == "x" ];then

/bin/cat >> /etc/profile << EOF

# Export JDK 
export JAVA_HOME=/xs/app/jdk1.7.0_79
export JAVA_BIN=/xs/app/jdk1.7.0_79/bin
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH

EOF
fi
