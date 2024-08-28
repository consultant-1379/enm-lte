#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 28.02.10
##
### VERSION HISTORY
# Ver1        : Created for Senan Coffey req id:3415 
# Purpose     : Set "eutranFrequencyRef" 
# Description :
# Date        : 28 Feb 2010
# Who         : Fatih ONUR

if [ "$#" -ne 2  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <lte num>

Example: $0 LTEA930-FT-LTE01 1

HELP

exit 1
fi

SIMNAME=$1
LTE=$2

# added instead of env file
NUMOFRBS=100
CELLNUM=4

NETSIMVERSION=inst
NETSIMDIR=$HOME

if [ "$LTE" -le "9" ]
then
 LTENAME="LTE0"$LTE"ERBS00"
else
 LTENAME="LTE"$LTE"ERBS00"
fi



PWD=`pwd`

MOSCRIPT=$0".mo"
MMLSCRIPT=$0".mml"

if [ -f $PWD/$MOSCRIPT ]
then
rm -r  $PWD/$MOSCRIPT
echo "old "$PWD/$MOSCRIPT " removed"
fi

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

#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

COUNT=1

while [ "$COUNT" -le "$NUMOFRBS"  ]
do
 echo '.open '$SIMNAME > $MMLSCRIPT
 if [ "$COUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$COUNT
 else 
   if [ "$COUNT" -le 99 ] 
   then
     NENAME=${LTENAME}"0"$COUNT
   else 
     NENAME=${LTENAME}$COUNT
   fi
 fi

CELLCOUNT=1
while [ "$CELLCOUNT" -le "$CELLNUM" ]
do
cat >> $MOSCRIPT << MOSCT
SET
(
   mo "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1"
   exception none
    nrOfAttributes 1
      "eutranFrequencyRef" Ref null 
)
MOSCT
CELLCOUNT=`expr $CELLCOUNT + 1`
done

 echo '.select '$NENAME >> $MMLSCRIPT 
 echo '.start ' >> $MMLSCRIPT
 echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
 echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT
 $NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT
 COUNT=`expr $COUNT + 1`
 rm $PWD/$MOSCRIPT
done

rm $PWD/$MMLSCRIPT

