#!/bin/sh

# Created by  : unknown
# Created in  : unknown
##
### VERSION HISTORY
# Ver1        : Moddified for TERE 10.0
# Purpose     : 
# Description : 
# Date        : 01 09 2009
# Who         : Fatih ONUR
#########################################
# Version2    : LTE 16.10
# Revision    : CXP 903 0491-226-1
# Jira        : NSS-4048
# Purpose     : Update Sims with dummy SL2 configuration
# Description : Set SL2 on ERBS sims
# Date        : June 2016
# Who         : xkatmri
##########################################
# Version3    : LTE 16.11
# Revision    : CXP 903 0491-231-1
# Jira        : NSS-4547
# Purpose     : SL1/SL2 configuration with switch
# Description : Setting a condition to check for SL1 or SL2
# Date        : June 2016
# Who         : xkatmri
##########################################
# Version4    : LTE 16.12
# Revision    : CXP 903 0491-241-1
# Jira        : NSS-5297
# Purpose     : Start Nodes parallely
# Description : To start ERBS Nodes parallely
# Date        : June 2016
# Who         : xsrilek
##########################################
#################################################################### 
# Version5    : 18.6    
# Revision    : CXP 903 0491-331-1
# Jira        : NSS-17417
# Purpose     : Simulation script design during NETSim node start
# Description : Parallel execution of build scripts and netsim node start
# Date        : Feb 2018
# Who         : xkatmri
####################################################################
#Version6     : 22.07
#Revision     : CXP 903 0491-383-1
#Jira         : NSS-38412
#Purpose      : To delete basic node in ERBS sim
#Description  : Updated 2 lines in the script to delete the basicnode after simulation creation 
#Date         : Apr 2022
#Who          : zjaisai
#####################################################################
if [ "$#" -ne 3  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <count> <env file>

Example: $0 LTEA90-ST-LTE01 1 R7-ST-K-ERBSA90.env 

HELP

exit 1
fi


MMLSCRIPT=$0$$".mml"

SIM=$1
COUNT=$2
ENV=$3
RBSNAME=ERBS01

. ../dat/$ENV


if [ "$COUNT" -le 9 ]
then
 LTENAME="LTE0"$COUNT"ERBS"
 LTECOUNT="0"$COUNT
else
 LTENAME="LTE"$COUNT"ERBS"
 LTECOUNT=$COUNT
fi



if [ -f $PWD/$MMLSCRIPT ]
then
rm -r  $PWD/$MMLSCRIPT
echo "old $MMLSCRIPT  removed"
fi

    echo '.open '$SIM >> $MMLSCRIPT
    echo '.createne checkport '$PORT >> $MMLSCRIPT
    echo '.set preference positions 5' >> $MMLSCRIPT
    echo '.new simne -auto '$NUMOFRBS $LTENAME' 00001' >> $MMLSCRIPT
    echo '.set netype LTE ERBS '$NODETYPE3 >> $MMLSCRIPT
    echo '.set port '$PORT >> $MMLSCRIPT
    echo '.createne subaddr 1 subaddr no_value' >> $MMLSCRIPT
    echo '.set save' >> $MMLSCRIPT
    echo '.selectnocallback ERBS'$NODETYPE3 >> $MMLSCRIPT
    echo '.deletesimne' >> $MMLSCRIPT
if [ "$ENABLESL2" == "YES" ]
then
    #Create Security definition
    echo '.setssliop createormodify SL2' >> $MMLSCRIPT
    echo '.setssliop description SL2' >> $MMLSCRIPT
    echo '.setssliop clientcertfile '$PWD/../dummy_certs/cert_single.pem'' >> $MMLSCRIPT
    echo '.setssliop clientcacertfile '$PWD/../dummy_certs/CombinedCertCA.pem'' >> $MMLSCRIPT
    echo '.setssliop clientkeyfile '$PWD/../dummy_certs/keys.pem'' >> $MMLSCRIPT
    echo '.setssliop clientpassword secmgmt' >> $MMLSCRIPT
    echo '.setssliop clientverify 0' >> $MMLSCRIPT
    echo '.setssliop clientdepth 1' >> $MMLSCRIPT
    echo '.setssliop servercertfile '$PWD/../dummy_certs/cert_single.pem'' >> $MMLSCRIPT
    echo '.setssliop servercacertfile '$PWD/../dummy_certs/CombinedCertCA.pem'' >> $MMLSCRIPT
    echo '.setssliop serverkeyfile '$PWD/../dummy_certs/keys.pem'' >> $MMLSCRIPT
    echo '.setssliop serverpassword secmgmt' >> $MMLSCRIPT
    echo '.setssliop serververify 0' >> $MMLSCRIPT
    echo '.setssliop serverdepth 1' >> $MMLSCRIPT
    echo '.setssliop protocol_version sslv2|sslv3|tlsv1' >> $MMLSCRIPT
    echo '.setssliop save force' >> $MMLSCRIPT

    #Set Corba security
    echo '.selectnocallback network' >> $MMLSCRIPT
    echo '.set ssliop no->yes SL2' >> $MMLSCRIPT
    echo '.set save' >> $MMLSCRIPT

fi
    #start first node and then rest of the nodes
    echo '.select '$LTENAME'00001' >> $MMLSCRIPT
    echo '.start -force_new_server' >> $MMLSCRIPT
    echo '.stop' >> $MMLSCRIPT
    echo '.select network' >> $MMLSCRIPT
    echo '.start' >> $MMLSCRIPT

    echo ""
    echo "RUNNING MML SCRIPT"
    echo ""

    $NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT

    rm $PWD/$MMLSCRIPT
