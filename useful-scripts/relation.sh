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

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 start

Example: $0 start

DESCRP : Print out cdma relation 

HELP

exit 1
fi


ERBSCOUNT=1

##############
NUMOFRBS=32
LTE=1
##############


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



while [ "$ERBSCOUNT" -le "$NUMOFRBS" ]
do




echo "****************************"
echo "working on ERBS"$ERBSCOUNT
echo "****************************"

CELLSTART=1
CELLSTOP=4
CELLCOUNT=$CELLSTART


while [ "$CELLCOUNT" -le "$CELLSTOP" ]
do

EXTENODEBID=$EXTENODEBIDSTART
EXTENODEBIDSTOP=`expr $EXTENODEBID + 15`

echo "working on cell "$CELLCOUNT

 TARGETCELLSTART=1
 TARGETCELLSTOP=4
 TARGETCELLCOUNT=$TARGETCELLSTART

 RELATIONID=1


 while [ "$TARGETCELLCOUNT" -le "$TARGETCELLSTOP" ]
 do

 if [ "$TARGETCELLCOUNT" -ne "$CELLCOUNT" ]
 then
 echo "creating relation "$RELATIONID" to targetcell "$TARGETCELLCOUNT 
 RELATIONID=`expr $RELATIONID + 1`
 fi

 TARGETCELLCOUNT=`expr $TARGETCELLCOUNT + 1`  
 done
  
 #at this point RELATIONID=4
 # Next create relations to External EUtranCells
 #

 while [ "$EXTENODEBID" -le "$EXTENODEBIDSTOP" ]
 do
 
 
   #####################################
   # An=4n-3
   ##################################### 

   TEMP1=`expr 4 \* $EXTENODEBID`
   XCELLSTART=`expr $TEMP1 - 3`
   XCELLCOUNT=$XCELLSTART
   XCELLSTOP=`expr $XCELLSTART + 3`
 
 
 if [ "$EXTENODEBID" -ne "$ERBSTOTALCOUNT" ]
 then
 echo "creating relations to External Cells under ExternalNodeBFunction="$EXTENODEBID
 
   while [ "$XCELLCOUNT" -le "$XCELLSTOP" ]
   do
    if [ "$CELLCOUNT" -le 2 ]
    then
     XCELLSTOP=`expr $XCELLSTART + 1`
     echo "creating relation to ExternalNodeBFunction="$EXTENODEBID"-ExternalEUtranCell="$XCELLCOUNT
     XCELLCOUNT=`expr $XCELLCOUNT + 1`
    else
     XCELLSTOP=`expr $XCELLSTART + 1`
     NEWXCELLCOUNT=`expr $XCELLCOUNT + 2`
     echo "creating relation to ExternalNodeBFunction="$EXTENODEBID"-ExternalEUtranCell="$NEWXCELLCOUNT
     XCELLCOUNT=`expr $XCELLCOUNT + 1`  
    fi
     
  
   done
 
 fi
 
 EXTENODEBID=`expr $EXTENODEBID + 1`
 done



CELLCOUNT=`expr $CELLCOUNT + 1`
done


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
