#!/bin/bash
#Version History
####################################################################
# Version1    : LTE 18.10
# Revision    : CXP 903 0491-337-1
# Purpose     : To reduce the simulation build time
# Description : This script executes the kertayles generated
#               per node
# Jira        : NSS-18645
# Date        : May 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version2    : LTE 18.10
# Revision    : CXP 903 0491-339-1
# Purpose     : Increasing the sleep time for 2874 & 4874 scripts
# Description : Sleep time introduced here in order to run the
#               cipher scripts properly
# Jira        : NSS-18644
# Date        : May 2018
# Who         : zyamkan
###################################################################

echo "script started running at" $(date +%T)
usage (){

echo "Usage  : $0 <sim name> <basename> <node_num> "

echo "Example: $0 LTE16A-V12x160-RVDG2-FDD-LTE01 LTE01dg2ERBS00 1"

echo "script stopped running at "$(date +%T);

}
######################################################
#To check whether commands are passed as they should#
######################################################
if [ $# -ne 3 ]
then
usage
exit
fi
SIMNAME=$1
BASENAME=$2
NODENUM=$3
#NUMOFNODES=`echo $SIMNAME|awk -F'x' '{print $NF}'`
PWD=`pwd`
######################################################
#Making MML Script#
######################################################

#NUMOFNODES=`printf "$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}'`

if [ $NODENUM -le 9 ]
then
BASENAME+=00;
BASENAME+=$NODENUM;
NODENAME=$BASENAME;
elif [ $NODENUM -le 99 ]
then
BASENAME+=0;
BASENAME+=$NODENUM;
NODENAME=$BASENAME;
else
BASENAME+=$NODENUM;
NODENAME=$BASENAME;
fi
echo "\t$NODENUM  $NODENAME \n"
#NUM=$(($(($(($3 - 1))*160)) + $NODENUM ));
######################################################
#Making MO Script#
######################################################

MOLIST=`ls *mo$NODENUM | grep -v Final`

for mofile in $MOLIST
do

cat >> abc$NODENUM.mml << ABC
.open $SIMNAME
.select $NODENAME
.start
useattributecharacteristics:switch="off";
kertayle:file="$PWD/$mofile";
ABC

if [[ $mofile == *"2874"* || $mofile == *"4874"* ]]  # Cipher scripts will restart the nodes, so it needs sleep time
then
cat >> abc$NODENUM.mml << XYZ
.sleep 40
XYZ
fi


/netsim/inst/netsim_pipe < abc$NODENUM.mml
rm abc$NODENUM.mml

done

#BASENAME=$2

echo "script ended at" $( date +%T );

