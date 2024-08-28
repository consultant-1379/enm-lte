#!/bin/sh

# Created by  : unknown
# Created in  : unknown
##
### VERSION HISTORY
# Ver1        : Moddified for TERE 10.0
# Purpose     :
# Description :
# Date        : 01 09 2009
# Who         : Fatih ONUR
###########################################
# Version     : 22.07
# Purpose     : To get the basic nodetemplate 
# Description : Added the line in this script to get the basic node from the nodetemplate 
# Date        : 01 Apr 2022
# Who         : zjaisai
###########################################
if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <count> <env file>

Example: $0 LTEA90-ST-LTE01 1 R7-ST-K-ERBSA90.env

DESCRP : This will create a simulation and the NEs as defined in the env file

HELP

exit 1
fi

SIM=$1
COUNT=$2
ENV=$3

. ../dat/$ENV

./createSim.sh $SIM $ENV
./getNodeFromFtp.sh $SIM
./createSTERBS.sh $SIM $COUNT $ENV 


