#!/bin/sh
# Created by  : Ronan Mehigan
# Created in  : 14.07.09
##
### VERSION HISTORY
# Ver1        : Created for LTE O 10.0 TERE
# Purpose     :
# Description :
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Ver2        : LTE 14A
# Purpose     : check sim type which is either PICO or LTE netork
# Description : checks the type of simulation based on PICO sim
#               naming convention and depending on if the script
#               is PICO network specific or not it either exits 
#               the script or executes it.               
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 15B
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <env file> <rnc num>

Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1

HELP

exit 1
fi

SIMNAME=$1
ENV=$2


. ../../dat/$ENV

PWD=`pwd`

# if SIMNAME is of type PICO or DG2 do not execute script
# ex: LTESRBSV1x160-RVPICO-FDD-LTE02
if [[ $SIMNAME == *PICO* ]] || [[ $SIMNAME == *DG2* ]]; then
    exit 
fi

MOSCRIPT=$SIMDIR/mo/$RBSDIR/swmgmt.mo
MMLSCRIPT=$0".mml"


if [ -f $PWD/$MMLSCRIPT ]
then
rm -r  $PWD/$MMLSCRIPT
echo "old "$PWD/$MMLSCRIPT " removed"
fi

#########################################
# 
# Make MO Script
#
#########################################

echo ""
echo "MAKING MO SCRIPT"
echo ""


#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.selectregexp simne .*' >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$MOSCRIPT'";' >> $MMLSCRIPT

$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

rm $PWD/$MMLSCRIPT



































