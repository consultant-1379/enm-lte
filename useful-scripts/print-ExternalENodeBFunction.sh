#!/bin/sh

# Created by  : Ronan Mehigan
# Created in  : 01/09/2009
##
### VERSION HISTORY
# Ver1        : Added in TERE 10.0 review
# Purpose     :
# Description :
# Date        : 01/09/2009
# Who         : Ronan Mehigan

if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <env file> <count> 

Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1

HELP

exit 1
fi


SIMNAME=$1
ENV=$2
LTE=$3

if [ "$LTE" -le "9" ]
then
 LTENAME="LTE0"$LTE"ERBS00"
else
 LTENAME="LTE"$LTE"ERBS00"
fi


. ../../dat/$ENV


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

echo "********************"
echo "LTE="$NENAME
echo "LOCAL ERBS"=$ERBSCOUNT
echo "TOTAL ERBS"=$ERBSTOTALCOUNT
echo "*******************"

while [ "$EXTENODEBID" -le "$EXTENODEBIDSTOP" ]
do


 if [ "$EXTENODEBID" -ne "$ERBSTOTALCOUNT" ]
 then

   echo 'CREATE' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"' >> $MOSCRIPT
   echo '   identity '$EXTENODEBID >> $MOSCRIPT
   echo '   moType ExternalENodeBFunction' >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 0' >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   echo "Creating ExternalENodeBFunction="$EXTENODEBID
 fi


EXTENODEBID=`expr $EXTENODEBID + 1`
done


#echo '.open '$SIMNAME >> $MMLSCRIPT
#echo '.select '$NENAME >> $MMLSCRIPT
#echo '.start ' >> $MMLSCRIPT
#echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
#echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

#$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

#rm $PWD/$MOSCRIPT
#rm $PWD/$MMLSCRIPT


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







































