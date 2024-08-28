#!/bin/sh

if [ "$#" -ne 4  ]
then
 echo
 echo "Usage: $0 <sim name> <env file> <rnc num> <script number>"
 echo
 echo "Example: $0 RNCH2030-FT-RNC01 SIM1.env 1 3"
 echo
 exit 1
fi


SIMNAME=$1
ENV=$2
COUNT=$3
SCRIPTNO=$4

if [ "$SCRIPTNO" -eq 3 ]
then

SCRIPTLIST=`ls "$SCRIPTNO"*.??`

  for script in $SCRIPTLIST
  do
    echo '****************************************************' 
    echo "./$script $SIMNAME $ENV $COUNT" 
    echo '****************************************************' 
    ./$script $SIMNAME $ENV $COUNT
  done

else

SCRIPTLIST=`ls "$SCRIPTNO"*.??`

  for script in $SCRIPTLIST
  do
    echo '****************************************************' 
    echo "./$script $SIMNAME $ENV $COUNT" 
    echo '****************************************************' 
    ./$script $SIMNAME $ENV $COUNT & 
  done

fi


