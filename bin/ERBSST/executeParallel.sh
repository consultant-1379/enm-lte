#!/bin/bash

#Version History
####################################################################
# Version1    : LTE 18.10
# Revision    : CXP 903 0491-337-1
# Purpose     : To reduce the simulation build time
# Description : This script executes parallel netsim shells
# Jira        : NSS-18645
# Date        : May 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version2    : LTE 18.10
# Revision    : CXP 903 0491-339-1
# Purpose     : Increasing the sleep time between netsim shells
# Description : Changing sleep time between netsim shells
# Jira        : NSS-18644
# Date        : May 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version2    : LTE 18.12
# Revision    : CXP 903 0491-343-1
# Purpose     : MML support for Parallel LTE Code Base
# Description : Making MML script run strictly after Kertayles run
# Jira        : NSS-18892
# Date        : July 2018
# Who         : xravlat
####################################################################
####################################################################
# Version2    : LTE 18.14
# Revision    : CXP 903 0491-345-1
# Purpose     : Giving support simulation with < 10 nodes
# Description : Giving Support to execute the script simulation
#               contains < 10 nodes
# Jira        : NSS-19335
# Date        : Aug 2018
# Who         : zyamkan
####################################################################
SIMNAME=$1
LOGSPATH=`pwd`

echo "************************************"
echo "./executeParallel.sh script started running" $(date +%T)
echo "************************************"

BASE1=`echo "$SIMNAME" | awk -F "-" '{print $NF}'`

#BASE1="$( echo $SIMNAME | rev |cut -d'-' -f1|rev)"

case $SIMNAME in
  *DG2*)
	BASE2=dg2ERBS00
	;;
  *PICO*)
	BASE2=pERBS00
	;;
	*)
	BASE2=ERBS00
	;;
esac
BASENAME=$BASE1$BASE2

#NUMOFNODES=`printf "$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}'`
NUMOFNODES=`echo "$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}'`

function_start()  # This function selects the 10 netsim shells at a time and it calls the executeKertayles.sh
{
NUM=$1

let STARTNUM="($NUM * 10) + 1"

let ENDNUM="($NUM + 1) * 10"

for NODENUM in `seq $STARTNUM $ENDNUM`
do
./executeKertayles.sh $SIMNAME $BASENAME $NODENUM > LOGof$NODENUM.log &
done
}

if [ $NUMOFNODES -lt 10 ]; then
for NODE in `seq 1 $NUMOFNODES`
do
./executeKertayles.sh $SIMNAME $BASENAME $NODE > LOGof$NODENUM.log &
done
sleep 150
for temp in `seq 1 $NUMOFNODES`
do
cat LOGof$temp.log >> $LOGSPATH/../../log/LTE-SIMS.log
done
fi

if [ $NUMOFNODES == 10 ]; then
function_start 0
sleep 720   # As We are spawning 10 netsim shells parallelly so we are introducing the sleep time
for temp in `seq 1 $NUMOFNODES`
do
cat LOGof$temp.log >> $LOGSPATH/../../log/LTE-SIMS.log
done
else
let BATCH="($NUMOFNODES / 10) - 1"
for var in `seq 0 $BATCH`
do
function_start $var
let STARTTERM="($var * 10) + 1"
let ENDTERM="($var + 1) * 10"
sleep 720   # As We are spawning 10 netsim shells parallelly so we are introducing the sleep time
for temp in `seq $STARTTERM $ENDTERM`
do
cat LOGof$temp.log >> $LOGSPATH/../../log/LTE-SIMS.log
done
done
fi
if [[ $SIMNAME == *"DG2"* ]]
then
/netsim/inst/netsim_pipe < 4994MOBulkUpDG2.pl.mml
else
/netsim/inst/netsim_pipe < 2994MOBulkUp.pl.mml
/netsim/inst/netsim_pipe < 2041createAdditionalLoadModules.pl.mml
fi

echo "************************************"
echo "./executeParallel.sh script ended running at" $(date +%T)
echo "************************************"
