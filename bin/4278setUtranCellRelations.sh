#!/bin/sh
#Script Name: Set externalUtrancellFDDRef
#set -x
SIMNAME=$1
echo SIMNAME=$SIMNAME
ENV=$2
echo ENV=$ENV
LTE=$3
echo LTE=$LTE
PWD=`pwd`
echo $PWD
if [[ $SIMNAME != *DG2* ]]; then
    exit
fi
if [[ $SIMNAME == *TDD* ]]
then
   CELLTYPE="Lrat:ExternalUtranCellTDD"
else
   CELLTYPE="Lrat:ExternalUtranCellFDD"
fi
echo CELLTYPE=$CELLTYPE
CELLTYPE1="Lrat:UtranCellRelation"
echo -e ".open $SIMNAME \n .select network \n .start " | /netsim/inst/netsim_shell
sleep 30
NODELIST=$(echo -e '.open '$SIMNAME'\n.show simnes' | /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | awk '{print $1}')
echo NODELIST=$NODELIST
NODES=(${NODELIST// / })
for NODE in ${NODES[@]}
do
echo NODE=$NODE
ExternalUtranCellList=`echo -e '.open '$SIMNAME'\n.select '$NODE'\ne csmo:get_mo_ids_by_type(null,"'${CELLTYPE}'").' | /netsim/inst/netsim_shell | tail -n+6 | tr -d '\n' | tr -d '[:space:]' | sed 's/[][]//g'`
UtranCellList=`echo -e '.open '$SIMNAME'\n.select '$NODE'\ne csmo:get_mo_ids_by_type(null,"'${CELLTYPE1}'").' | /netsim/inst/netsim_shell | tail -n+6 | tr -d '\n' | tr -d '[:space:]' | sed 's/[][]//g'`
length=`echo -e '.open '$SIMNAME'\n.select '$NODE'\ne: lists:flatlength(csmo:get_mo_ids_by_type(null, "Lrat:ExternalUtranCellFDD")).'| /netsim/inst/netsim_shell | tail -n+6 | tr -d '\n' | tr -d '[:space:]' | sed 's/[][]//g'`
fddMoIds=(${ExternalUtranCellList//,/ })
moIds=(${UtranCellList//,/ })
length=${#fddMoIds[@]}
j=0
MOSCRIPT=$NODE"_extUtra1.mo"
if [ -e $MOSCRIPT ]
then
rm $MOSCRIPT
fi
for moId in ${moIds[@]}
do
LDN=`echo 'e csmo:mo_id_to_ldn(null,'$moId').' | /netsim/inst/netsim_shell -q -sim $SIMNAME -ne $NODE | tr -d '[:space:]' | sed 's/[][]//g'  | sed 's/"//g' `
Id=${fddMoIds[j]}
LDN1=`echo 'e csmo:mo_id_to_ldn(null,'$Id').' | /netsim/inst/netsim_shell -q -sim $SIMNAME -ne $NODE | tr -d '[:space:]' | sed 's/[][]//g'  | sed 's/"//g' | sed  -e 's/ComTop://g' | sed -e 's/Lrat://g' `
cat >> $MOSCRIPT << MOSC
SET
(
    mo "$LDN"
    exception none
    nrOfAttributes 1
    "externalUtranCellFDDRef" Ref "$LDN1"
)

MOSC
j=`expr $j + 1`

if [ $j == $length ]
then
j=0
fi
done
echo -e '.open '$SIMNAME' \n .select '$NODE' \n kertayle:file="'$PWD'/'$MOSCRIPT'";'  | /netsim/inst/netsim_shell
done
echo -e ".open $SIMNAME \n .select network \n .savenedatabase curr force" | /netsim/inst/netsim_shell
cp -r /netsim/netsimdir/$SIMNAME/saved/dbs/* /netsim/netsimdir/$SIMNAME/allsaved/dbs/

rm -f *.mo
