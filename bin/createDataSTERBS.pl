#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : Modified for TERE 10.0
# Revision    : unknown
# Jira        : unknown
# Purpose     : 
# Description : 
# Date        : Sept 2009
# Who         : Fatih ONUR
####################################################################            
# Version2    : LTE 15B         
# Revision    : CXP 903 0491-129-1
# Purpose     : LTE Nexus support design
# Description : Choose the UploadLocation for simulations.
#		[Commented out: add test status by adding file to
#		 simulation directory.]
# Date        : 09 Mar 2015
# Who         : edalrey     
#################################################################### 
# Version3    : 16.6         
# Revision    : CXP 903 0491-204-1
# Jira        : NSS-2548
# Purpose     : generate simulation build summary log 
# Description : add execute utils/checkForBuildErrors.sh 
#               and bin/writeSimBuildData.pl
# Date        : March 2016             
# Who         : ejamfur      
####################################################################
####################################################################
#Version4    : 18.6
# Revision    : CXP 903 0491-331-1
# Jira        : NSS-17417
# Purpose     : Simulation script design during NETSim node start
# Description : Parallel execution of build scripts and netsim node start
# Date        : Feb 2018
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : 18.7
# Revision    : CXP 903 0491-334-1
# Jira        : NSS-17121
# Purpose     : LRAN Simnet Build Phase - Checklist to be verified post build
# Description : Generates a summary report after build and pushes it
#               into the simulation zip
# Date        : March 2018
# Who         : xkatmri
####################################################################
###############################################################################
# Version6    : LTE 19.04
# Revision    : CXP 903 0491-349-1
# Jira        : NSS-22844
# Purpose     : Create specific moDumps for Nodes
# Description : Get the modata from the nodes and store them in SimNetRevision
# Date        : Feb 2019
# Who         : xharidu
###############################################################################
###############################################################################
#Version 7    : LTE 22.06
#REvision     : CXP 903 0491-380-1
#Jira         : NSS-37048
#Purpose      : Set ExternalUtranCellFDD refs
#Description  : This 4278setUtranCellRelations.sh script will includes the ref values
#Date         : Feb 2022
#Who          : zjaisai
###############################################################################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
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
local $date=`date`;
print "... ${0} started running at $date\n";
local $dir=cwd;
$dir=~s/bin.*//;
$utilsDir=$dir."utils/";

if ( $SIMNAME=~m/PICO/ )
{
$retval=system("./createRBSdataFTERBS.sh $SIMNAME $LTE $ENV");
}
if ( $SIMNAME=~m/DG2/ )
{
$retval=system("./4278setUtranCellRelations.sh $SIMNAME $LTE $ENV");
}
#generate simulation summary report
$retval=system("cd $utilsDir; ./generateSummary.sh $SIMNAME");

# CXP 903 0491-129-1 - LTE Nexus support design
# ./addTestStatus.sh
# generate simulation build log: /utils/simulationBuild.log
$retval=system("cd $utilsDir; ./checkForBuildErrors.sh $SIMNAME");

# write build data to /netsim/netsimdir/<SIM>/SimnetRevision
$retval=system("./writeSimBuildData.pl $SIMNAME");

# load nodeSpecificdumps to /netsim/netsimdir/<SIM>/SimnetRevision
$retval=system("./generateNodeSpecificMoData.sh $SIMNAME");

# save and compress simulation
$retval=system("./saveAndCompressSimulation.sh $SIMNAME $ENV");

# CXP 903 0491-129-1 - LTE Nexus support design
$retval=system("./uploadSim.sh $SIMNAME $ENV");

$date=`date`;
print "... ${0} ended running at $date\n";
################################
# END
################################
