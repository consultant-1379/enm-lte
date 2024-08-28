#!/bin/sh
####################################################################
# Ver1        : LTE 15B         
# Revision    : CXP 903 0491-129-1
# Purpose     : LTE Nexus support design
# Description : Simulation is uploaded to Nexus.
# Date        : 03 Mar 2015             
# Who         : edalrey         
####################################################################
# Version     : LTE 16.01
# Revision    : CXP 903 0491-186-1
# User Story  : NSS-1096 
# Purpose     : Integrate upload simulation on nexus to ENM-LTE scripts 
# Description : - Add logging to NEXUS upload
#               - Remove versioning from Simulation name
#               - Update path on NEXUS to more familiar format:
#                   ../simnet/ENM/XX.xx/LTE/{network description}/{sim name}.zip
# Date        : 06 Nov 2015
# Who         : edalrey
#################################################################### 
if [ "$#" -ne 2  ]
then
	echo
	echo "Usage: $0 <sim> <config file>"
	echo
	echo "Example: $0 LTEE1220x160-RV-FDD-LTE16  CONFIG.env"
	echo
	exit 1
fi
SIM=$1
ENV=$2
. ../dat/$ENV

LOGFILE="$(pwd)"
LOGFILE=${LOGFILE/bin/log/}
LOGFILE=$LOGFILE"LTE-SIMS.log"  

NETWORKAREA="LTE"
#################################
#   Format Network Type         #
#################################
nexusSim=$SIM
temp1=${SIM##*x}                                # Remove longest sub-string ending in 'x' from front of string
temp2=${temp1#*-}                               # Remove shortest sub-string ending in '-' from front of string
networkType="$(echo "$temp2" | sed 's/-.*//')"  # Remove longest sub-string starting in '-' from front of string
#################################
#   Upload simulation to Nexus  #
#################################
echo "Command to upload simulation using curl:"
echo "Command to upload simulation ($nexusSim) using curl:" >> $LOGFILE
echo "curl -k --upload-file /netsim/netsimdir/$SIM.zip -u simnet:simnet01 -v https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/ENM/$VERSION/$NETWORKAREA/$networkType/$nexusSim.zip"
echo "curl -k --upload-file /netsim/netsimdir/$SIM.zip -u simnet:simnet01 -v https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/ENM/$VERSION/$NETWORKAREA/$networkType/$nexusSim.zip" >> $LOGFILE
curl -k --upload-file /netsim/netsimdir/$SIM.zip -u simnet:simnet01 -v https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/ENM/$VERSION/$NETWORKAREA/$networkType/$nexusSim.zip
##############################
# END OF SCRIPT
##############################
