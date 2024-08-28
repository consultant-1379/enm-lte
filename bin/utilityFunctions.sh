#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 09 Jul 2010
##
### VERSION HISTORY
#############################################################################################
# Ver1        : Created to improve script's flexibility
# Purpose     : Better script design
# Description : File to be sourced in every simgen script to define some utility "good to have" functions
# Date        : 09.07.20010
# Who         : Fatih ONUR
#############################################################################################
# Ver2        : Modified during LTE O 11.1 TERE reiew
# Purpose     : Functions moved from individual script files to common file at here
# Description : 
# Date        : 05.11.20010
# Who         : Fatih ONUR
#############################################################################################

################################
# FUNCTIONS
################################
#
## Scripts will not run unless their type is FT
#
#
doNotRunThisIfSimTypeIsFT()
{
SIMTYPE=$1

if [ "$SIMTYPE" == "FT" ]
then
  echo "   This script run only for ST sims" 
  echo "     FT sims has alternative 3 series script slightly different than these script"
  echo "     Difference: FT sims has more populated mos than ST sims"
  echo ""
  echo "...script ended at "`date`
  echo ""
  exit
fi

}


## EUtranFreqRelation Algorithm Function ( added in v3)
#
# e.g where NUMOFEUTRANFREQRELATION is 4
#  EUtranFreqRelation=1 one can be points to n1=ERBS01, n2=ERBS05, n3=ERBS09, n4=ERBS13, nx where nx=(x*NUMOFUTRANRELATION) - (NUMOFUTRANRELATION-1) 
#  EUtranFreqRelation=2 one can be points to n1=ERBS02, n2=ERBS06, n3=ERBS10, n4=ERBS14, nx where nx=(x*NUMOFUTRANRELATION) - (NUMOFUTRANRELATION-1) 
#  EUtranFreqRelation=3 one can be points to n1=ERBS03, n2=ERBS07, n3=ERBS11, n4=ERBS15, nx where nx=(x*NUMOFUTRANRELATION) - (NUMOFUTRANRELATION-1) 
#  EUtranFreqRelation=4 one can be points to n1=ERBS04, n2=ERBS08, n3=ERBS12, n4=ERBS16, nx where nx=(x*NUMOFUTRANRELATION) - (NUMOFUTRANRELATION-1) 
#
#  EnodeB1-Cell-1 (Freq=1)
#	EUtranFreqRelation=1 (Freq=1)
#		EUtranCellRelation-1 reference to ENodeB1-Cell2
#		EUtranCellRelation-2 reference to ENodeB1-Cell3
#		EUtranCellRelation-3 reference to ENodeB1-Cell3
#	EUtranFreqRelation=2 (Freq=2)
#		EUtranCellRelation-4 reference to ENodeB2-Cell1
#		EUtranCellRelation-5 reference to ENodeB2-Cell2
#	EUtranFreqRelation=3 (Freq=3)
#		EUtranCellRelation-6 reference to ENodeB3-Cell1
#		EUtranCellRelation-7 reference to ENodeB3-Cell2
#	EUtranFreqRelation=4 (Freq=4)
#		EUtranCellRelation-8 reference to ENodeB4-Cell1
#		EUtranCellRelation-9 reference to ENodeB4-Cell2
#
## get num of EutranFrequency for each erbs, according to specified percantage
#
#
getEUtranFreqID_NUM() # ERBSTOTALCOUNT,"ID"/"NUM"
{
ERBSTOTALCOUNT=$1
KEY=$2

#
# User Configurable
# Num of nodes/erbs within network
#
NUMOFSIMS=47
NUMOFRBS=160
TOTALNODES=`expr \( $NUMOFRBS \* $NUMOFSIMS \)`

#
# User Configurable
# Num of frequency per erbs for each band
#
BAND_A=8
BAND_B=4
BAND_C=2
BAND_D=1

#
# User Configurable
# Percantage portion of each band
#
BAND_A_PERC=6
BAND_B_PERC=6
BAND_C_PERC=48
BAND_D_PERC=40

#
# Not User Configurable
# Calculated percantage portion of each band
#
BAND_B_SWITCH_PERC=`expr $BAND_A_PERC + 0`
BAND_C_SWITCH_PERC=`expr $BAND_A_PERC + $BAND_B_PERC`
BAND_D_SWITCH_PERC=`expr $BAND_A_PERC + $BAND_B_PERC + $BAND_C_PERC`


#
# Not User Configurable
# Calculated switch cell percantage portion of each band
#
SWITCH_TO_BAND_B=`expr \( $TOTALNODES \* $BAND_B_SWITCH_PERC \) / 100 + 1`
SWITCH_TO_BAND_C=`expr \( $TOTALNODES \* $BAND_C_SWITCH_PERC \) / 100 + 1`
SWITCH_TO_BAND_D=`expr \( $TOTALNODES \* $BAND_D_SWITCH_PERC \) / 100 + 1`
#echo "SWITCH_TO_BAND_B="$SWITCH_TO_BAND_B
#echo "SWITCH_TO_BAND_C="$SWITCH_TO_BAND_C
#echo "SWITCH_TO_BAND_D="$SWITCH_TO_BAND_D

#
# Not User Configurable
# Num of frequency are set according to within defined percantage volume
#
if [ "$ERBSTOTALCOUNT" -ge "1" ]
then
  NUMOFEUTRANFREQ=$BAND_A
fi

if [ "$ERBSTOTALCOUNT" -ge "$SWITCH_TO_BAND_B" ]
then
  NUMOFEUTRANFREQ=$BAND_B
fi

if [ "$ERBSTOTALCOUNT" -ge "$SWITCH_TO_BAND_C" ]
then
  NUMOFEUTRANFREQ=$BAND_C
fi

if [ "$ERBSTOTALCOUNT" -ge "$SWITCH_TO_BAND_D" ]
then
  NUMOFEUTRANFREQ=$BAND_D
fi

#echo $NUMOFEUTRANFREQ

MOD=`expr $ERBSTOTALCOUNT % $NUMOFEUTRANFREQ`
if [ "$MOD" -eq 0 ]
then
  EUTRANFREQID=$NUMOFEUTRANFREQ
else
  EUTRANFREQID=$MOD
fi

if [ "$KEY" == "ID" ]
then
  echo $EUTRANFREQID
else
  echo $NUMOFEUTRANFREQ
fi

}

#
## Calculates total ERBS number up to current ERBS
#
#
getERBSTotalCount() # ERBSCOUNT, LTE, NUMOFRBS
{
 ERBSCOUNT=$1
 LTE=$2
 NUMOFRBS=$3
 TEMP=`expr $LTE \* $NUMOFRBS` # NUMOFRBS come from env file
 MINUS=$NUMOFRBS
 ERBSTOTALCOUNT=`expr $ERBSCOUNT + $TEMP - $MINUS`

 echo $ERBSTOTALCOUNT
}

#
## Returns ExternalEUtranCellName userlabel
#
#
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


## Returns ExternalNodeBfunction userlabel
#
#
getExtENodeBName() # ERBSCOUNT, NUMOFRBS
{
ERBSCOUNT=$1
NUMOFRBS=$2
MOD=`expr $ERBSCOUNT % $NUMOFRBS`

 if [ "$MOD" -eq 0 ]
 then
   ERBSCOUNT=$NUMOFRBS
 else
   ERBSCOUNT=$MOD
 fi

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

