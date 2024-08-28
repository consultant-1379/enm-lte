#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14B
# Revision    : CXP 903 0491-95-1
# Jira        : NETSUP-2258
# Purpose     : Set setswinstallvariables::create_cv_files attribute
# Description : Set setswinstallvariables::create_cv_files attribute
#               to support Smo operation for CPP nodes
# Date        : Oct 2014
# Who         : edalrey
####################################################################
####################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : NETSUP-1019
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_General;
use LTE_OSS14;
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

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type

# check if SMO attributes are enabled 
local $SMOENABLED=&getENVfilevalue($ENV,"SMOENABLED");
if($SMOENABLED ne "YES"){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`, $NETSIMMMLSCRIPT, $MMLSCRIPT;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @MMLCmds, @netsim_output;
local $dir=cwd,$currentdir=$dir."/";
local $MMLSCRIPT=$currentdir.${0}.".mml";

# build mml script
@MMLCmds=(".open ".${SIMNAME},
          ".select network",
          ".start ",
          "setswinstallvariables:createCVFiles=true;"
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

print "... ${0} ended running at $date\n";
################################
# END
################################
