#!/bin/sh
# Created by  : Fatih ONUR
# Created in  : 14.07.09
##
### VERSION HISTORY
# Ver1        : Created for LTE O 10.0 TERE 
# Purpose     : 
# Description : 
# Date        : 14 July 2009
# Who         : Fatih ONUR
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
####################################################################
# Version4    : ENM 17.7
# Revision    : CXP 903 0491-290-1
# JIRA        : NSS-9363
# Purpose     : Update SimNET build scripts so that it populates
#               ProcessorLoad MOs for all ERBS nodes
# Description : Create ProcessorLoad MO on ERBS node
# Date        : Mar 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : LTE 18.10
# Revision    : CXP 903 0491-337-1
# Purpose     : Creating MO files for each node
# Description : To ensure that MOs donot directly reflected into GUI
# Jira        : NSS-18645
# Date        : May 2018
# Who         : zyamkan
####################################################################
# Version5    : LTE 22.07
# Revision    : CXP 903 0491-383-1
# Purpose     : To make code errorfree
# Jira        : NSS-38412
# Date        : April 2022
# Who         : zjaisai
######################################################################
# Version6    : LTE 22.09
# Revision    : CXP 903 0491-384-1
# Purpose     : To remove errors in mml
# Jira        : NSS-38412
# Date        : May 2022
# Who         : zjaisai
#####################################################################
if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <env file> <rnc num>

Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1

CREATE :-PlugInUnit, GeneralProcessorUnit, ProcessorLoad, MediumAccessUnit, FastEthernet, TimingUnit, ExchangeTerminalIp, GigaBitEthernet

HELP

exit 1
fi


SIMNAME=$1
ENV=$2
LTE=$3
. ../../dat/$ENV


PWD=`pwd`

# if SIMNAME is of type PICO or DG2 do not execute script

# ex: LTESRBSV1x160-RVPICO-FDD-LTE02

if [[ $SIMNAME == *PICO* ]] || [[ $SIMNAME == *DG2* ]]; then
    exit
fi

NUMOFRBS="$SIMNAME" | awk -F "x" '{print $2}' | awk -F "-" '{print $1}';

i=1;
while [ $i -ne $NUMOFRBS ]
do
        rm -rf $0.mo$i;
        i=`expr $i + 1`;
done

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


#################
# PlugInUnit 
#################
NODE=1
while [ "$NODE" -le "$NUMOFRBS" ]
do

if [ $NODE -lt 10 ]
then
    nodezeros=0000
elif [ $NODE -lt 100 ]
then
    nodezeros=000
else
    nodezeros=00
fi

if [ $LTE -le 9 ]
then
    simnodename="LTE0$LTE"ERBS$nodezeros$NODE
else
    simnodename="LTE$LTE".ERBS.$nodezeros.$NODE
fi
COUNT=1
STOP=1

while [ "$COUNT" -le "$STOP" ]
do

cat >> $MOSCRIPT$NODE << MOSCT

CREATE
(
  parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT"
   identity 1
   moType PlugInUnit
   exception none
   nrOfAttributes 0
)


CREATE
(
  parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT"
    identity 1
    moType GeneralProcessorUnit
    exception none
    nrOfAttributes 0
)

CREATE
(
    parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,GeneralProcessorUnit=1"
    identity "1"
    moType ProcessorLoad
    exception none
    nrOfAttributes 0
)

  CREATE
  (
    parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,GeneralProcessorUnit=1"
      identity 1
      moType MediumAccessUnit
      exception none
      nrOfAttributes 0
  )

  CREATE
  (
    parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,GeneralProcessorUnit=1"
      identity 1
      moType FastEthernet
      exception none
      nrOfAttributes 0
  )

CREATE
(
  parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT"
    identity 1
    moType TimingUnit
    exception none
    nrOfAttributes 0
)

CREATE
(
  parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT"
    identity 1
    moType ExchangeTerminalIp
    exception none
    nrOfAttributes 0
)

  CREATE
  (
    parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,ExchangeTerminalIp=1"
      identity 1
      moType GigaBitEthernet
      exception none
      nrOfAttributes 0
  )
     CREATE
     (
       parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,ExchangeTerminalIp=1,GigaBitEthernet=1"
         identity 1
         moType IpInterface
         exception none
         nrOfAttributes 0
     )
     CREATE
     (
       parent "ManagedElement=1,Equipment=1,Subrack=1,Slot=$COUNT,PlugInUnit=$COUNT,ExchangeTerminalIp=1,GigaBitEthernet=1"
         identity 2
         moType IpInterface
         exception none
         nrOfAttributes 0
     )



MOSCT

COUNT=`expr $COUNT + 1`
done
COUNT=1




#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

cat >> $MMLSCRIPT << MMLSCT

.open $SIMNAME
.select $simnodename
.start
useattributecharacteristics:switch="off";
kertayle:file="$PWD/$MOSCRIPT$NODE";

MMLSCT
NODE=`expr $NODE + 1`
done

#$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

#rm $PWD/$MOSCRIPT
#rm $PWD/$MMLSCRIPT


