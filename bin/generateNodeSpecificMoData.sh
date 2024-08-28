#!/bin/sh
###############################################################################
# Version1    : LTE 19.04
# Revision    : CXP 903 0491-349-1
# Jira        : NSS-22844
# Purpose     : Create specific moDumps for Nodes
# Description : Get the modata from the nodes and store them in SimNetRevision
# Date        : Feb 2019
# Who         : xharidu
###############################################################################
SIM=$1
NodesList=`echo -e '.open '$SIM' \n .show simnes' | /netsim/inst/netsim_shell | grep "LTE " | cut -d" " -f1`
NODES=(${NodesList// / })
if [[ $SIM == *"DG2"* ]]
then
   Molist=( Lrat:EUtranCellFDD Lrat:EUtranCellRelation Lrat:ExternalENodeFunction Lrat:TermPointToENB Lrat:ExternalEUtranCellFDD Lrat:PmEventService)
else
   Molist=( EUtranCellFDD EUtranCellRelation EUtranFreqRelation ExternalENodeFunction TermPointToENB )
fi
### copying to Simulation #############
mkdir /netsim/netsimdir/$SIM/SimNetRevision/MoData/
#### Running For Nodes ##################
for NODE in ${NODES[@]}
do
   MOSCRIPT=$NODE".mo"
### Running for Each motype #############
   for MOTYPE in ${Molist[@]}
   do
      MOIDSSTR=`echo -e '.open '$SIM' \n .select '$NODE' \n.start \ne: csmo:get_mo_ids_by_type(null,"'$MOTYPE'").' | /netsim/inst/netsim_shell | tail -n+8`
      MOIDS=$(echo $MOIDSSTR | sed 's/\[//g' | sed 's/\]//g')
      MOIDS=(${MOIDS//,/ })
      MMLSCRIPT=$NODE".mml"
      if [ -e $MMLSCRIPT ]
      then
         rm $MMLSCRIPT
      fi
      cat >> $MMLSCRIPT << MML
.open $SIM
.select $NODE
MML
      for moId in ${MOIDS[@]}
      do
         echo -e 'dumpmotree:moid="'$moId'",ker_out,outputfile="/'$PWD'/'$MOTYPE'_'$moId'.mo";' >> $MMLSCRIPT
      done
      /netsim/inst/netsim_shell < $MMLSCRIPT
      rm $MMLSCRIPT
      for moId in ${MOIDS[@]}
      do
         sed -e '/)/,$d' $MOTYPE"_"$moId".mo" >> $MOSCRIPT
         echo ")" >> $MOSCRIPT
         rm $MOTYPE"_"$moId".mo"
      done
   done
   cp $MOSCRIPT /netsim/netsimdir/$SIM/SimNetRevision/MoData/
done
