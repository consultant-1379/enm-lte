#!/usr/bin/perl
### VERSION HISTORY
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
# Version7    : LTE 21.18
# # Revision    : CXP 903 0491-362-1
# # Jira        : NSS-35689
# # Purpose     : Add CBSD support for 4x4 DOT
# # Description : To create Rfbranches for 6cell TDD mRRUs
# #               and Multicast Antenna for 12cell TDD DOTS
# # Date        : November 2021
# # Who         : znamjag 
####################################################################
# Version7    : LTE 21.18
# # Revision    : CXP 903 0491-363-1
# # Jira        : NSS-36099
# # Purpose     : Serial number fix
# # Description : To create unique serial number for each frus
# # Date        : November 2021
# # Who         : znrvbia
#################################################################### 

####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_coordinates;
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
local $TYPE="EUtranCellTDD";
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
if (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE))) {
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
  $cbrsType=&getCbrsType($nodecountinteger,$CELLNUM);
  if ($cbrsType eq "SKIP") {
        $NODECOUNT++;
        next;
  }
  ####################################################
 if ($cbrsType eq "4442_4x4") {
         $noOfAntennas = 4;
         $configuredMaxTxPower = 25;
         $sectorEquipmentNum = ($CELLNUM/2);
         $sectoroffset=2;
         $totalTilt=-900;
  } elsif ($cbrsType eq "4442_2x2") {
         $noOfAntennas = 2;
         $configuredMaxTxPower = 200;
         $sectorEquipmentNum = ($CELLNUM/2);
         $sectoroffset=2;
         $totalTilt=-900;
  } elsif ($cbrsType eq "4408") {
         $noOfAntennas = 4;
         $configuredMaxTxPower = 1950;
         $sectorEquipmentNum = ($CELLNUM/6);
         $sectoroffset=6;
         $totalTilt=0;
  } elsif ($cbrsType eq "6448") {
         $noOfAntennas = 0;
         $configuredMaxTxPower = 250;
         $sectorEquipmentNum = ($CELLNUM/6);
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
         $totalTilt=-900;
  }
    $totalAntennaGroups=$sectorEquipmentNum;
    @MOCmds=();
   ################################
   # start FieldReplaceableUnit
   ################################

   if ($cbrsType eq "4442_4x4") {

   #################################
   #  DOTS
   #################################
	my $numOfFrus=($CELLNUM * 4);
	my $numOfIrus=$CELLNUM;
	my $serialString="TD3E";
        my $serialOffset=1;
        my $serialOffset2=$serialOffset;
        my $serialIruString="D8264";
        my $serialIruOffset=1;
        my $numofdevices=$numOfFrus;
           ## Creating FRU RDs #############
        for(my $frucount=1;$frucount<=$numOfFrus;$frucount++) {
	
           my $frusuffix2=($frusuffix + 1);
           my $fruId1="RD" . "-" . $frucount . "-1";
           my $fruId2="RD" . "-" . $frucount . "-2";
           my $serialNum1=$serialString . $LTE . $NODECOUNT . "00" . $serialOffset;
	   my $serialNum2=$serialNum1;
           my ($latitude,$longitude)=&getPositionCoordinates($LTE,$NODECOUNT,$frucount,$numofdevices,$DG2NUMOFRBS);
           @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity "$fruId1"
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String "$fruId1"
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 2180
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20180322"
        "productName" String "RD 4442 B48"
        "productNumber" String "KRY 901 385/1"
        "productRevision" String "R1C"
        "serialNumber" String "$serialNum1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity "$fruId2"
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String "$fruId2"
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 2180
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20180322"
        "productName" String "RD 4442 B48"
        "productNumber" String "KRY 901 385/1"
        "productRevision" String "R1C"
        "serialNumber" String "$serialNum2"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId1"
    identity "1"
    moType ReqTransceiver:Transceiver
    exception none
    nrOfAttributes 1
    "transceiverId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId2"
    identity "1"
    moType ReqTransceiver:Transceiver
    exception none
    nrOfAttributes 1
    "transceiverId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId1"
    identity 1
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId2"
    identity 1
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String "1"
    )^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           $serialOffset=($serialOffset + 1);
        }

        #Creating FRUs for IRUs###
        for(my $frucount=1;$frucount<=$numOfIrus;$frucount++) {
             my $productionDate="20171007";
             my $fruId="IRU-" . $frucount;
             my $serialIruNum=$serialIruString . $LTE . $NODECOUNT . "00" . $serialIruOffset;
	#my $serialIruNum="D826463200";
                 @MOCmds=qq^
       CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity $fruId
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 5
    "fieldReplaceableUnitId" String $fruId
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "productData" Struct
        nrOfElements 5
        "productionDate" String $productionDate
        "productName" String "IRU 2242"
        "productNumber" String "KRC 161 444/3"
        "productRevision" String "R1C"
        "serialNumber" String $serialIruNum
    )
CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId"
    identity "1"
    moType ReqRcvdPowerScanner:RcvdPowerScanner
    exception none
    nrOfAttributes 1
    "rcvdPowerScannerId" String "1"
    )
