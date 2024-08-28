#!/usr/bin/perl
# VERSION HISTORY
######################################################################################
# Version1    :
# Description : writes LTE build simulation data namely a README to sim folder
#                   /netsim/netsimdir/$SIMNAME/SimNetRevision
# Syntax      : writeSimBuildData.pl
# Date        : June 2013
# Who         : epatdal
######################################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-123-1
# Jira        : CIS-5416
# Purpose     : LTE GIT Migration, modified directory structure,update script
#		directory paths.
# Description : Modified directory structure, update script directory paths.
#			$SCRIPTROOTDIR=~s/LTESim.*//; >> $SCRIPTROOTDIR=~s/util.*//
#			$SCRIPTROOTDIR=~s/LTE1.*//; >> $SCRIPTROOTDIR=~s/lte.*//;
#			$rootDirPath=~s/LTESim.*//; >> $SCRIPTROOTDIR=~s/bin.*//;
# Date        : February 2015
# Who         : ejamfur
#####################################################################################
# Version3    : 16.6
# Revision    : CXP 903 0491-204-1
# Jira        : NSS-2548
# Purpose     : writes simulation build log to simulation directory
# Description : writes utils/simulationbuild.log to simulation directory
#                   /netsim/netsimdir/$SIMNAME/SimNetRevision
# Date        : March 2016
# Who         : ejamfur
#####################################################################################
# Version4    : 16.17
# Revision    : CXP 903 0491-270-1
# Jira        : NSS-7467
# Purpose     : writes simulation EUtranCellData.txt to simulation directory
# Description : calls the /enm-lte/bin/extractEUtranCellData.pl to extract simulation
#               EUtran cell Data and write the data to EUtranCellData.txt file
# Date        : Oct 2016
# Who         : ejamfur
#####################################################################################
####################################################################
# Version5    : ENM 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Copy the Topology file
# Description : To copy the Topology txt file from build directory
#               to SimNetRevision directory
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : ENM 18.7
# Revision    : CXP 903 0491-334-1
# Jira        : NSS-17121
# Purpose     : LRAN Simnet Build Phase - Checklist to be verified post build
# Description : To copy the Summary csv file from build directory
#               to SimNetRevision directory
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
########################
#  Environment
########################
use FindBin;
use lib "$FindBin::Bin/..";
use Cwd;
########################
# Vars
########################
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETSIMDIR="/netsim/netsimdir/";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @netsim_output=();
local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
local $SCRIPTROOTDIR="$scriptpath";
local $rootDirPath="$scriptpath";
$rootDirPath=~s/bin.*//;
local $datDirPath="$scriptpath";
$datDirPath=~s/bin.*/dat\//;
local $utilsDirPath="$scriptpath";
$utilsDirPath=~s/bin.*/utils\//;
local $customdataDirPath="$scriptpath";
$customdataDirPath=~s/bin.*/customdata\//;
local $NETSIMDIRPATH="/netsim/netsimdir/";
local $LOGFILE=${0};
$LOGFILE=~s/\.pl//;$LOGFILE=~s/\.\///;
$LOGFILE="$scriptpath/$LOGFILE.log";
local $DATE=localtime;
local $SIMNAME=$ARGV[0];# the simulations to be updated
local $README="README";
local $CONFIG="CONFIG.env";
local $BUILDLOG="simulationBuild.log";
local $SIMNETREVISION="SimNetRevision";
local $retval,$copycommand;
local $extractEUtranCellDataScript = "extractEUtranCellData.pl";
local $extractEUtranCellDataScriptPath = "$currentdir$extractEUtranCellDataScript";
local $topologyPath="$customdataDirPath/topology";
local $topologyData="$topologyPath/TopologyData.txt";
local $summaryReport="$utilsDirPath/Summary_$SIMNAME.csv";
local $summaryGeneratorScript="$utilsDirPath/generateSummary.sh";

local @helpinfo=qq(
ERROR : need to pass 1 parameter to ${0}

Usage : ${0} <simulation name>

Example 1: ${0} <SIMNAME>

Example 2: ${0} LTED1160-V2x160-ST-TDD-LTE51

Info : ${0} creates and populates
       /netsim/netsimdir/SIMNAME/SimNetRevision with
       the latest SimNetBuilder README
); # end helpinfo
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
   print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure netsim inst in place
#-----------------------------------------
if (!(-e "$NETSIM_INSTALL_PIPE")){# ensure netsim installed
       print "FATAL ERROR : $NETSIM_INSTALL_PIPE does not exist on $netsimserver\n";exit(1);
}# end if
#############################
# verify script params
#############################
if (!( @ARGV==1)){
      print "@helpinfo\n";exit(1);}# end if

$SIMNAME="$NETSIMDIRPATH$SIMNAME";

if (!(-e "$SIMNAME")){# ensure SIMNAME available
       print "FATAL ERROR : $SIMNAME does not exist on $netsimserver\n";exit(1);
}# end if

$README="$rootDirPath$README";
$CONFIG="$datDirPath$CONFIG";
$BUILDLOG="$utilsDirPath$BUILDLOG";

if (!(-e "$README")){# ensure README exists
       print "FATAL ERROR : $README does not exist on $netsimserver\n";exit(1);
}# end if

if (!(-e "$CONFIG")){# ensure CONFIG.env exists
       print "FATAL ERROR : $CONFIG does not exist on $netsimserver\n";exit(1);
}# end if

if (!(-e "$BUILDLOG")){# ensure simulationBuild.log exists
       print "FATAL ERROR : $BUILDLOG does not exist on $netsimserver\n";exit(1);
}# end if


$SIMNETREVISION="$SIMNAME/$SIMNETREVISION";

if (!(-d "$SIMNETREVISION")){# ensure SimNetRevision folder available
       print "Creating $SIMNETREVISION\n";
       $retval=system("mkdir $SIMNETREVISION");
       if($retval!=0){print "WARN : unable to create $SIMNETREVISION\n";}
}# end if
#############################
# copy README to simulation
#############################
$copycommand="$README $SIMNETREVISION/";
print "Copying $copycommand\n";
$retval=system("cp $copycommand");
if($retval!=0){print "WARN : unable to copy $copycommand\n";}
###############################
# copy CONFIG.env to simulation
###############################
$copycommand="$CONFIG $SIMNETREVISION/";
print "Copying $copycommand\n";
$retval=system("cp $copycommand");
if($retval!=0){print "WARN : unable to copy $copycommand\n";}
########################################
# copy simulationBuild.log to simulation
########################################
$copycommand="$BUILDLOG $SIMNETREVISION/";
print "Copying $copycommand\n";
$retval=system("cp $copycommand");
if($retval!=0){print "WARN : unable to copy $copycommand\n";}
#########################################
# Copy EUtran Cell data to simulation
#########################################
local $simulationName = $ARGV[0];
print "Extracting EUtranCellData to $SIMNETREVISION \n";
system(`$extractEUtranCellDataScriptPath $simulationName`);
#########################################
# Copy Topology Cell data to simulation
#########################################
print "Copying TopologyData.txt to $SIMNETREVISION \n";
system(`cp $topologyData $SIMNETREVISION`);

#########################################
# Copy Summary Report to simulation
#########################################
print "Copying Summary.csv to $SIMNETREVISION \n";
system(`cp $summaryReport $SIMNETREVISION`);
system(`cp $summaryGeneratorScript $SIMNETREVISION`);
#-----------------------------------------
#  END
#-----------------------------------------
