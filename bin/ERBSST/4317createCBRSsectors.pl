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
# Version7    : LTE 20.08
# Revision    : CXP 903 0491-361-1
# Jira        : NSS-30062
# Purpose     : Modify CBSD support for only DOTS and 4408
# Description : To create Rfbranches for 6cell TDD mRRUs
#               and Multicast Antenna for 12cell TDD DOTS
# Date        : April 2020
# Who         : xharidu
####################################################################
# Version8    : LTE 20.16
# Revision    : CXP 903 0491-368-1
# Jira        : NSS-28950
# Purpose     : Modify CBSD support for DOT, 4408 and 6448
# Description : Create Sectors for TDD CBRS nodes
# Date        : September 2020
# Who         : xharidu
####################################################################
####################################################################
## Version9    : LTE 21.18
## Revision    : CXP 903 0491-369-1
## Jira        : NSS-35689
## Purpose     : Adding CBSD support for 4x4 DOT
## Description : Create Sectors for TDD CBRS nodes
## Date        : November 2021
## Who         : znamjag
#####################################################################


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
local $TYPE="Lrat:EUtranCellTDD";
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
  print "script1: $LTENAME , $CELLNUM , $cbrsType\n";
  # sector configuration details ##
 if ($cbrsType eq "4442_4x4") {
	print "script1: 4x4 type";
         $noOfAntennas =4;
         $configuredMaxTxPower = 25;
         $sectorEquipmentNum = int($CELLNUM/2);
         $sectoroffset=2;
  }
  elsif ($cbrsType eq "4442_2x2") {
         $noOfAntennas = 2;
         $configuredMaxTxPower = 200;
         $sectorEquipmentNum = int($CELLNUM/2);
         $sectoroffset=2;
  } elsif ($cbrsType eq "4408") {
         $noOfAntennas = 4;
         $configuredMaxTxPower = 1950;
         $sectorEquipmentNum = int($CELLNUM/6);
         $sectoroffset=6;
  } elsif ($cbrsType eq "6448") {
         $noOfAntennas = 0;
         $configuredMaxTxPower = 250;
         $sectorEquipmentNum = int($CELLNUM/6);
         $sectoroffset=6;
  } else {
          $noOfAntennas = 0;
          $configuredMaxTxPower = 200;
          $sectorEquipmentNum = 1;
          $sectoroffset=6;
  }
  if ( $sectorEquipmentNum == 0 ) {
       $sectorEquipmentNum = 1;
       $sectoroffset=6;
  }
   ################################
   # start SectorCarrier
   ################################
   $tempcellnum=1;
   @MOCmds=(); 
   while($tempcellnum<=$CELLNUM){
    @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1"
       identity $tempcellnum
       moType Lrat:SectorCarrier
       exception none
       nrOfAttributes 11
        sectorCarrierId  String $tempcellnum
        maximumTransmissionPower Int32 $maxtranspower
        "configuredMaxTxPower" Int32 $configuredMaxTxPower
        "noOfTxAntennas" Int32 $noOfAntennas
        "noOfRxAntennas" Int32 $noOfAntennas

       )
       SET
       (
        mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$tempcellnum"
        exception none
        nrOfAttributes 3
        sectorCarrierRef Array Ref 1
             "ManagedElement=$LTENAME,ENodeBFunction=1,SectorCarrier=$tempcellnum"
        "cbrsCell" Boolean true
        "eutranCellCoverage" Struct
            nrOfElements 3
            "posCellRadius" Int32 1000
            "posCellOpeningAngle" Int32 1200
            "posCellBearing" Int32 830
       )
     ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellnum++;
   }# end while
   ################################
   # end SectorCarrier
   ################################
   ################################
   # start SectorEquipmentFunction
   ################################
   if ($post15BV11MIM=~m/no/) {
       $tempcellnum=1;
       while($tempcellnum<=$sectorEquipmentNum){
        @MOCmds=qq^ CREATE
        (
        parent "ComTop:ManagedElement=$LTENAME"
        identity $tempcellnum
        moType RmeSectorEquipmentFunction:SectorEquipmentFunction
        exception none
        nrOfAttributes 1
        sectorEquipmentFunctionId String $tempcellnum
        )
        ^;# end @MO
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        $tempcellnum++;
       }# end while
   }# end if
   ################################
   # end SectorEquipmentFunction
   ################################
   ################################
   # start NodeSupport 
   ################################
    @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME"
       identity "1"
       moType RmeSupport:NodeSupport
       exception none
       nrOfAttributes 1
       nodeSupportId String "1"
       )
       CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1"
      identity "1"
      moType RmeUlSpectrumAnalyzer:UlSpectrumAnalyzer
      exception none
      nrOfAttributes 1
      "ulSpectrumAnalyzerId" String "1"
      )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   ################################
   # end NodeSupport 
   ################################
   ############################################
   # start NodeSupport SectorEquipmentFunction
   ############################################
   $tempcellnum=1;
   while($tempcellnum<=$sectorEquipmentNum){
    @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1"
       identity $tempcellnum
       moType RmeSectorEquipmentFunction:SectorEquipmentFunction
       exception none
       nrOfAttributes 1
       sectorEquipmentFunctionId String $tempcellnum
       )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ############################################
   # end NodeSupport SectorEquipmentFunction
   ############################################
   ############################################
   # set references to SectorEquipmentFunction
   ############################################
   $tempcellnum=1;
   $sectorEquipmentNum=1;
   while($tempcellnum<=$CELLNUM){
         @MOCmds=qq^ SET
       (
        mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:SectorCarrier=$tempcellnum"
        exception none
        nrOfAttributes 1
        sectorFunctionRef Ref "ManagedElement=$LTENAME,NodeSupport=1,SectorEquipmentFunction=$sectorEquipmentNum"
        )
^;# end @MO
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        if (($tempcellnum % $sectoroffset)==0) {
               $sectorEquipmentNum++;
        }
        $tempcellnum++;
    }
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

