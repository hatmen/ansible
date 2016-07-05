#!/bin/bash
#description: Auto-starts tomcat
# chkconfig: 35 10 90
# Tomcat auto-start
# Source function library.
. /etc/init.d/functions
# source networking configuration.
. /etc/sysconfig/network
RETVAL=0
TOMCATBASE=tomcat-app
TOMCATUSER=tomcat
export JAVA_HOME=/xs/app/jdk1.7.0_79
export CATALINA_HOME=/xs/app/${TOMCATBASE}
export CATALINA_BASE=/xs/app/${TOMCATBASE}
start()
{
        if [ -f $CATALINA_HOME/bin/startup.sh ];
          then
            echo $"Starting $TOMCATBASE"
            $CATALINA_HOME/bin/startup.sh
            RETVAL=$?
            echo -e "$TOMCATBASE started OK"
            return $RETVAL
        fi
}
stop()
{
        if [ -f $CATALINA_HOME/bin/shutdown.sh ];
          then
            echo $"Stopping $TOMCATBASE"
            /bin/su $TOMCATUSER -c $CATALINA_HOME/bin/shutdown.sh
            RETVAL=$?
            sleep 1
            if [ ! -z `ps -fwwu $TOMCATUSER | egrep "${TOMCATBASE}"|grep -v grep | grep -v PID | /bin/awk '{print $2}'` ]
               then
                 ps -fwwu $TOMCATUSER | egrep "${TOMCATBASE}"|grep -v grep | grep -v PID | /bin/awk '{print $2}'|xargs kill -9
            fi
            echo -e "$TOMCATBASE stopped OK"
            return $RETVAL
        fi
}
case "$1" in
start)
        start
        ;;
stop)
        stop
        ;;
restart)
         echo $"Restaring Tomcat7"
         $0 stop
         sleep 1
         $0 start
         ;;
*)
        echo $"Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
exit $RETVAL
