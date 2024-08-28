#!/usr/bin/perl
#######################################################################
# Version1    : LTE 16.17
# Revision    : CXP 903 0491-270-1
# Purpose     : create EUtranCell data file in SimNetRevsion directory
# Description : Extracts simulation EUtran Cell data information from
#               the EUtranCellData.csv generated from /enm-lte/bin/
#               ERBSST/archiveEUtranData.pl in order to populate the
#               /netsim_users/pms/etc/eutrancellfdd_list.txt file for
#               GenStats PM support
# Date        : Oct 2016
# Who         : ejamfur
#######################################################################
#######################################################################
# Version2    : LTE 17.14
# Revision    : CXP 903 0491-271-1
# Purpose     : Modified Subnetwork data for ERBS, Radio and PICO nodes
# Date        : 20th August 2017
# Who         : xharidu
#######################################################################

####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../lib/cellconfig";
use Cwd;
use LTE_General;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0];
local $currentDir=cwd."/";
$currentDir=~s/bin.*//;
local $CONFIG="CONFIG.env";
local $ENV=$CONFIG;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $NETSIMDIR = "/netsim/netsimdir/";
local $SIMNETREVISIONDIR = "/SimNetRevision/";
local $SIMEUTRANDATAPATH = "$NETSIMDIR$SIMNAME$SIMNETREVISIONDIR"."EUtranCellData.txt";
local $archiveEUtranCellDatafilePath = $currentDir."customdata/networkarchive/LTE${NETWORKCELLSIZE}EUtranCellData.csv";
local ($simIDnum)=$SIMNAME=~/-LTE(\d+)/;
local $simID = "LTE".$simIDnum;
local $subNetworkID = int $simIDnum;
local $SIMTYPE="";
local $managedElementID = "1";
local $EUtranCellType = "FDD";
local @cellNames;
local $subNetwork="";
if(&isSimLTE($SIMNAME)=~m/YES/) {
    $SIMTYPE="ERBS";
} elsif(&isSimPICO($SIMNAME)=~m/YES/) {
   $SIMTYPE="pERBS";
} elsif(&isSimDG2($SIMNAME)=~m/YES/) {
   $SIMTYPE="RadioNode";
} else {
   print "ERROR: Cell type is not specified in the simulation name \n";
   exit(1);
}
###############################
local @helpinfo=qq(
ERROR : need to pass 1 parameter to ${0}

Usage : ${0} <simulation name>

Example 1: ${0} <SIMNAME>

Example 2: ${0} LTED1160-V2x160-5k-TDD-LTE01

Info : ${0} creates and populates
       /netsim/netsimdir/SIMNAME/SimNetRevision/EUtranCellData.txt

); # end helpinfo
#############################
# verify script params
#############################
if (!( @ARGV==1)){
      print "@helpinfo\n";
      exit(1);
}# end if
#############################
if ( $SIMNAME=~m/-TDD-/ ) {
     $EUtranCellType = "TDD";
}

# read EUtran cell data from archiveEUtranCellData generated csv file
open FH3, '<', $archiveEUtranCellDatafilePath or die "$archiveEUtranCellDatafilePath: $!";
my @archiveEUtranCellData = <FH3>;
foreach $cellData (@archiveEUtranCellData) {
   if ($cellData=~/$simID/) {
       $cellData=~ s/\;.*//;
       push (@cellNames, $cellData);
   }
}

# write simulation EUtran data to EUtranCellData.txt file in simulation SimNetRevision directory
open FILE, '>', $SIMEUTRANDATAPATH or die "$SIMEUTRANDATAPATH: $!";
foreach $cellName (@cellNames) {
    my $nodeName = $cellName;
    $nodeName=~ s/\-.*//;
    $nodeName=~ s/\n//g;
    $managedElementID = $nodeName;
    my $nodenum = int (substr($nodeName, -5));
    if ( $SIMTYPE eq "ERBS" ) {
        if ( $nodenum <= 125 ) {
        $subNetwork = "ERBS-SUBNW-1";
        }
        else {
        $subNetwork = "ERBS-SUBNW-2";
        }
    }
    elsif ( $SIMTYPE eq "RadioNode" ) {
        $subNetwork = "NETSimW";
    }
    elsif ( $SIMTYPE eq "pERBS" ) {
        $subNetwork = "LTE05";
    }
    print FILE "SubNetwork=$subNetwork,MeContext=$nodeName,ManagedElement=$managedElementID,ENodeBFunction=1,EUtranCell$EUtranCellType=$cellName";
}
close FILE;
###########
# EOF
###########
