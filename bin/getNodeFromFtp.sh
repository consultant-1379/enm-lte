#!/bin/sh
################################################################
#ScriptName:getNodeFromFtp.sh
#Purpose: To Install basic node from ftp based on name of simulation.
#Written By:xmitsin
#Usage: ./getNodeFromFtp.sh <SimName>
#       ./getNodeFromFtp.sh LTE18-Q4-V4x80-60K-DG2-FDD-LTE39
###################################################################
# Version 1   : LTE 21.06
# Revision    : CXP 903 0491-372-1
# Jira        : NSS-34510
# Purpose     : Update Node template URL.
# Description : Update LTE Codebase to take Node template from new location
# Date        : March 2021
# Who         : xmitsin
####################################################################
# Version 2   : LTE 22.07
# Revision    : CXP 903 0491-383-1
# Jira        : NSS-38412
# Purpose     : Updates the ERBS NodeTemplate URL
# Description : Updated LTE ERBS codebase to take the Nodetemplate from the cpp9.0 page
# Date        : April 2022
# Who         : zjaisai
####################################################################
SimName=$1
# check if SIMNAME is of type DG2
if [[ "$SimName" == *"DG2"* ]];
then
NodeURL="https://netsim.seli.wh.rnd.internal.ericsson.com/tssweb/simulations/com3.1/"
## old url 
#ftp://ftp.lmera.ericsson.se/project/netsim-ftp/simulations/NEtypes/com3.1/
mim=`echo $SimName | awk -F'x' '{print $1}' | awk -F'LTE' '{print $2}' | awk -F'-V' '{print $1}'` #18-Q4
Version=`echo $SimName | awk -F'x' '{print $1}' | awk -F'LTE' '{print $2}' | awk -F'-' '{print $3}'` #V4
MimVer="$mim.$Version" 
MimVersion=`echo $SimName | awk -F'x' '{print $1}' | awk -F'LTE' '{print $2}'`
NeType="MSRBS.*V2.*$MimVer.*"
echo "****"
#echo "NodeTemp=\`curl $NodeURL | grep \"$NeType\" |awk -F \"href=\" \'{print $2}\' | awk -F \'\"\' \'{print $2}\'|grep \"$MimVersion\"\`"
NodeTemp=`curl $NodeURL | grep "$NeType" |awk -F "href=" '{print $2}' | awk -F '"' '{print $2}'`
echo "$SimName,NodeURL=$NodeURL, MimVersion=$MimVer,NeType=$NeType,NodeTemp=$NodeTemp"
echo "Downloading basic node template from netsim ftp"
cd /netsim/netsimdir; wget $NodeURL/$NodeTemp; cd -
NodeName=`echo $NodeTemp | awk -F'.zip' '{print $1}'`
echo "NodeNAme=$NodeName"
echo -e ".uncompressandopen clear_lock\n.uncompressandopen $NodeTemp $SimName" | ~/inst/netsim_shell
rm -rf ~/netsimdir/$NodeTemp
#cp -r ~/netsimdir/$NodeName  ~/netsimdir/$SimName
echo "$0 finished"
else
NodeURL="https://netsim.seli.wh.rnd.internal.ericsson.com/tssweb/simulations/cpp9.0/"
mim=`echo $SimName | awk -F'x' '{print $1}' | awk -F'-' '{print $1}' | awk -F'LTE' '{print $2}' `
version=`cat /var/tmp/tep/enm-lte/dat/ProductData.env | grep "$mim" |grep -v "#" | awk -F '=' '{print $2}' | awk -F ':' '{print $2}'`
NodeTemp=`curl $NodeURL | grep "$mim" |grep "$version"|  awk -F "href=" '{print $2}' | awk -F '"' '{print $2}' `
echo "NodeTemp=$NodeTemp"
echo "Downloading basic node template from netsim ftp"
cd /netsim/netsimdir; wget $NodeURL/$NodeTemp; cd -
NodeName=`echo $NodeTemp | awk -F'.zip' '{print $1}'`
echo "NodeName=$NodeName"
echo -e ".uncompressandopen clear_lock\n.uncompressandopen $NodeTemp $SimName force" | ~/inst/netsim_shell
rm -rf ~/netsimdir/$NodeTemp
fi
