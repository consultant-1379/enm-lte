#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16.8
# Revision    : CXP 903 0491-219-1
# JIRA        : NSS-3685
# Purpose     : PM file support for MSRBS-V1 simulations
# Description : Set PM path on PM and PM Event MOs
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : LTE16.8
# Revision    : CXP 903 0491-223-1
# JIRA        : NSS-3685
# Purpose     : PM file support for MSRBS-V1 simulations
# Description : Handle the change in MO in 15B mim
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE16.15
# Revision    : CXP 903 0491-254-1
# JIRA        : NSS-6366
# Purpose     : pico pm_data collection path update for Genstat
# Description : updated pm_data collection path
# Date        : Sep 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE17.01
# Revision    : CXP 903 0491-276-1
# JIRA        : NSS-8286
# Purpose     : To disable pmdata on node
# Description : pmdata:disable commmand added
# Date        : Nov 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE17.11
# Revision    : CXP 903 0491-299-1
# JIRA        : NSS-12516
# Purpose     : To provide PM file format support
# Description : PM file format support added
# Date        : June 2017
# Who         : xkatmri
####################################################################
####################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBSV1x160-RVPICO-FDD-LTE36 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# end verify params
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICONODETYPE3=&getENVfilevalue($ENV,"PICONODETYPE3");
local $NodeVersion=substr($PICONODETYPE3,0,3);

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

     if($NodeVersion != "15B"){$FilePullCapabilitiesid=1;}
     else {$FilePullCapabilitiesid=2;}

while ($NODECOUNT<=$PICONUMOFRBS){

    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    # build mml script
    @MOCmds=();
    @MOCmds=qq^
    SET
    (
    mo "ManagedElement=$LTENAME"
    exception none
    nrOfAttributes 1
    "dateTimeOffset" String "+01:00"
    )
    SET
    (
    mo "ManagedElement=$LTENAME,SystemFunctions=1,Pm=1,PmMeasurementCapabilities=1"
    exception none
    nrOfAttributes 2
    "fileLocation" String "/opt/com/comea/internalFiles/PerformanceManagementReportFiles"
    "supportedCompressionTypes" Array Integer 1
         0
    )
    SET
    (
    mo "ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,FilePullCapabilities=$FilePullCapabilitiesid"
    exception none
    nrOfAttributes 1
    "outputDirectory" String "/var/log/persistent/oss/cell_trace"
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
          "pmdata:disable;",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while

  # execute mml script
  @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
  print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo scripts
unlink @NETSIMMOSCRIPTS;
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
