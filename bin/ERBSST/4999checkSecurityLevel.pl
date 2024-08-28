#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : LTE 16.10
# Revision    : CXP 903 0491-226-1
# Jira        : NSS-4048
# Purpose     : Update Sims with dummy SL2 configuration
# Description : Enable SL2 on ERBS nodes
# Date        : June 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : LTE 16.11
# Revision    : CXP 903 0491-230-1
# Jira        : NSS-4524
# Purpose     : To resolve LTE build error
# Description : Changing the filename to change the scripts
#               running order
# Date        : June 2016
# Who         : xkatmri
####################################################################
# Version3    : LTE 16.11
# Revision    : CXP 903 0491-231-1
# Jira        : NSS-4547
# Purpose     : SL1/SL2 configuration with switch
# Description : Setting a condition to check for SL1 or SL2
# Date        : June 2016
# Who         : xkatmri
##########################################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
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
# check if SIMNAME is of type PICO or DG2
if (&isSimPICO($SIMNAME)=~m/YES/ || &isSimDG2($SIMNAME)=~m/YES/)
{exit;}
#----------------------------------------------------------------
local $date=`date`,$NETSIMMMLSCRIPT,$MMLSCRIPT;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @MMLCmds, @netsim_output;
local $dir=cwd,$currentdir=$dir."/";
local $MMLSCRIPT=$currentdir.${0}.".mml";

print "... ${0} started running at $date\n";

#Checking Security Level on nodes
@MMLCmds=(".open ".${SIMNAME},
          ".selectnocallback network",
          ".start",
          "oseshell",
          "secmode -s",
          "secmode -l 2",
          "secmode -s",
          "exit",
          ".sleep 300",
          ".stop");# end @MMLCmds

$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
#@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

# output mml script execution
print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo script
#unlink "$NETSIMMMLSCRIPT";
#------------------------------------------
print "... ${0} ended running at $date\n";
################################
# END
################################
