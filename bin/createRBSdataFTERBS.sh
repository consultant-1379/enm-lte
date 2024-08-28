#!/bin/sh

# Created by  : unknown
# Created in  : unknown
##
### VERSION HISTORY
########################################################################
# Ver1        : Moddified for TERE 10.0
# Purpose     :
# Description :
# Date        : 01 09 2009
# Who         : Fatih ONUR
########################################################################
# Ver1        : Moddified in FT-LTE 0.11.1.1 ReqId:4951
# Purpose     : to catch errors output in a log file
# Description : If you want the stderr and stdout messages to appear in the right order, you'll need to use a subshell, like so:
# 		(ls -l 2>&1) > file.txt
# Date        : 21 07 2010
# Who         : Fatih ONUR
########################################################################
########################################################################
# Version2   : LTE 15B
# Purpose     : enable DG2 support
# Description : ensures DDG2 simulations can be auto created
# Date        : Feb 2015
# Who         : epatdal
########################################################################
####################################################################
# Version3    : 18.6
# Revision    : CXP 903 0491-331-1
# Jira        : NSS-17417
# Purpose     : Simulation script design during NETSim node start
# Description : Parallel execution of build scripts and netsim node start
# Date        : Feb 2018
# Who         : xkatmri
####################################################################
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

if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <count> <env file>

Example: $0 LTEA90-ST-LTE01 1 R7-ST-K-ERBSA90.env

HELP

exit 1
fi


SIM=$1
ENV=$3
COUNT=$2

. ../dat/$ENV

LOGFILE=$SIMDIR/log/LTE-SIMS.log

cd $SIMDIR/bin/$RBSDIR

#
## 2>&1 provides to catch errors into a log file
#

if [[ $SIM = *"PICO"* ]];then
  ( ./runScripts.sh $SIM $ENV $COUNT 3 2>&1 ) | tee -a $LOGFILE
  ( ./createTopologyFile.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE
  exit
fi

( ./runScripts.sh $SIM $ENV $COUNT 1 2>&1 ) | tee -a $LOGFILE

if [ "$TRANS" = "yes" ]
then
  ( ./runScripts.sh $SIM $ENV $COUNT 2 2>&1 ) | tee -a $LOGFILE
fi

if [ "$TRANS" = "yes" ]
then
  ( ./runScripts.sh $SIM $ENV $COUNT 4 2>&1 ) | tee -a $LOGFILE
fi

  ( ./createTopologyFile.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE
#  ( ./compileMOs.sh $SIM 2>&1 ) | tee -a $LOGFILE

