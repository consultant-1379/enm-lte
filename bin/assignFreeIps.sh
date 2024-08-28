#!/bin/sh
####################################################################
# Version1    : LTE 21.10
# Revision    : CXP 903 0491-374-1
# Jira        : NSS-35802
# Purpose     : Code Base change to assign free IP
# Description : Code Base change to assign free IP
# Date        : May 2021
# Who         : xmitsin
###################################################################
PWD=`pwd`
SimName=$1
echo "start $0 `date`"
#Fetching Free IPs#
lsof -nl >/tmp/lsof.log;rm -rf ~/freeIPs.log; for ip in `ip add list|grep -v "127.0.0\|::1\|0.0.0.0\|00:00:"|cut -d" " -f6|cut -d"/" -f1|grep -v "qdisc\|:"|awk 'NF'`;do grep $ip /tmp/lsof.log > /dev/null; if [ $? != 0 ]; then echo $ip >> ~/freeIPs.log; fi; done; rm -rf /tmp/lsof.log;echo "Total IPs:`ip add list|grep -v "127.0.0\|::1\|0.0.0.0\|00:00:"|cut -d" " -f6|cut -d"/" -f1|grep -v "qdisc\|:" |awk 'NF'|wc -l`"; echo "Free IPs:`wc -l ~/freeIPs.log`"
#Getting Nodename#
echo netsim | sudo -S -H -u netsim bash -c "echo -e '.open '$SimName' \n .show simnes' | /netsim/inst/netsim_shell | grep -v \">>\" | grep -v \"OK\" | grep -v \"NE\"" > /$PWD/NodeData.txt

cat NodeData.txt | awk '{print $1}' > /$PWD/NodeData1.txt
NodeCount=`wc -l < /$PWD/NodeData1.txt`
NodeCounter=1

paste -d@ /$PWD/NodeData1.txt ~/freeIPs.log | while IFS="@" read -r node ip
do
    if [ $NodeCounter -gt $NodeCount ]
    then
        break
    fi
    echo netsim | sudo -S -H -u netsim bash -c "echo -e '.open '$SimName' \n .select $node \n .set taggedaddr subaddr $ip 0 \n .set save \n .start \n setmoattribute:mo=\"ManagedElement=NE01\", attributes =\"managedElementId(string)=$node\"; \n .stop \n .set save' | /netsim/inst/netsim_shell"
NodeCounter=$((NodeCounter+1))
done

echo "End $0 `date`"

