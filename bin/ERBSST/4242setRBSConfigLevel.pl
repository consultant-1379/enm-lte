#!/usr/bin/perl
### VERSION HISTORY
###########################################################################
# Version1    : LTE 16B
# Revision    : CXP 903 0491-208-1
# Jira        : NSS-1493
# Purpose     : setting RBSConfiglevel of AutoProvisioning MO
# Description : ENM:AutoProvisioning not receiving Attribute Change events
#               for Radio Node. As NetSims are defaulting to RBSConfiglevel
#               of sitconfigcomplete
# Date        : Apr 2016
# Who         : xsrilek
###########################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use POSIX;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTE16A-V12x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# check if SIMNAME is of type PICO or DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`;
local $LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";

local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds=(),@MMLCmds=(),@netsim_output=();
local $NODECOUNT=1;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

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
# MAIN
################################
################################
# Make MO & MML Scripts
################################

while ($NODECOUNT<=$DG2NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    @MOCmds=qq^ SET
	(
	    mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeAI:AutoProvisioning=1"
	    exception none
	    nrOfAttributes 1
	    "rbsConfigLevel" Integer 4
	)
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

 push(@NETSIMMOSCRIPTS,$NETSIMMOSCRIPT);

 # build mml script
  @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds

  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer NODECOUNT while

  # execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
  print "@netsim_output\n";

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
