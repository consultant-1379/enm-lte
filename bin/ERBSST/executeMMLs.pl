#!/usr/bin/perl
### VERSION HISTORY
########################################################################
# Version1    : ENM 18.06
# Revision    : CXP 903 0491-
# Purpose     : To execute the final MML on netsim
# Description : create a MML file and throw it to netsim shell
# Date        : Feb 2018
# Who         : Kathak Mridha
########################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);

################################
# MAIN
################################
print "...${0} started running at $date\n";

################################
# Make MML Scripts
################################

while ($NODECOUNT<=$NUMOFRBS){# start outer while

  #get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);

  $NETSIMMOSCRIPT="$scriptpath/Final.mo$NODECOUNT";

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

$date=`date`;
print "... ${0} ended running at $date\n";
################################
# END
################################
