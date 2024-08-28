#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16.17
# Revision    : CXP 903 0491-269-1
# JIRA        : NSS-7366
# Purpose     : To set attributes of MO CertMCapabilities
# Description : To set attributes enrollmentSupport, fingerprintSupport
#               in the MO CertMCapabilities according to real Node
# Date        : Oct 2016
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

while ($NODECOUNT<=$PICONUMOFRBS){

    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    # build mml script
    @MOCmds=();
    @MOCmds=qq( SET
(
    mo "ManagedElement=$LTENAME,SystemFunctions=1,SecM=1,CertM=1,CertMCapabilities=1"
    exception none
    nrOfAttributes 2
    "fingerprintSupport" Integer 0
    "enrollmentSupport" Array Integer 3
         0
         1
         3
)
  );# end @MO

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
