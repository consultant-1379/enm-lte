#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : LTE 16.8
# Revision    : CXP 903 0491-220-1
# Jira        : NSS-3586
# Purpose     : Set LogService MO for pushLog action
# Description : Setting attributes in LogService MO
#               ERBS simulations.
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : LTE 16.8
# Revision    : CXP 903 0491-224-1
# Jira        : NSS-3586
# Purpose     : Set LogService MO for pushLog action
# Description : Setting attributes in LogService MO
#               ERBS simulations.
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE 16.14
# Revision    : CXP 903 0491-253-1
# Jira        : NSS-5478
# Purpose     : Set LogService MO for pushLog action
# Description : Setting Some defined attributes in LogService MO
#               ERBS simulations.
# Date        : Aug 2016
# Who         : xmitsin
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

print "... ${0} started running at $date\n";

# build mml script
@MMLCmds=(".open ".${SIMNAME},
          ".select network",
          ".start ",
          "setmoattribute:mo=\"ManagedElement=1,SystemFunctions=1,LogService=1\", attributes=\"logs (string)=[SHELL_AUDITTRAIL_LOG, CELLO_SECURITYEVENT_LOG, CORBA_AUDITTRAIL_LOG, CELLO_IPTRAN_LOG, CELLO_IPTRAN_DEBUG_LOG, PNP_LOG]\";"

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
