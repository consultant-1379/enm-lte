#!/bin/sh
####################################################################
# Ver         : LTE 15B
# Revision    : CXP 903 0491-129-1
# Purpose     : LTE Nexus support design
# Description : Choose the upload location for simulations
# Date        : 03 Mar 2015
# Who         : edalrey
####################################################################
####################################################################
# Ver         : LTE 17A
# Revision    : CXP 903 0491-245-1
# Purpose     : LTE test build support
# Description : Choose whether to upload the simulations to NEXUS/FTP
#               or not to upload at all
# Date        : August 2016
# Who         : xravlat
####################################################################

if [ "$#" -ne 2  ]
then
cat<<HELP
####################
# HELP
####################

Usage  : $0 <sim name> <env file>

Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env
HELP
exit 1
fi

SIM=$1
ENV=$2
. ../dat/$ENV

LOGFILE="$(pwd)"
LOGFILE=${LOGFILE/bin/log/}
LOGFILE=$LOGFILE"LTE-SIMS.log"

if [ "$ENABLEUPLOAD" = "YES" ];
then
if [ "$ENABLENEXUS" = "NO" ];
then
	echo "ftp server is used";
	echo "ftp server is used" >> $LOGFILE;
 	./ftp.sh $SIM $ENV;
elif [ "$ENABLENEXUS" = "YES" ];
then
	echo "nexus server is used";
	echo "nexus server is used" >> $LOGFILE;
	./nexus.sh $SIM $ENV;
else
	echo "ERROR: The value of ENABLENEXUS must be set in $ENV (YES | NO).";
	echo "ERROR: The value of ENABLENEXUS must be set in $ENV (YES | NO)." >> $LOGFILE;
fi
else
        echo "NOT UPLOADING: No simulation will be uploaded to NEXUS/FTP as ENABLEUPLOAD is set to NO is $ENV";
        echo "NOT UPLOADING: No simulation will be uploaded to NEXUS/FTP as ENABLEUPLOAD is set to NO is $ENV"; >> $LOGFILE;
fi
