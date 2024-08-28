#!/bin/sh
# VERSION HISTORY
##############################################################
# Version1    : Modified for TERE 10.0
# Purpose     :
# Description :
# Date        : 01 09 2009
# Who         : Fatih ONUR
##############################################################
# Version2    :
# Jira        : NETSUP 1019
# Purpose     : enable Pico support
# Description : ensures Pico simulations can be auto created
# Date        : Nov 2013
# Who         : epatdal
##############################################################
# Version3    : LTE 15B
# Purpose     : enable DG2 support
# Description : ensures DDG2 simulations can be auto created
# Date        : Feb 2015
# Who         : epatdal
##############################################################
# Version4    : 16.6
# Revision    : CXP 903 0491-204-1 
# Jira        : NSS-2548
# Purpose     : remove call to writeSimBuildData.pl 
# Description : move call to writeSimBuildData.pl to 
#               createDataSTERBS.pl
# Date        : March 2016
# Who         : ejamfur
##############################################################
# Version5    : 18.6
# Revision    : CXP 903 0491-331-1
# Jira        : NSS-17417
# Purpose     : Simulation script design during NETSim node start
# Description : Parallel execution of build scripts and netsim node start
# Date        : Feb 2018
# Who         : xkatmri
####################################################################
####################################################################
# Version6    : LTE 18.10
# Revision    : CXP 903 0491-337-1
# Purpose     : To reduce the simulation build time
# Description : This script executes the kertayles generated
#               per node
# Jira        : NSS-18645
# Date        : May 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version7    : LTE 20.14
# Revision    : CXP 903 0491-364-1
# Purpose     : Delete the System Created MOs
# Description : Deleting System created Mos
# Jira        : NSS-32040
# Date        : Aug 2020
# Who         : zanavee
####################################################################

if [ "$#" -ne 1 ]
then
cat<<HELP

####################
# HELP
####################
Usage  : $0 <network configuration env file>

Example: $0 CONFIG.env

DESCRP : This will create a new simulation and the NEs as defined  in the env file
HELP

exit 1
fi
################################
# Assign variables
################################

ENV=$1
DATE=`date +%H%M%S`
PWD=`pwd`

##############################
# Check env file exists
##############################

if [ ! -f ../dat/$ENV ]
then
 echo "The configuration file $ENV does not exist."
 exit 1
fi
#########################################
# Check that the user does not assume he
# can control where to put simulations
#########################################

if [ -n "$NETSIMDIR" ]; then
    # *** Note *** 
    # Assuming simulations are stored in default dir $HOME/netsimdir
    echo "Use of NETSIMDIR other than the default is currently not"
    echo "supported (current value: $NETSIMDIR)"
    echo "SimGen assumes that simulations are saved in $HOME/netsimdir."
    exit 1
fi

################################
# Source env file
################################

. ../dat/$ENV
LOGFILE=$SIMDIR/log/LTE-SIMS.log

if [ -f $LOGFILE ]
then
rm -r  $LOGFILE
echo "old $LOGFILE log file removed"
fi

getSimname() # RNCnumber 
{
     if [ "$1" -le 9 ]
     then
	 echo "$SIMBASE"-LTE0"$1"
     else
	 echo "$SIMBASE"-LTE"$1"
     fi
}


checkExistingSimulation() #Simname
{
 if [ -f "$HOME/netsimdir/$1.zip" ]; then
     # *** Note *** 
     # Assuming simulations are stored in default dir $HOME/netsimdir
     echo "Simulation $HOME/netsimdir/$1.zip"
     echo "already exists. Delete it and run again."
     exit 2
 fi
}

checkCellRestriction()
{
  # Check that number of cells is a multiple of 4
  # some algorithms may fail otherwise
  REM=`expr \( $NUMOFRBS \* $CELLNUM \) % 4`
  if [ "$REM" -ne 0 ]; then
     echo " **************************************** " | tee -a $LOGFILE
     echo " WARNING: Number of cells is not a "        | tee -a $LOGFILE
     echo " multiple of 4. Some algorithms may fail. " | tee -a $LOGFILE
     echo " **************************************** " | tee -a $LOGFILE   
  fi 
}
################################
# Main program
################################
echo "Start at `date`" | tee -a $LOGFILE
##########################
# START : ERBS sim build
##########################
# Just check the first simulation
checkExistingSimulation `getSimname $SIMSTART`

checkCellRestriction

# do we need LTE nodes if 0 then LTE sims not needed
if [ $SIMSTART -eq 0 ] || [[ $SIMEND -eq 0 ]]; then
   COUNT=999999
 else
   COUNT=$SIMSTART
fi 

while [ "$COUNT" -le "$SIMEND" ]
do

 if [ "$COUNT" -le 9 ]
 then
  SIM=$SIMBASE"-LTE0"$COUNT
 else
  SIM=$SIMBASE"-LTE"$COUNT
 fi

 echo " ***************************" >> $LOGFILE
 echo " *      $SIM               *" >> $LOGFILE
 echo " ***************************" >> $LOGFILE

 echo '****************************************************'
 echo "./createSimulationSTERBS.sh $SIM $ENV $COUNT"
 echo '****************************************************'
 ./createSimulationSTERBS.sh $SIM $COUNT $ENV
 echo '****************************************************'
 echo "./createRBSdataFTERBS.sh $SIM $COUNT $ENV"
 echo '****************************************************'
  ./createRBSdataFTERBS.sh $SIM $COUNT $ENV
 
 cd $SIMDIR/bin/$RBSDIR

 echo '****************************************************'
