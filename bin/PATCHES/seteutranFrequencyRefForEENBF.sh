#!/bin/sh

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

################################
# Functions
################################

getExEUtranCellName() # ERBSCOUNT CELLCOUNT
{
ERBSCOUNT=$1
CELLCOUNT=$2

 if [ "$ERBSCOUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$ERBSCOUNT
 else 
   if [ "$ERBSCOUNT" -le 99 ] 
   then
     NENAME=${LTENAME}"0"$ERBSCOUNT
   else 
     NENAME=${LTENAME}$ERBSCOUNT
   fi
 fi

EXEUTRANCELLNAME=$NENAME-$CELLCOUNT

echo $EXEUTRANCELLNAME
}

getExENodeBName() # ERBSCOUNT 
{
ERBSCOUNT=$1

 if [ "$ERBSCOUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$ERBSCOUNT
 else
   if [ "$ERBSCOUNT" -le 99 ]
   then
     NENAME=${LTENAME}"0"$ERBSCOUNT
   else
     NENAME=${LTENAME}$ERBSCOUNT
   fi
 fi

EXENODEBNAME=$NENAME

echo $EXENODEBNAME
}



######################################

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

echo ""
echo "MAKING MO SCRIPT"
echo ""

############################################
#
# LTE01ERBS01 has ExternalENodeBFunction 1-16 !1
# LTE01ERBS02 has ExternalENodeBFunction 1-16 !2
# LTE01ERBS03 has ExternalENodeBFunction 1-16 !3
# . . . . . . . . . . . . .  . . . . . . . 
# . . . . . . . . . . . . . . . . . . . . .
# LTE01ERBS16 has ExternalENodeBFunction 1-16 !16
#
# LTE01ERBS17 has ExternalENodeBFunction 17-32 !17 
# LTE01ERBS18 has ExternalENodeBFunction 17-32 !18 ...etc
#
# .......etc
#
# LTE02ERBS01 has ExternalENodeBFunction 161-176 !161
# LTE02ERBS02 has ExternalENodeBFunction 161-176 !162
#
# LTE02ERBS16 has ExternalENodeBFunction 161-176 !176
#
# LTE02ERBS17 has ExternalENodeBFunction 177-192 !177
#
#  ......etc
#
############################################

ERBSCOUNT=1

###########################################
#
# LTE01 has 160 ERBS, so the first ERBS is ERBSID=1
# LTE02 has 160 ERBS, so the first ERBS is ERBSID=161 ...etc
#
# An = A1 + d (n -1)
# An = 1 + 160(n-1)
# An = 160n - 159
#
#
###########################################

TEMP=`expr $LTE \* $NUMOFRBS`
MINUS=`expr $NUMOFRBS - 1`
EXTENODEBIDSTART=`expr $TEMP - $MINUS`


# ERBSTOTALCOUNT keeps of count of the total number of ERBSs in network

ERBSTOTALCOUNT=$EXTENODEBIDSTART


while [ "$ERBSCOUNT" -le "$NUMOFRBS"  ]
do
 echo '.open '$SIMNAME > $MMLSCRIPT
 if [ "$ERBSCOUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$ERBSCOUNT
 else
   if [ "$ERBSCOUNT" -le 99 ]
   then
     NENAME=${LTENAME}"0"$ERBSCOUNT
   else
     NENAME=${LTENAME}$ERBSCOUNT
   fi
 fi




EXTENODEBID=$EXTENODEBIDSTART
EXTENODEBIDSTOP=`expr $EXTENODEBID + 15`

#echo "********************"
#echo "LTE="$NENAME
#echo "LOCAL ERBS"=$ERBSCOUNT
#echo "TOTAL ERBS"=$ERBSTOTALCOUNT
#echo "*******************"

while [ "$EXTENODEBID" -le "$EXTENODEBIDSTOP" ]
do


 if [ "$EXTENODEBID" -ne "$ERBSTOTALCOUNT" ]
 then

   CELLSTART=1
   CELLCOUNT=$CELLSTART
   CELLSTOP=$CELLNUM

   while [ "$CELLCOUNT" -le "$CELLSTOP" ]
   do
 
   USERLABEL=`getExEUtranCellName $EXTENODEBID $CELLCOUNT`
   
   echo 'SET' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo "  mo ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$CELLCOUNT >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 1' >> $MOSCRIPT
   echo "    eutranFrequencyRef Ref null" >> $MOSCRIPT
   echo ')' >> $MOSCRIPT


   CELLCOUNT=`expr $CELLCOUNT + 1`
   done


#   echo "Creating ExternalENodeBFunction="$EXTENODEBID
 fi


EXTENODEBID=`expr $EXTENODEBID + 1`
done


echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$NENAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT


REM=`expr $ERBSCOUNT \% 16`
if [ "$REM" -eq "0" ]
then 
 EXTENODEBIDSTART=`expr $EXTENODEBIDSTART + 16`
else
 echo "dont change it" >> /dev/null
fi

ERBSTOTALCOUNT=`expr $ERBSTOTALCOUNT + 1`
ERBSCOUNT=`expr $ERBSCOUNT + 1`
done

