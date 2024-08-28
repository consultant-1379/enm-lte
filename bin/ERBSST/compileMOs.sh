#!/bin/sh
#Written by Kathak Mridha
#The scripts combines all the MO files into one single MO file

if [ "$#" -ne 1 ]
then
 echo
 echo "Usage: $0 <sim name>"
 echo
 echo "Example: $0 LTE18-Q1-V4x4-test-DG2-FDD-LTE01"
 echo
 exit 1
fi


SIMNAME=$1
NUMOFNODES=`printf "$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}'`

for i in `seq 1 $NUMOFNODES`
do

MOLIST=`ls *mo$i`

  for mofile in $MOLIST
  do

  cat $mofile >>Final.mo$i
    
  done

chmod 775 Final.mo$i

done


