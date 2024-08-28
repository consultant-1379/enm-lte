#!/bin/sh
####################################################################            
# Ver         : LTE 15B         
# Revision    : CXP 903 0491-129-1
# Purpose     : LTE Nexus support design
# Description : Adds a file to zip for FT and RV
# Date        : 09 Mar 2015             
# Who         : edalrey         
#################################################################### 

if [ "$#" -ne 1  ]
then
cat<<HELP
####################
# HELP
####################

Usage  : $0 <sim name>

Example: $0 LTEA90-ST-LTE01
HELP
exit 1
fi

SIM=$1
simPath="/netsim/netsimdir/$SIM/"

temp1=${SIM##*x}
temp2=${temp1#*-}
NETWORKAREA=${temp2:0:2}
echo "INFO: Network area =  $NETWORKAREA"
if [ "$NETWORKAREA" == "FT" ];
then
	if [ ! -d $simPath  ];
	then
		echo "ERROR: Can't touch this: "$simPath"PENDING"
		echo "ERROR: The path $simPath does not exist."
	else
	       	touch "/netsim/netsimdir/$SIM/PENDING"
		echo "INFO: ${simPath}PENDING has been created."
	fi
elif [ "$NETWORKAREA" == "RV" ] || [ "$NETWORKAREA" == "ST" ];
then
	if [ ! -d $simPath  ];
	then
		echo "ERROR: Can't touch this: "$simPath"PENDING"
		echo "ERROR: The path $simPath does not exist."
	else
		touch "/netsim/netsimdir/$SIM/LATEST"
		echo "INFO: ${simPath}LATEST has been created."
	fi
else
	echo "Not a valid sim name";
fi
