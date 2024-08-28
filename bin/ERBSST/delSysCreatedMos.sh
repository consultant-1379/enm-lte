#!/bin/bash

#Version History
####################################################################
# Version1    : LTE 20.14
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
Usage  : $0 <SimName>

Example: $0 LTE20-Q3-V3x10-1.8K-DG2-FDD-LTE02

DESCRP : This will Delete the System created MOs
HELP

exit 1
fi

################################
# Assign variables
################################

Instpath=/netsim/inst

sim=$1
LOGSPATH=`pwd`

echo "************************************"
echo "./delSysCreatedMos.sh script started running at" $(date +%T)
echo "************************************"

neType=`echo -e $sim | cut -d 'x' -f1 | awk -F "LTE" '{print $2}'`
echo -e ".open $sim \n .show simnes" | $Instpath/netsim_shell -q | awk '/OK/{f=0;};f{print $1;};/NE Name/{f=1;}' > $Instpath/nodelist.txt

for nename in `cat $Instpath/nodelist.txt`
do
            echo -e ".open $sim \n .selectnocallback $nename \n.start \n e case simneenv:get_netype() of {\"LTE\", \"MSRBS-V2\", \"$neType\",_} -> SId = cs_session_factory:create_internal_session(\"MoDelete\", infinity), EranInterMeLinkMOs = csmo:get_mo_ids_by_type(null,\"Lrat:EranInterMeLink\"), lists:map(fun(EranInterMeLinkMOId) -> case EranInterMeLinkMOId of EranInterMeLinkMOId when is_integer(EranInterMeLinkMOId) -> csmodb:delete_mo_by_id(SId, EranInterMeLinkMOId);_Any-> OK end end, EranInterMeLinkMOs), cs_session:commit_chk(SId),cs_session_factory:end_session(SId);_AnyValue -> OK end." | $Instpath/netsim_shell >> $LOGSPATH/../../log/LTE-SIMS.log

            echo -e ".open $sim \n .selectnocallback $nename \n.start \n e case simneenv:get_netype() of {\"LTE\", \"MSRBS-V2\", \"$neType\",_} -> SId = cs_session_factory:create_internal_session(\"MoDelete\", infinity), GtpPathMOs = csmo:get_mo_ids_by_type(null,\"Lrat:GtpPath\"), lists:map(fun(GtpPathMOId) -> case GtpPathMOId of GtpPathMOId when is_integer(GtpPathMOId) -> csmodb:delete_mo_by_id(SId, GtpPathMOId);_Any-> OK end end, GtpPathMOs), cs_session:commit_chk(SId),cs_session_factory:end_session(SId);_AnyValue -> OK end." | $Instpath/netsim_shell >> $LOGSPATH/../../log/LTE-SIMS.log

            echo -e ".open $sim \n .selectnocallback $nename \n.start \n e case simneenv:get_netype() of {\"LTE\", \"MSRBS-V2\", \"$neType\",_} -> SId = cs_session_factory:create_internal_session(\"MoDelete\", infinity), LbmMOs = csmo:get_mo_ids_by_type(null,\"Lrat:TermPointToLbm\"), lists:map(fun(LbmMOId) -> case LbmMOId of LbmMOId when is_integer(LbmMOId) -> csmodb:delete_mo_by_id(SId, LbmMOId);_Any-> OK end end, LbmMOs), cs_session:commit_chk(SId),cs_session_factory:end_session(SId);_AnyValue -> OK end." | $Instpath/netsim_shell >> $LOGSPATH/../../log/LTE-SIMS.log

            echo -e ".open $sim \n .selectnocallback $nename \n.start \n e case simneenv:get_netype() of {\"LTE\", \"MSRBS-V2\", \"$neType\",_} -> SId = cs_session_factory:create_internal_session(\"MoDelete\", infinity), EFuseMOs = csmo:get_mo_ids_by_type(null,\"ReqEFuse:EFuse\"), lists:map(fun(EFuseMOId) -> case EFuseMOId of EFuseMOId when is_integer(EFuseMOId) -> csmodb:delete_mo_by_id(SId, EFuseMOId);_Any-> OK end end, EFuseMOs), cs_session:commit_chk(SId),cs_session_factory:end_session(SId);_AnyValue -> OK end." | $Instpath/netsim_shell >> $LOGSPATH/../../log/LTE-SIMS.log

            echo -e ".open $sim \n .selectnocallback $nename \n.start \n useattributecharacteristics:switch=\"off\"; \n createmo:parentid=\"ManagedElement=$nename,Equipment=1,FieldReplaceableUnit=1\",type=\"EFuse\",name=\"MO12\", quantity=25;" | $Instpath/netsim_shell >> $LOGSPATH/../../log/LTE-SIMS.log
done

echo "************************************"
echo "./delSysCreatedMos.sh script ended running at" $(date +%T)
echo "************************************"

rm -rf $Instpath/nodelist.txt
