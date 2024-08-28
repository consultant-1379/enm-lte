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

HELP

exit 1
fi

START=1
STOP=25
COUNT=$START
ENV=R7-ST-G-ERBSA70.env

while [ "$COUNT" -le "$STOP" ]
do

 if [ "$COUNT" -le "9" ]
 then
  SIM="LTEA70-ST-LTE0"$COUNT
  LOG="ExternalENodeBFunction-LTE0"$COUNT"-withCells.txt"
 else
  SIM="LTEA70-ST-LTE"$COUNT
  LOG="ExternalENodeBFunction-LTE"$COUNT"-withCells.txt"
 fi

./print-ExternalENodeBFunction2.sh $SIM $ENV $COUNT | tee -a $LOG

COUNT=`expr $COUNT + 1`
done