# echo "./executeMMLs.pl $SIM $ENV $COUNT"
 echo "./executeParallel.sh $SIM $ENV $COUNT"
 echo '****************************************************'
# ( ./executeMMLs.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE
 (./executeParallel.sh $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE

 cd $SIMDIR/bin

 echo '****************************************************'
 echo "./createDataSTERBS.pl $SIM $ENV $COUNT"
 echo '****************************************************'
 ( ./createDataSTERBS.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE

COUNT=`expr $COUNT + 1`
done
##########################
# END : ERBS sim build
##########################
##########################
# START : PICO sim build
##########################
# do we need PICO nodes if 0 then PICO sims not needed
if [ $PICOSIMSTART -eq 0 ] || [[ $PICOSIMEND -eq 0 ]]; then
   COUNT=999999
 else
   COUNT=$PICOSIMSTART
fi
# verify intergrity of CONFIG.env 
# staring PICO sim number ie. PICOSIMSTART
# and ending LTE sim number ie. SIMEND

if [ $SIMEND -ge $PICOSIMSTART ] && [[ $PICOSIMSTART -ne 0 ]]; then
   echo "FATAL ERROR : Cannot create PICO sims as CONFIG.env LTESIMEND $SIMEND is greater than/equal to PICOSIMEND $PICOSIMSTART - PICOSIMSTART value MUST BE greater than the SIMEND value" >> $LOGFILE
   echo "FATAL ERROR : creating PICO sims. - check ../log/LTE-SIMS.log for further details"
   COUNT=999999
fi 

while [ "$COUNT" -le "$PICOSIMEND" ]
do

 if [ "$COUNT" -le 9 ]
 then
  SIM=$PICOSIMBASE"-LTE0"$COUNT
 else
  SIM=$PICOSIMBASE"-LTE"$COUNT
 fi

 echo " ***************************" >> $LOGFILE
 echo " *      $SIM               *" >> $LOGFILE
 echo " ***************************" >> $LOGFILE

 echo '****************************************************'
 echo "./createPICOsim.pl `getSimname $SIMSTART` $ENV $COUNT"
 echo '****************************************************'
 ./createPICOsim.pl $SIM
 echo '****************************************************'
 echo "./createDataSTERBS.pl `getSimname $SIMSTART` $ENV $COUNT"
 echo '****************************************************'
 ./createDataSTERBS.pl $SIM $ENV $COUNT

COUNT=`expr $COUNT + 1`
done
##########################
# END : PICO sim build
##########################
##########################
# START : DG2 sim build
##########################
# do we need DG2 nodes if 0 then DG2 sims not needed
if [ $DG2SIMSTART -eq 0 ] || [[ $DG2SIMEND -eq 0 ]]; then
   COUNT=999999
 else
   COUNT=$DG2SIMSTART
fi
# verify intergrity of CONFIG.env
# staring DG2 sim number ie. DG2SIMSTART
# and ending LTE sim number ie. SIMEND

if [ $SIMEND -ge $DG2SIMSTART ] && [[ $DG2SIMSTART -ne 0 ]]; then
   echo "FATAL ERROR : Cannot create DG2 sims as CONFIG.env LTESIMEND $SIMEND is greater than/equal to DG2SIMEND $DG2SIMSTART - DG2SIMSTART value MUST BE greater than the SIMEND value" >> $LOGFILE
   echo "FATAL ERROR : creating DG2 sims. - check ../log/LTE-SIMS.log for further details"
   COUNT=999999
fi

while [ "$COUNT" -le "$DG2SIMEND" ]
do

  if [ "$COUNT" -le 9 ]
   then
  SIM=$DG2SIMBASE"-LTE0"$COUNT
   else
  SIM=$DG2SIMBASE"-LTE"$COUNT
  fi


  echo " ***************************" >> $LOGFILE
  echo " *      $SIM               *" >> $LOGFILE
  echo " ***************************" >> $LOGFILE

 echo '****************************************************'
 echo "./createDG2sim.pl $SIM"
 echo '****************************************************'
  ./createDG2sim.pl $SIM &
 echo '****************************************************'
 echo "./createRBSdataFTERBS.sh $SIM $COUNT $ENV"
 echo '****************************************************'
  ./createRBSdataFTERBS.sh $SIM $COUNT $ENV &

 wait

 cd $SIMDIR/bin/$RBSDIR

 echo '****************************************************'
# echo "./executeMMLs.pl $SIM $ENV $COUNT"
 echo "./executeParallel.sh $SIM $ENV $COUNT"
 echo '****************************************************'
# ( ./executeMMLs.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE
 ( ./executeParallel.sh $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE

 cd $SIMDIR/bin/$RBSDIR

 echo '****************************************************'
 echo "./delSysCreatedMos.sh $SIM"
 echo '****************************************************'
 ( ./delSysCreatedMos.sh $SIM 2>&1 ) | tee -a $LOGFILE
 
 cd $SIMDIR/bin

 echo '****************************************************'
 echo "./createDataSTERBS.pl $SIM $ENV $COUNT"
 echo '****************************************************'
 ( ./createDataSTERBS.pl $SIM $ENV $COUNT 2>&1 ) | tee -a $LOGFILE

  COUNT=`expr $COUNT + 1`
done
##########################
# END : DG2 sim build
##########################


echo "Done at `date`" | tee -a $LOGFILE

