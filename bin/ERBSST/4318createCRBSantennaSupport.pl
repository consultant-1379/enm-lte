#!/usr/bin/perl
### VERSION HISTORY
###########################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-154-1
# Jira        : OSS-77930
# Purpose     : implements PCI dependent full antenna support for DG2 nodes
# Description : Creating MOs SectorCarrier,SectorEquipmentFunction,
#		AntennaUnitGroup, AntennaNearUnit, AntennaUnit, 
#		TmaSubUnit, RetSubUnit, AntennaSubunit, AuPort
# Date        : June 2015
# Who         : xsrilek
###########################################################################
###########################################################################
# Version2    : LTE 15.16
# Revision    : CXP 903 0491-178-1
# Jira        : NS-220
# Purpose     : Create RmeSupport:NodeSupport MO  
# Description : Create RmeSupport:NodeSupport MO under 
#               ComTop:ManagedElement=LTENAME, and SectorEquipmentFunction 
#               under ComTop:ManagedElement=LTENAME,RmeSupport:NodeSupport=1
# Date        : Oct 2015
# Who         : ejamfur
###########################################################################
###########################################################################
# Version3    : LTE 15.16
# Revision    : CXP 903 0491-183-1
# Jira        : NSS-685
# Purpose     : MIM support for MIMs >= 16A 
# Description : iuantAntennaGain data type changed to Int64 for >= 16A              
# Date        : Nov 2015
# Who         : ejamfur
###########################################################################
###########################################################################
# Version4    : LTE 16.15
# Revision    : CXP 903 0491-255-1
# Jira        : NSS-6206
# Purpose     : Handle change in RetSubUnit MO attributes from 17A-V10
# Description : RetSubUnit MO attributes updated
# Date        : Sep 2016
# Who         : xkatmri
###########################################################################
####################################################################
# Version5    : LTE 17B
# Revision    : CXP 903 0491-288-1
# Jira        : NSS-8645
# Purpose     : Increase RetSubUnit to 1.5 per cell
# Description : To increase the RetSubUnits average for the network
#               to be 1.5
# Date        : March 2017
# Who         : xsrilek
####################################################################
####################################################################
# Version6    : LTE 19.04
# Revision    : CXP 903 0491-348-1
# Jira        : NSS-22789
# Purpose     : Creating the mos for CBSD support 
# Description : To create Rfbranches for 6cell TDD mRRUs
#               and Multicast Antenna for 12cell TDD DOTS
# Date        : January 2019
# Who         : xharidu
####################################################################
# Version6    : LTE 20.08
# Revision    : CXP 903 0491-361-1
# Jira        : NSS-30062
# Purpose     : Modify CBSD support for only DOTS and 4408
# Description : To create Rfbranches for 6cell TDD mRRUs
#               and Multicast Antenna for 12cell TDD DOTS
# Date        : April 2020
# Who         : xharidu
####################################################################
# Version7    : LTE 20.16
# Revision    : CXP 903 0491-368-1
# Jira        : NSS-28950
# Purpose     : Modify CBSD support for DOT, 4408 and 6448
# Description : Bypass this script for the nodes assigned for CBSD
# Date        : September 2020
# Who         : xharidu
####################################################################
# Version8   : LTE 20.16
# # Revision    : CXP 903 0491-369-1
# # Jira        : NSS-35689
# # Purpose     : Add CBSD support for 4x4 DOT
# # Description : Bypass this script for the nodes assigned for CBSD
# # Date        : November 2021
# # Who         : znamjag
# ####################################################################


####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use POSIX;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTE15B-v6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# check if SIMNAME is of type PICO or DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
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
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $nodecountinteger,$tempcellnum,$tempAntennaUnit,$maxAntennaUnit,$tempRetSubUnit,$maxRetSubUnit;
local $bearing;
local $NODESIM,$nodecountinteger;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $percentmultisector=&getENVfilevalue($ENV,"PERCENTAGEOFMULTISECTORCELLS");
local $maxmultisectors=&getENVfilevalue($ENV,"MAXMULTISECTORCELLS");
local $numberofmultisectornodes=ceil(($NETWORKCELLSIZE/100)*$percentmultisector);
# when supported node interval for multisector cells
local $multisectornodeinterval=ceil(($NETWORKCELLSIZE/$numberofmultisectornodes)/$STATICCELLNUM);
local $requiredsectorcarriers;
local $MAXALLOWEDSECTORMOS=48;
local $maxtranspower=120;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# MAIN
################################
################################
# Make MO & MML Scripts
################################
if (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE))){
    print "\nThe cbrs configuration is not applicable ..\n";
    exit 0;
}

