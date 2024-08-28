#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 17B
# Revision    : CXP 903 0491-284-1
# Purpose     : Creates logs on PICO Simulations.
# Description : Updates missing Logs on PICO simulations.
# Jira        : NSS-9759
# Date        : JAN 2017
# Who         : xmitsin
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
local $NETSIMMMLSCRIPT,$NODECOUNT=1;
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
####################
# Integrity Check
####################
if (-e "$MMLSCRIPT"){
   unlink "$MMLSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $count=1;

while ($NODECOUNT<=$PICONUMOFRBS){
    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    ##################################
    # start create PICO cell
    ##################################
    # build mml script
    @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
          "createlogfile:path=\"/oss/permanent/\",logname = \"sysevent\";",
          "createlogfile:path=\"/oss/permanent/\",logname = \"SWUpgradeLog.txt\";",
          "createlogfile:path=\"/oss/permanent/\",logname = \"AutointegrationLog.txt\";",
          "createlogfile:path=\"/oss/permanent/\",logname = \"fmevents.log\";",
          "createlogfile:path=\"/oss/permanent/\",logname = \"alarmlog.log\";",
          "createlogfile:path=\"/oss/volatile/\",logname = \"fmevents.log\";",
          "createlogfile:path=\"/oss/volatile/\",logname = \"startup\";",
          "createlogfile:path=\"/oss/volatile/\",logname = \"runtime\";",
          "createlogfile:path=\"/oss/volatile/\",logname = \"Boam_traceLog.dmp, Core0_traceLog.dmp, Core1_traceLog.dmp, Core2_traceLog.dmp, Core3_traceLog.dmp\";",
          "createlogfile:path=\"/oss/volatile/diagnostic/\",logname = \"Diag_1.bin.gz, Diag_2.bin.gz, Diag_3.bin.gz\";",
          "createlogfile:path=\"/oss/persistent/diag1/\",logname = \"postmortemdiag1\";",
          "createlogfile:path=\"/oss/persistent/diag2/\",logname = \"postmortemdiag2\";",
          "createlogfile:path=\"/oss/persistent/pm/\",logname = \"A20130326.0131+0000-0132+0000_1.xml\";",
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
