#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : Created for LTE O 10.0 TERE
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Version2    : Created for reqId:4710 
# Description : FDD and TDD node division provided
# Date        : 09 JUL 2010
# Who         : Fatih ONUR
####################################################################
####################################################################
# Version3    : Created for LTE ST Simulations 
# Purpose     : TEP Request : 5024
# Description : LTE PCI values in LTE ST Simulations 
# Date        : Dec 2010
# Who         : epatdal
####################################################################
####################################################################
# Version4    : Created for LTE ST Simulations
# Purpose     : TEP Request : 5024 & 6203
# Description : LTE PCI values in LTE ST Simulations includes for
#               updated latitude, longitude and maximumTransmissionPower
#               attributes 
# Date        : Jan 2011
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 12.2 
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : Creates flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Nov 2011
# Who         : lmieody
####################################################################
####################################################################
# Version6    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 3 Fix
# Description : Changes administrative state of EUtranCell to
# be operational and unlocked for dynamic cell status
# Date        : Apr 2011
# Who         : qgormor
####################################################################
####################################################################
# Version7    : LTE 13A
# Purpose     : Speed up sim creation
# Description : Script altered to use single MML script, single pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version8    : LTE 13A
# Purpose     : Sprint 2 Feature 3b -> Combined Cell (Multi-sector Cell)-Part 2
#               Sprint 2 Feature 3c -> Combined Cell (Multi-sector Cell)-Part 3
# Description : Enables support for single and/or multiple SectorCarrier
#               with Combined Cell from MIM L13A (MIM D125) onwards.
#               Deprecate maximumTransmissionPower
# CDM         : 25/159 41-FCP 121 9272
# Date        : August 2012
# Who         : epatdal
#####################################################################
####################################################################
# Version9    : LTE 13A
# Purpose     : 0/0 PCI values on all cells
# Description : This is to allow PCI to set good values to begin with
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version10   : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#		relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version11   : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE 
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next 
#               script                             
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version12   : LTE 14B.1
# Purpose     : enable support for PCI 
# Description : 1. set physicalLayerSubCellId and physicalLayerCellIdGroup values
#               2. set channelbandwidthvalue for either FDD/TDD cells
#               3. execute writePCIinnerNetwork.pl if required
#               4. check ex: ~/customdata/pci/LTE28000innerPCInetwork.csv
#                  exists and defines the boundarypoints 1,2,3,4 as required
#               Note : the innerPCInetwork file should be supplied to customer (RV/FT)
# Date        : May 2014
# Who         : epatdal
####################################################################
####################################################################
# Version13   : LTE 14B.1
# Purpose     : remove comment 
# Description : Discovered problems building 6KPCI, issues related
#		to functionality which was commented out on $retval
# Date        : Aug 2014
# Who         : ecasjim
####################################################################
####################################################################
# Version14   : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version15   : LTE 15B
# Revision    : CXP 903 0491-135-1
# Jira        : NETSUP-2748
# Purpose     : resolves an issue where TDD cells are represented
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Description : ensure TDD and FDD cells are not represented
#               incorrectly
# Date        : Mar 2015
# Who         : epatdal
####################################################################
####################################################################
# Version16   : LTE 15.16
# Revision    : CXP 903 0491-182-1
# Jira        : NSS-91
# Purpose     : maximumTransmissionPower attribute deprecated for
#               MIM versions >= G160 
# Description : deprecate maximumTransmissionPower attribute for
#               MIM versions >= G160
# Date        : Oct 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version17   : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts 
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
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
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# populate network grid with all cell data
local (@FULLNETWORKGRID)=&getAllNodeCells(2,1,$NETWORKCELLSIZE);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
local ($cellid,$latitutde,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup);
local @NETSIMMOSCRIPTS=();
# LTE14B.1 pci support
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pci\//;
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."innerPCInetwork.csv";
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;
# cell channelbandwith values
local $command1="./writePCIinnerNetwork.pl";
local @bandwidthrange=qw/1400 3000 5000 10000 15000 20000/;
local $bandwidthrangesize=@bandwidthrange;
local $tempbandwidthrangesize=0;
local $CHANNELBANDWIDTH="";
local $channelbandwidthvalue;
######################
# MIM Version support
######################
local $MIMVERSION=&queryMIM($SIMNAME);
local $disableMaxTransPowerSupport=&isgreaterthanMIM($MIMVERSION,"G160");
local $maximumTransmissionPower;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}

# check innerPCInetwork file exits
if(!(-e $LTENetworkOutput)){
   print "Executing $command1 to create $LTENetworkOutput\n";
   #CXP 903 0491-80-1, 27/08/2014 - functionality which was commented out
   $retval=system("$command1 >/dev/null 2>&1");
   if($retval!=0){
      print "FATAL ERROR : unable to create $LTENetworkOutput\n";
      $retval=0;
      exit;
   }# end inner if
}# end outer if
#####################
#Open file
#####################
local $filename = "$topologyDirPath/EUtranCell.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  $CELLCOUNT=1;
 
 foreach $Cell (@primarycells) {

   if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      print "Creates ".$LTENAME."-".$CELLCOUNT." FDD Cell...\n";
      $TYPE="EUtranCellFDD";
      $CHANNELBANDWIDTH="dlChannelBandwidth";
   }# end if
   else {
       print "Creates ".$LTENAME."-".$CELLCOUNT." TDD Cell...\n";
       $TYPE="EUtranCellTDD";
       $CHANNELBANDWIDTH="channelBandwidth";
       # CXP 903 0491-135-1
       if($Frequency<36005){$Frequency=$Frequency+36004;}
   }# end else

   # set round robin channelbandwith range
   if($tempbandwidthrangesize>=$bandwidthrangesize){$tempbandwidthrangesize=0;}
   if($tempbandwidthrangesize<$bandwidthrangesize){
      $channelbandwidthvalue=$bandwidthrange[$tempbandwidthrangesize];
      $tempbandwidthrangesize++;
   }# end if

   # CXP 903 0491-182-1        
   $maximumTransmissionPower=($disableMaxTransPowerSupport eq "yes") ? '' : "maximumTransmissionPower Integer 120";
     
    # get node cell data
    ($gridrow,$gridcol)=&getCellRowCol($Cell,$NETWORKCELLSIZE);
    ($cellid,$latitude,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup)=split(/\../,$FULLNETWORKGRID[$gridrow][$gridcol]);
    print "Create $LTENAME Cell $LTENAME-$CELLCOUNT\n";
    # build mo script

   @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1"
      identity $LTENAME-$CELLCOUNT
      moType $TYPE
      exception none
         nrOfAttributes 9
           altitude Integer $altitude
           $CHANNELBANDWIDTH Integer $channelbandwidthvalue
           latitude Integer $latitude
           longitude Integer $longitude
           $maximumTransmissionPower
           physicalLayerCellIdGroup Integer $physicalLayerCellIdGroup 
           physicalLayerSubCellId Integer $physicalLayerSubCellId
           userLabel String $LTENAME-$CELLCOUNT
	       administrativeState Integer 1
	       operationalState Integer 1
     );
     ^;# end @MO

print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
    $CELLCOUNT++;
  }# end foreach
 
  # build mml script 
  @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while

  # execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
  print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo scripts
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
