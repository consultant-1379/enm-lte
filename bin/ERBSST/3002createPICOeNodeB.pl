#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16.8
# Revision    : CXP 903 0491-217-1
# JIRA        : NSS-2951
# Purpose     : Reflect the changes from 15B pico and 16B pico
# Description : Create eNodeB for 16B PICO mim
# Date        : May 2016
# Who         : xkatmri
####################################################################
# Version2    : LTE 16.12
# Revision    : CXP 903 0491-243-1
# JIRA        : NSS-5331
# Purpose     : Reflect the changes from 16B onwards
# Description : Create eNodeB for 16B PICO mim onwards
# Date        : July 2016
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
local $date=`date`,$pdkdate=`date '+%FT%T'`,$LTENAME;
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
local $eNodeBRequiredVersion='16B';
local $eNodeBRequired=&isgreaterthanMIM($NodeVersion,$eNodeBRequiredVersion);

####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}
# check if Node Version is 16B
if ($eNodeBRequired eq "NO") {
    print "...[INFO] $date: Node Version is not higher than 16A. ${0} will not be executed\n";
    exit;
}
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
	@MOCmds=qq^ CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME"
    identity "1"
    moType MSRBS_V1_eNodeBFunction:ENodeBFunction
    exception none
    nrOfAttributes 1
    "eNodeBFunctionId" String "1"
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