^;#end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              my $rdiPortnum=1;
             ### Creating RdiPorts to IRUs #########
              while ($rdiPortnum<=8) {
                 @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId"
    identity $rdiPortnum
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String $rdiPortnum
    )^;#end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $rdiPortnum++;
              } #end Rdiport while
              $serialIruOffset++;
        }#end IRU for loop
    }# end DOT if

elsif ($cbrsType eq "4442_2x2") {
	my $numOfFrus=($CELLNUM * 2);
       	my $numOfIrus=($CELLNUM / 2);
	my $serialString="TD3E";
        my $serialOffset=1;
        my $serialOffset2=$serialOffset;
        my $serialIruString="D8264";
        my $serialIruOffset=1;
        my $numofdevices=$numOfFrus;
           ## Creating FRU RDs #############
        for(my $frucount=1;$frucount<=$numOfFrus;$frucount++) {
	
           my $frusuffix2=($frusuffix + 1);
           my $fruId1="RD" . "-" . $frucount . "-1";
           my $fruId2="RD" . "-" . $frucount . "-2";
           my $serialNum1=$serialString . $LTE . $NODECOUNT . "00" . $serialOffset;
           my $serialNum2=$serialNum1;
           my ($latitude,$longitude)=&getPositionCoordinates($LTE,$NODECOUNT,$frucount,$numofdevices,$DG2NUMOFRBS);
           @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity "$fruId1"
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String "$fruId1"
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 2180
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20180322"
        "productName" String "RD 4442 B48"
        "productNumber" String "KRY 901 385/1"
        "productRevision" String "R1C"
        "serialNumber" String "$serialNum1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity "$fruId2"
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String "$fruId2"
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 2180
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20180322"
        "productName" String "RD 4442 B48"
        "productNumber" String "KRY 901 385/1"
        "productRevision" String "R1C"
        "serialNumber" String "$serialNum2"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId1"
    identity "1"
    moType ReqTransceiver:Transceiver
    exception none
    nrOfAttributes 1
    "transceiverId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId2"
    identity "1"
    moType ReqTransceiver:Transceiver
    exception none
    nrOfAttributes 1
    "transceiverId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId1"
    identity 1
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId2"
    identity 1
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String "1"
    )^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           $serialOffset=($serialOffset + 1);
        }

        #Creating FRUs for IRUs###
        for(my $frucount=1;$frucount<=$numOfIrus;$frucount++) {
             my $productionDate="20170927";
             my $fruId="IRU-" . $frucount;
             my $serialIruNum=$serialIruString . $LTE . $NODECOUNT . "00" . $serialIruOffset;
                 @MOCmds=qq^
       CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity $fruId
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 5
    "fieldReplaceableUnitId" String $fruId
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "productData" Struct
        nrOfElements 5
        "productionDate" String $productionDate
        "productName" String "IRU 2242"
        "productNumber" String "KRC 161 444/3"
        "productRevision" String "R1C"
        "serialNumber" String $serialIruNum
    )
CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId"
    identity "1"
    moType ReqRcvdPowerScanner:RcvdPowerScanner
    exception none
    nrOfAttributes 1
    "rcvdPowerScannerId" String "1"
    )
