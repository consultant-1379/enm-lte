#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : LTE 17.1
# Revision    : CXP 903 0491-274-1
# Jira        : NSS-7854
# Purpose     : Set Log Files for ERBS
# Description : Setting up Log Files in different paths for
#               ERBS simulations.
# Date        : Nov 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version1    : LTE 17.4
# Revision    : CXP 903 0491-285-1
# Jira        : NSS-9760
# Purpose     : Set Log Files for ERBS
# Description : Setting up Log Files in different paths for
#               ERBS simulations.
# Date        : Jan 2017
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

print "... ${0} started running at $date\n";

# build mml script
@MMLCmds=(".open ".${SIMNAME},
          ".select network",
          ".start ",
          "createlogfile:path=\"/c/logfiles/systemlog/\",logname = \"00000sys.log\";",
          "createlogfile:path=\"/c/systemfiles/cello/cma/su/trace/\",logname = \"Trace.log\";",
          "createlogfile:path=\"/d/logfiles/dspdumps/\",logname = \"datadumps.log\";",
          "createlogfile:path=\"/d/logfiles/dspdumps/\",logname = \"faultlogs.log\";",
          "createlogfile:path=\"/d/logfiles/dspdumps/\",logname = \"ls.log\";",
          "createlogfile:path=\"/c/logfiles/hw_inventory/\",logname = \"CELLO_HWINVENTORY_LOG.xml\";",
          "createlogfile:path=\"/r000100/localevent/\",logname = \"localevent.log\";",
          "createlogfile:path=\"/c/logfiles/troubleshooting/\",logname = \"CELLO_IPTRAN_LOG.xml\";",
          "createlogfile:path=\"/c/logfiles/troubleshooting/exception/\",logname = \"exception.log\";",
          "createlogfile:path=\"/c/logfiles/troubleshooting/error/\",logname = \"error.log\";"

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
