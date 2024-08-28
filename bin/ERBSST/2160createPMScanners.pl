#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14B.1 FT Simulations
# Revision    : CXP 903 0491-88-1
# Jira        : OSS-40195
# purpose     : Create PM Scanners
# description : Create PM Scanners for simulations
# date        : Oct 2014
# who         : edalrey
####################################################################
####################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 16A
# Revision    : CXP 903 0491-159-1
# Jira        : CIS-11328
# Purpose     : Create PM scanner for UETR
# Description : Create PM scanner for UETR for ENM PMIC requirement
# Date        : June 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : LTE 16A
# Revision    : CXP 903 0491-162-1
# Jira        : CIS-11328
# Purpose     : ENM Support for PM
# Description : ENM Support for PM
# Date        : June 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : 16.6
# Revision    : CXP 903 0491-205-1
# Jira        : NSS-2838
# Purpose     : create scanners in suspended state
# Description : create scanners on simulations in suspended for PM
# 		support
# Date        : March 2016
# Who         : ejamfur
####################################################################
# Version5    : 17.12
# Revision    : CXP 903 0491-300-1
# Jira        : NSS-13115
# Purpose     : Remove UETR scanners support on the LTE ERBS
# Description : To remove UETR scanners support on the LTE ERBS
# Date        : July 2017
# Who         : xkatmri
###################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_OSS14;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1];

# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim number>
Example: $0  LTEE1160-V2x10-TEST-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
	print "@helpinfo\n";exit(1);i
}

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type

local $date=`date`, $NETSIMMMLSCRIPT, ;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @MMLCmds,@netsim_output;
####################
# Integrity Check
####################
local $PMSCANNERENABLED=&getENVfilevalue($ENV,"PMSCANNERENABLED");
if($PMSCANNERENABLED ne "YES"){
	exit;
}
if (-e "$MMLSCRIPT"){
	unlink "$MMLSCRIPT";
}
################################
# MAIN
################################
print "... ${0} started running at $date\n";
################################
# Make MML Script (no MO script)
################################
########################################
# build MML script to create PM Scanners
########################################
@MMLCmds=(".open ".$SIMNAME,
	  ".select network",
	  ".genreffilecpp lte Fileset.STATS stats default",
	  ".selectnetype ERBS",
          ".start -sequential",
	  "createscanner2:id=1,measurement_name=\"PREDEF.10000.CELLTRACE\";",
	  "createscanner2:id=2,measurement_name=\"PREDEF.10001.CELLTRACE\";",
	  "createscanner2:id=3,measurement_name=\"PREDEF.10002.CELLTRACE\";",
	  "createscanner2:id=4,measurement_name=\"PREDEF.10003.CELLTRACE\";",
	  "createscanner2:id=5,measurement_name=\"PREDEF.10004.CELLTRACE\";",
	  "createscanner2:id=6,measurement_name=\"PREDEF.10005.CELLTRACE\";",
	  "createscanner2:id=100,measurement_name=\"PREDEF.STATS\",state=\"SUSPENDED\",file=\"Fileset.STATS\";",
	  "pmdata:disable;"
);# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

# execute mml script
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

# output mml script execution
print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mml script
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