^;#end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              my $rdiPortnum=1;
             ### Creating RdiPorts to IRUs #########
              while ($rdiPortnum<=8) {
                 @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fruId"
    identity $rdiPortnum
    moType ReqRdiPort:RdiPort
    exception none
    nrOfAttributes 1
    "rdiPortId" String $rdiPortnum
    )^;#end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $rdiPortnum++;
              } #end Rdiport while
              $serialIruOffset++;
        }#end IRU for loop
    }# end DOT if

    elsif ( $cbrsType eq "4408" ) {

        $fieldreplaceableUnitNum=int($CELLNUM/6);
        if ($fieldreplaceableUnitNum < 1 ) {
           $fieldreplaceableUnitNum=1;
        }
       $fieldreplaceableUnitCount=1;
       my $serialString="D8291";
       my $serialcount=1;
       while(($fieldreplaceableUnitCount<=$fieldreplaceableUnitNum)){
          my $serialNum=$serialString . $LTE . $NODECOUNT . "00" . $serialcount;
          my ($latitude,$longitude)=&getPositionCoordinates($LTE,$NODECOUNT,$fieldreplaceableUnitCount,$fieldreplaceableUnitNum,$DG2NUMOFRBS);
          @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity $fieldreplaceableUnitCount
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String $fieldreplaceableUnitCount
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 70
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20180301"
        "productName" String "Radio 4408 B48"
        "productNumber" String "KRC 161 746/1"
        "productRevision" String "R1B"
        "serialNumber" String "$serialNum"
    "administrativeState" Integer 1
    "operationalState" Integer 1
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "1"
    moType ReqRcvdPowerScanner:RcvdPowerScanner
    exception none
    nrOfAttributes 1
    "rcvdPowerScannerId" String "1"
    )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "A"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "A"
    "administrativeState" Integer 1
    "ulFrequencyRanges" String "3550000-3700000 KHz"
    )

    SET
        (
        mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$fieldreplaceableUnitCount,ReqAntennaSystem:RfBranch=1"
        exception none
        nrOfAttributes 1
        "rfPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,RfPort=A"
        )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "B"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "B"
    "administrativeState" Integer 1
    "ulFrequencyRanges" String "3550000-3700000 KHz"
    )

    SET
        (
        mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$fieldreplaceableUnitCount,ReqAntennaSystem:RfBranch=2"
        exception none
        nrOfAttributes 1
        "rfPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,RfPort=B"
        )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "C"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "C"
    "administrativeState" Integer 1
    "ulFrequencyRanges" String "3550000-3700000 KHz"
    )

     SET
        (
        mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$fieldreplaceableUnitCount,ReqAntennaSystem:RfBranch=3"
        exception none
        nrOfAttributes 1
        "rfPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,RfPort=C"
        )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "D"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "D"
    "administrativeState" Integer 1
    "ulFrequencyRanges" String "3550000-3700000 KHz"
    )

    SET
        (
        mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$fieldreplaceableUnitCount,ReqAntennaSystem:RfBranch=4"
        exception none
        nrOfAttributes 1
        "rfPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,RfPort=D"
        )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "RXA_IO"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "RXA_IO"
    )^;# end @MO
          $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
          $fieldreplaceableUnitCount++;
          $serialcount++;
       }

    } elsif ( $cbrsType eq "6448" ) {

       $fieldreplaceableUnitNum=int($CELLNUM/6);
        if ($fieldreplaceableUnitNum < 1 ) {
           $fieldreplaceableUnitNum=1;
        }
        $fieldreplaceableUnitCount=1;
        my $serialString="D8291";
        my $serialcount=1;
        while(($fieldreplaceableUnitCount<=$fieldreplaceableUnitNum)){
          my $serialNum=$serialString . $LTE . $NODECOUNT . "00" . $serialcount;
          my ($latitude,$longitude)=&getPositionCoordinates($LTE,$NODECOUNT,$fieldreplaceableUnitCount,$fieldreplaceableUnitNum,$DG2NUMOFRBS);
          @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity $fieldreplaceableUnitCount
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 6
    "fieldReplaceableUnitId" String $fieldreplaceableUnitCount
    "administrativeState" Integer 1
    "operationalState" Integer 1
    "availabilityStatus" Array Integer 1
	0
    "positionCoordinates" Struct
        nrOfElements 4
        "altitude" Int32 70
        "geoDatum" String "WGS84"
        "latitude" Int32 $latitude
        "longitude" Int32 $longitude
    "productData" Struct
        nrOfElements 5
        "productionDate" String "20190628"
        "productName" String "AIR 6488 B48"
        "productNumber" String "KRD 901 160/11"
        "productRevision" String "R1A"
        "serialNumber" String "$serialNum"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "1"
    moType ReqTransceiver:Transceiver
    exception none
    nrOfAttributes 1
    "transceiverId" String "1"
    )
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "1"
    moType ReqRcvdPowerScanner:RcvdPowerScanner
    exception none
    nrOfAttributes 1
    "rcvdPowerScannerId" String "1"
    )
    SET
    (
    mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeSectorEquipmentFunction:SectorEquipmentFunction=$fieldreplaceableUnitCount"
    exception none
    nrOfAttributes 2
    administrativeState Integer 1
    "rfBranchRef" Array Ref 1
       "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,Transceiver=1"
    )
^;
    #end @MO
          $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
          $sfpModuleCount=1;
          while ($sfpModuleCount <= 3) {
             $sfpModuleId="DATA_" . $sfpModuleCount;
             @MOCmds=qq^
CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "$sfpModuleId"
    moType ReqSfpModule:SfpModule
    exception none
    nrOfAttributes 2
    "administrativeState" Integer 1
    "sfpModuleId" String "$sfpModuleId"
)
CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount,ReqSfpModule:SfpModule=$sfpModuleId"
    identity "$sfpModuleCount"
    moType ReqSfpChannel:SfpChannel
    exception none
    nrOfAttributes 1
    "sfpChannelId" String "$sfpModuleCount"
)
CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "$sfpModuleId"
    moType ReqRiPort:RiPort
    exception none
    nrOfAttributes 5
    "administrativeState" Integer 1
    "channelRef" Array Ref 1
        "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,SfpModule=$sfpModuleId,SfpChannel=$sfpModuleCount"
    "riPortId" String "$sfpModuleId"
    "sfpModuleRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldreplaceableUnitCount,SfpModule=$sfpModuleId"
    "transmissionStandard" Integer 1
)
^;
             $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
             $sfpModuleCount++;

          }#end spfModule while
          $fieldreplaceableUnitCount++;
          $serialcount++;

        }# end fru while

    }#end 6448 config

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

