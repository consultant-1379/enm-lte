#!/usr/bin/perl
#VERSION HISTORY
####################################################################
# Version1    : LTE 17.14
# Revision    : CXP 903 0491-304-1 
# Purpose     : creates Softlock support in LTE nodes               
# Description : creates OptionalFeatureLicense MO needs to be set on
#               the half of the network
# Jira        : NSS-13421
# Date        : Aug 2017
# Who         : zyamkan
####################################################################
# Env
#####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS14;
####################

# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local @NETSIMMOSCRIPTS=();
local $RBSCOUNT=$NUMOFRBS/2;
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
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$RBSCOUNT){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
    @MOCmds=qq( CREATE
(
    parent "ManagedElement=1,SystemFunctions=1,Licensing=1"
        identity CellSoftLock
        moType OptionalFeatureLicense
    exception none
    nrOfAttributes 6
    "OptionalFeatureLicenseId" String "CellSoftLock"
    "serviceState" Integer 1
    "licenseState" Integer 1
    "keyId" String "CXC4011378"
    "featureState" Integer 1
    "userLabel" String "Service Cell Soft Lock"
)
    );# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

   # build mml script
  @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end first while condition
$RBSCOUNT++;
while ($RBSCOUNT<=$NUMOFRBS) {
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$RBSCOUNT);
    @MOCmds=qq( CREATE
(
    parent "ManagedElement=1,SystemFunctions=1,Licensing=1"
        identity NonCellSoftLock
        moType OptionalFeatureLicense
    exception none
    nrOfAttributes 6
    "OptionalFeatureLicenseId" String "NonCellSoftLock"
    "serviceState" Integer 0
    "licenseState" Integer 0
    "keyId" String "CXC"
    "featureState" Integer 0
    "userLabel" String "Service"
)
    );# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$RBSCOUNT,@MOCmds);
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

   # build mml script
  @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $RBSCOUNT++;
}# end second while condition 
 #execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

    # output mml script execution
  print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo scripts
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################