while ($NODECOUNT<=$NUMOFRBS){

    ##########################
    # MIM version support
    ##########################
    local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
    local $post15BV11MIM=&isgreaterthanMIM($MIMVERSION,"15B-V13");
    local $post16AMIM=&isgreaterthanMIM($MIMVERSION,"16A-V1");
    local $intDataType=($post16AMIM eq "yes") ? "Int64" : "Int32";
    local $post17AV10MIM=&isgreaterthanMIM($MIMVERSION,"17A-V10");
    local $ANTENNAGAINMO=($post17AV10MIM eq "yes") ? "iuantAntennaOperatingGain" : "iuantAntennaGain";

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # set cell configuration ex: 6,3,3,1 etc.....
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
  $CELLNUM=@primarycells;

  # get cbsd device type
  $cbrsType=&getCbrsType($nodecountinteger,$CELLNUM);
  if ($cbrsType eq "SKIP") {
        $NODECOUNT++;
        next;
  }
  ####################################################
  if ($cbrsType eq "4442_4x4"){
	$noOfAntennas = 2;
         $configuredMaxTxPower = 25;
         $sectorEquipmentNum=$CELLNUM;
         $sectoroffset=2;
         $totalTilt=-900;
  }elsif ($cbrsType eq "4442_2x2") {
         $noOfAntennas = 2;
         $configuredMaxTxPower = 200;
         $sectorEquipmentNum = int($CELLNUM/2);
         $sectoroffset=2;
         $totalTilt=-900;
  } elsif ($cbrsType eq "4408") {
         $noOfAntennas = 4;
         $configuredMaxTxPower = 1950;
         $sectorEquipmentNum = int($CELLNUM/6);
         $sectoroffset=6;
         $totalTilt=0;
  } elsif ($cbrsType eq "6448") {
         $noOfAntennas = 0;
         $configuredMaxTxPower = 250;
         $sectorEquipmentNum = int($CELLNUM/6);
         $sectoroffset=6;
         $totalTilt=-900;
  } else {
          $noOfAntennas = 0;
          $configuredMaxTxPower = 200;
          $sectorEquipmentNum = 1;
          $sectoroffset=6;
         $totalTilt=-900;
  }
  if ( $sectorEquipmentNum == 0 ) {
         $sectorEquipmentNum = 1;
         $sectoroffset=6;
  }
    $totalAntennaGroups=$sectorEquipmentNum;
   ################################
   # start AntennaUnitGroup
   ################################
   @MOCmds=();
   $antennaGroupCount=1;
   while($antennaGroupCount<=$totalAntennaGroups){ 
      @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
       identity $antennaGroupCount
       moType ReqAntennaSystem:AntennaUnitGroup
       exception none
       nrOfAttributes 1
       antennaUnitGroupId String $antennaGroupCount
       )
       ^;# end @MO
       $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
       if ($cbrsType eq "4442_2x2" or $cbrsType eq "4442_4x4") {

           $multicastAntennaCount=1;
           while($multicastAntennaCount <= 2) {
          @MOCmds=qq^CREATE
    (
     parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antennaGroupCount"
     identity $multicastAntennaCount
     moType ReqAntennaSystem:MulticastAntennaBranch
     exception none
     nrOfAttributes 1
     "multicastAntennaBranchId" String $multicastAntennaCount
    )
^;
          $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds); 
          $multicastAntennaCount++;
          }
	if($cbrsType eq "4442_4x4"){
	   if($antennaGroupCount%2 == 0){
		my $sectorEquipmentFunId=int($antennaGroupCount/2);
		my $prevAntennaGroupCount=int($antennaGroupCount-1);
          @MOCmds=qq^SET
       (
       mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeSectorEquipmentFunction:SectorEquipmentFunction=$sectorEquipmentFunId"
       exception none
       nrOfAttributes 1
       administrativeState Integer 1
       "rfBranchRef" Array Ref 4
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$prevAntennaGroupCount,MulticastAntennaBranch=1"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$prevAntennaGroupCount,MulticastAntennaBranch=2"
	    "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,MulticastAntennaBranch=1"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,MulticastAntennaBranch=2"
    
       )
^;
	}
}else{
	 @MOCmds=qq^SET
       (
       mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeSectorEquipmentFunction:SectorEquipmentFunction=$antennaGroupCount"
       exception none
       nrOfAttributes 1
       administrativeState Integer 1
       "rfBranchRef" Array Ref 2
	    "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,MulticastAntennaBranch=1"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,MulticastAntennaBranch=2"
    
       )
^;
	}
          $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);


       } elsif ($cbrsType eq "4408") {

   ##################################
   #  create AntennaUnit & AntennaSubUnit
   ##################################
           @MOCmds=qq^ CREATE
          (
          parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antennaGroupCount"
          identity 1
          moType ReqAntennaSystem:AntennaUnit
          exception none
          nrOfAttributes 1
          antennaUnitId String 1
          )
          CREATE
        (
        parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antennaGroupCount,ReqAntennaSystem:AntennaUnit=1"
        identity 1
        moType ReqAntennaSystem:AntennaSubunit
        exception none
        nrOfAttributes 1
         antennaSubunitId String 1
         totalTilt Int32 $totalTilt
        )
        ^;# end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   #################################
   # create rfBranch
   #################################
           $rfBranchCount=1;
           while($rfBranchCount <= 4) {
    @MOCmds=qq^ CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antennaGroupCount"
    identity $rfBranchCount
    moType ReqAntennaSystem:RfBranch
    exception none
    nrOfAttributes 1
    rfBranchId String $rfBranchCount
    )
    ^;# end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $rfBranchCount++;
           }
           @MOCmds=qq^SET
       (
       mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeSectorEquipmentFunction:SectorEquipmentFunction=$antennaGroupCount"
       exception none
       nrOfAttributes 1
       administrativeState Integer 1
       "rfBranchRef" Array Ref 4
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,RfBranch=1"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,RfBranch=2"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,RfBranch=3"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$antennaGroupCount,RfBranch=4"
       )
^;
          $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

       }

       $antennaGroupCount++;
   }# end while

 push(@NETSIMMOSCRIPTS,$NETSIMMOSCRIPT);

 # build mml script
  @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
 
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  
  $NODECOUNT++;
}# end outer NODECOUNT while

  # execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
  print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################

