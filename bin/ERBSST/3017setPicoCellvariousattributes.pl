#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : sets PICO cell various attributes
# Description : creates support for the creation of PICO cells
# Jira        : NETSUP-1019
# Date        : Jan 2014
# Who         : SimNet/epatdal
####################################################################
####################################################################
# Version2    : LTE 14B.1
# Revision    : CXP 903 0491-92-1
# Purpose     : set attributes InterfaceIPv4::encapsulation and
#	        NextHop::nexthop under ManagedElement,Transport,Host
# Date        : September 2014
# Who         : edalrey
####################################################################
####################################################################
# Version3    : LTE 15B
# Revision    : CXP 903 0491-126-1
# Purpose     : set attributes BrmBackupManager::BackupType and
#		BrmBackupManager::BackupDomain under ManagedElement,
#		SystemFunctions,Brm,BrmBackupManager
# Description : set BackupType=Type and BackupDomain=Domain
# JIRA 	      : NETSUP-2450
# Date        : February 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-128-1
# Purpose     : LTE15B support
# Description : Host MO under ManagedElement,Transport, no longer
#               system created.InterfaceIPv4::Encapsulation attribute
#               data type changed from struct to moRef under
#               ManagedElement,Transport,Host,InterfaceIPv4.
# JIRA        : OSS-66125
# Date        : February 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version5    : LTE16.8
# Revision    : CXP 903 0491-217-1
# JIRA        : NSS-2951
# Purpose     : Reflect the changes from 15B pico and 16B pico
# Description : Handle the struct change from 15B
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version6    : LTE17A
# Revision    : CXP 903 0491-239-1
# JIRA        : NSS-4284
# Purpose     : Update attributes BrmBackupManager::BackupType and
#               BrmBackupManager::BackupDomain under ManagedElement,
#               SystemFunctions,Brm,BrmBackupManager
# Description : Common Netsim for ECIM based nodes need to have
#		BrMBackupManager created with backupDomain=System
#		and backupType=Systemdata
# Date        : July 2016
# Who         : xravlat
####################################################################
####################################################################
# Version7    : LTE16.16
# Revision    : CXP 903 0491-267-1
# JIRA        : NSS-6928
# Purpose     : Update attributes BrmBackupManager::BackupType=System Data
# Description : simulations require BRM configuration for Pico nodes.
# Date        : Oct 2016
# Who         : xmitsin
####################################################################
####################################################################
# Version8    : LTE17.2
# Revision    : CXP 903 0491-279-1
# JIRA        : NSS-8453
# Purpose     : Update attributes BrmBackup::backupName=default_backup
# Description : Set BRM Backup attribute on the Pico nodes
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_CellConfiguration;
use LTE_General;
use LTE_OSS12;
use LTE_OSS13;
use LTE_Relations;
use LTE_OSS14;
####################
# Vars
####################
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEMSRBSV1x160-RVPICO-FDD-LTE36 CONFIG.env 36);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# end verify params

local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICOCELLNUM=&getENVfilevalue($ENV,"PICOCELLNUM");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
local $PICOSIMEND=&getENVfilevalue($ENV,"PICOSIMEND");
local $PICONETWORKCELLSIZE=&getENVfilevalue($ENV,"PICONETWORKCELLSIZE");
local $PICOMAJORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMAJORPERCENTNETWORK");
local $PICOMINORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMINORPERCENTNETWORK");
local $earfcnul,$earfcndl;
# CXP 903 0491-239-1
local $backupType="System Data";
local $backupDomain="System";
# CXP 903 0491-279-1
local $backupName="default_backup";
# CXP 903 0941-128-1
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMVERSION15B="15B";
local $mimGreaterThan14B=&isgreaterthanMIM($MIMVERSION,$MIMVERSION15B);# either yes or no
# CXP 903 0941-217-1
local $acBarringForMoData="";
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picocelltype="EUtranCellFDD";
local $cellcount=1;

while ($NODECOUNT<=$PICONUMOFRBS){
    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get node count number
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);
    # determine earfcnul + earfcndl
    $earfcnul=18000+1;
    $earfcndl=1;

    ##################################
    # start create PICO cell
    ##################################
    # CXP 903 0491-128-1
    local $encapsulationDataType="";# either struct or moRef
    local $createHostMO="";

    if($mimGreaterThan14B eq "yes"){
  	$createHostMO="createmo:parentid=\"ManagedElement=$LTENAME,Transport=1\",type=\"Host\",name=\"1\";";
     	$encapsulationDataType="moRef";
        $acBarringForMoData="[1,[true,true,true,true,true],1]";
    }#end if
    else {
   	$encapsulationDataType="struct";
        $acBarringForMoData="[1,true,1]";
    }# end else

    # build mml script
    @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"cellId (int32)=$cellcount\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"administrativeState (enum, AdmState)=1\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"cellBarred (enum, CellBarred)=1\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"operationalState (enum, OperState)=1\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"earfcnul (int32)=$earfcnul\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"earfcndl (int32)=$earfcndl\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1\",attributes=\"arfcnValueEUtranDl (int32)=$earfcndl\";",
# CXP 903 0491-217-1
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount\",attributes=\"acBarringForMoData (struct, AcBarringConfig)=$acBarringForMoData\";",
# CXP 903 0491-128-1
$createHostMO,
"setmoattribute:mo=\"ManagedElement=$LTENAME,Transport=1,Host=1,InterfaceIPv4=1\",attributes=\"encapsulation ($encapsulationDataType, Encapsulation)=ManagedElement=$LTENAME\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,Transport=1,Host=1,RouteTableIPv4Static=1,Dst=1,NextHop=1\",attributes=\"nexthop (struct, NextHopInfo)=ManagedElement=$LTENAME\";",
# CXP 903 0491-126-1
"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,BrM=1,BrmBackupManager=1\",attributes=\"backupType (str)=$backupType\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,BrM=1,BrmBackupManager=1\",attributes=\"backupDomain (str)=$backupDomain\";",
#CXP 903 0491-279-1
"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,BrM=1,BrmBackupManager=1,BrmBackup=1\",attributes=\"backupName (str)=$backupName\";"
);# end @MMLCmds

    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while PICONUMOFRBS

  # execute mml script
  @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
  print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
