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

if [ "$#" -ne 2  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <env file>

Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env

DESCRP : This will create a new simulation template

HELP

exit 1
fi


MMLSCRIPT=$0".mml"

SIM=$1
ENV=$2

. ../dat/$ENV


if [ -f $PWD/$MMLSCRIPT ]
then
rm -r  $PWD/$MMLSCRIPT
echo "old $MMLSCRIPT  removed"
fi


echo '.deletesimulation '$SIM' force' >> $MMLSCRIPT
echo '.new simulation '$SIM >> $MMLSCRIPT


echo ""
echo "RUNNING MML SCRIPT"
echo ""

$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

rm $PWD/$MMLSCRIPT
