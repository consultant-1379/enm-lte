#!/bin/sh
####################################################################            
# Ver         : [unknown]  
# Revision    : [unknown] 
# Purpose     : Saves and compresses a simulatin to /netsim/netsimdir/ 
# Description : Saves and compresses a simulatin to /netsim/netsimdir/ 
# Date        : [unknown] 
# Who         : [unknown] 
#################################################################### 
# Ver         : LTE 15B         
# Revision    : CXP 903 0491-129-1
# Purpose     : LTE Nexus support design
# Description : Appends Nexus naming convention to compressed file
#		when ENABLENEXUS is set to YES.
# Date        : 09 Mar 2015             
# Who         : edalrey         
#################################################################### 
####################################################################
# Version     : LTE 16.01
# Revision    : CXP 903 0491-186-1
# User Story  : NSS-1096 
# Purpose     : Integrate upload simulation on nexus to ENM-LTE scripts 
# Description : Disable adding Nexus naming convention from compressed
#               file when ENABLENEXUS is set to YES.
# Date        : 03 Dec 2015
# Who         : edalrey
###################################################################
####################################################################
# Version     : LTE 20.05
# Revision    : CXP 903 0491-357-1
# User Story  : NSS-27149 
# Purpose     : removes the logfiles and javafiles.
# Description : Include the patch to compress simulation size in LTE code base
# Date        : 24 Feb 2020
# Who         : xmitsin
###################################################################
. ../dat/$2

SIM=$1
MMLSCRIPT=saveAndCompressSimulation.mml
PWD=`pwd`

if [ "$#" -ne 2  ]
then
	echo
	echo "Usage: ./saveAndCompressSimulation.sh <sim name> <env file>"
	echo
	echo "Example: ./saveAndCompressSimulation.sh WegaC5LargeRNC14 WendyF.env"
	echo 
	exit 1
fi

if [ -f $PWD/$MOSCRIPT ]
then
	rm   $PWD/$MOSCRIPT
	echo "old "$PWD/$MOSCRIPT " removed"
fi

if [ -f $PWD/$MMLSCRIPT ]
then
	rm   $PWD/$MMLSCRIPT
	echo "old "$PWD/$MMLSCRIPT " removed"
fi

echo "#################### Start removing LOGFILES AND JAVA FILES ##########################"
echo "##############################################################################"

DIR=/netsim/netsimdir/
DIR1=/netsim/netsim_dbdir/simdir/netsim/netsimdir/

rm $DIR/$SIM/allsaved/fss/curr_*/c/java/*
rm $DIR/$SIM/allsaved/fss/curr_*/c/logfiles/alarm_event/*
rm $DIR/$SIM/allsaved/fss/curr_*/c/logfiles/audit_trail/*
rm $DIR/$SIM/allsaved/fss/curr_*/c/logfiles/availability/*
rm -rf $DIR/$SIM/allsaved/fss/curr_*/c/loadmodules_norepl/CXC1735*
rm $DIR1/$SIM/*/fs/c/java/*
rm $DIR1/$SIM/*/fs/c/logfiles/alarm_event/*
rm $DIR1/$SIM/*/fs/c/logfiles/audit_trail/*
rm $DIR1/$SIM/*/fs/c/logfiles/availability/*
rm -rf $DIR/$SIM/allsaved/fss/curr_*/c/pm_data/*
rm -rf $DIR1/$SIM/allsaved/fss/curr_*/c/pm_data/*
rm -rf $DIR/$SIM/allsaved/fss/curr_*/pm_data/*
rm -rf $DIR1/$SIM/allsaved/fss/curr_*/pm_data/*

echo "#################### Removed LOGFILES AND JAVA FILES ##########################"
echo "##############################################################################"


#########################################
#	Make MML Script
#########################################
echo '.open '$SIM >> $MMLSCRIPT
echo '.select network' >> $MMLSCRIPT
echo '.stop' >> $MMLSCRIPT
echo '.saveandcompress '$SIM' force' >> $MMLSCRIPT
#########################################
#	Run MML Script
#########################################
echo ""
echo "RUNNING MML SCRIPT"
echo ""
$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT
rm $PWD/$MMLSCRIPT
#########################################
#	End Script
#########################################
