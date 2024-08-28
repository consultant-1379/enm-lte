#!/usr/bin/perl
# VERSION HISTORY
##########################################################################
#########################################################################
# Version1    : LTE 22.06
# Revision    : CXP 903 0491-382-1
# User Story  : NSS-38841
# Purpose     : supportedCategories attribute values are missing on HealthCheckM
# Description : Update HC Rules for LTE Simulations
# Date        : Mar 2022
# Who         : zjaisai
#########################################################################
#########################################################################
# Version1    : LTE 20.03
# Revision    : CXP 903 0491-356-1
# User Story  : NSS-28444
# Purpose     : Set Category list Attribute for new mims
# Description : Update HC Rules for LTE DG2 simulations
# Date        : Dec 2019
# Who         : xmitsin
##########################################################################
##########################################################################
# Version1    : LTE 20.06
# Revision    : CXP 903 0491-357-1
# User Story  : NSS-29181
# Purpose     : Set CategoryList for CommonFunction_CheckSctrStatus HcRule.
# Description : Update HC Rules for LTE DG2 simulations
# Date        : Feb 2020
# Who         : xmitsin
##########################################################################
##########################################################################
# Version4    : LTE 21.13
# Revision    : CXP 903 0491-375-1
# User Story  : NSS-36574
# Purpose     : Updating HC Rules
# Description : Update HC Rules for LTE DG2 simulations
# Date        : July 2021
# Who         : xmitsin
##########################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}

# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS",$SIMNAME);
local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
####################

#$MIMVERSION="18-Q6-V9";
print "\n test--------- mimVersion =$MIMVERSION\n ";
$CheckMIM=&isgreaterthanMIM_ECIM($MIMVERSION,"19-Q4-V1");
if ( "$CheckMIM" eq "no"){ exit; }
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################

while ($NODECOUNT<=$DG2NUMOFRBS){# start outer while

# get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);

	@MOCmds=();
	@MOCmds=qq^
SET
(
   mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
   nrOfAttributes 1
     "supportedCategories" Array Struct 7
     nrOfElements 2
     "category" String "ALL"
     "description" String "Includes all the rules provided by the node."

     nrOfElements 2
     "category" String "EXPANSION"
     "description" String "Includes the rules to execute before and after node expansion."

     nrOfElements 2
     "category" String "POSTUPGRADE"
     "description" String "Includes the rules to execute after SW upgrade."

     nrOfElements 2
     "category" String "PREINSTALL"
     "description" String "Includes the rules to execute before SW installation"

     nrOfElements 2
     "category" String "PREUPGRADE"
     "description" String "Includes the rules to execute before SW upgrade."

     nrOfElements 2
     "category" String "SITE_ACCEPTANCE"
     "description" String "Includes the rules to execute for site acceptance activities."

     nrOfElements 2
     "category" String "TROUBLESHOOT"
     "description" String "Includes the rules to execute for site equipment diagnostics."
)
     

SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=BtsFunction_CheckAbisLinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 4
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Indicates that the rule should always be executed."
 )
 
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=BtsFunction_CheckTrxStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
	    nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Indicates that the rule should always be executed."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 

 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckFruStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 4
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckHardwareStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
	    nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."  
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
    
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckSynchronizationClock"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckSynchronizationReference"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 

  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=NodeBFunction_CheckNbapCommonLinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 4
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 ) 
 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=NodeBFunction_CheckNbapDedicatedLinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 4
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=NodeBFunction_CheckNodeBLocalCllStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update."
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=NodeBFunction_CheckWcdmaTraffic"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=SystemFunction_CheckDiskSpace"
    nrOfAttributes 1
      "categoryList" Array Struct 2
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
 
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckRetStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 3
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
 )
 
 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=SystemFunction_CheckFileServerConnection"
    nrOfAttributes 1
      "categoryList" Array Struct 2
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckBERForElectricalLink"
    nrOfAttributes 1
      "categoryList" Array Struct 2
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
    SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckCPRILinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 3
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=GNBCUCPFunction_CheckXnLinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )

SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckEutranFCllStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )

    SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckVswrStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 3
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
     SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckTmaStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 3
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
     SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckRaeStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 3
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
    SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckTxAndRxPowerForSfpModule"
    nrOfAttributes 1
      "categoryList" Array Struct 2
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckBERandPowerLossForOpticalLink"
    nrOfAttributes 1
      "categoryList" Array Struct 2
		nrOfElements 2
        "category" String "TROUBLESHOOT"
        "description" String "Indicates that the rule should be executed for troubleshooting."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
 )
 
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=GNBCUCPFunction_CheckNrTraffic"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=GNBCUCPFunction_CheckNgLinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
   SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckLteTraffic"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
  SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckNbiotCllStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=GNBCUCPFunction_CheckNRCllCUStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=CommonFunction_CheckSctrStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckS1LinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckX2LinkStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=ENodeBFunction_CheckEutranTCllStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )
 
 
 
 SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1,RcsHcm:HcRule=GNBDUFunction_CheckNRCllDUStatus"
    nrOfAttributes 1
      "categoryList" Array Struct 5
		nrOfElements 2
        "category" String "PREINSTALL"
        "description" String "Indicates that the rule should be executed before an installation."
        nrOfElements 2
        "category" String "PREUPGRADE"
        "description" String "Indicates that the rule should be executed before an update. "
        nrOfElements 2
        "category" String "POSTUPGRADE"
        "description" String "Indicates that the rule should be executed after an upgrade."
		nrOfElements 2
        "category" String "ALL"
        "description" String "Includes all the rules provided by the node."
		nrOfElements 2
        "category" String "SITE_ACCEPTANCE"
        "description" String "Indicates that the rule should be executed for site acceptance."
 )



	
       ^;# end @MO
       $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

  ################################################
  # build mml script
  ################################################
  @MMLCmds=(".open ".$SIMNAME,
            ".select ".$LTENAME,
            ".start ",
            "useattributecharacteristics:switch=\"off\"; ",
            "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds

  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while

   # execute mml script
  # @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
    print "@netsim_output\n"; 


  
################################
sub isgreaterthanMIM_ECIM {
    local ($mimVersion1,$mimVersion2)=@_;
    local $greaterOrEqualMIM="ERROR";
    # Extract the digits from mimversions
    local ($firstReleaseNum)=$mimVersion1=~/(\d+)/;  ######19
    local ($secondReleaseNum)=$mimVersion2=~/(\d+)/;  ######19
    

        if ($firstReleaseNum > $secondReleaseNum) { $greaterOrEqualMIM="yes";}
        if ($firstReleaseNum < $secondReleaseNum) { $greaterOrEqualMIM="no";}
		else {
       # COM/ECIM version comparsion
			my $firstVersion=($mimVersion1=~m/Q/) ? $mimVersion1 : $mimVersion1."-Q0"; $firstVersion=~ s/.*Q//g; @firstVersion= split /-/,$firstVersion;
			my $secondVersion=($mimVersion2=~m/Q/) ? $mimVersion2 : $mimVersion2."-Q0"; $secondVersion=~ s/.*Q//g; @secondVersion= split /-/,$secondVersion;
                
	           if ($firstVersion[0] >= $secondVersion[0]) { $greaterOrEqualMIM="yes";}
			   else { $greaterOrEqualMIM="no"; }
			}

    return($greaterOrEqualMIM);
}# end sub isgreaterthanMIM_ECIM
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
