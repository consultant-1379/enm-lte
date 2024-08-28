#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : LTE 16.8
# Revision    : CXP 903 0491-221-1
# Jira        : NSS-1434
# Purpose     : Set bandwidth for ERBS simulations.
# Description : Set setswinstallvariables:bandwidth for
#               ERBS simulations.
# Date        : May 2016
# Who         : xkatmri
####################################################################
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
local $setbandwidth="setswinstallvariables:bandwidth=1364992;";

print "... ${0} started running at $date\n";

# build mml script
@MMLCmds=(".open ".${SIMNAME},
          ".select network",
          ".start ",
           $setbandwidth

);# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

# output mml script execution
print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink "$NETSIMMMLSCRIPT";
#------------------------------------------
print "... ${0} ended running at $date\n";
################################
# END
################################
