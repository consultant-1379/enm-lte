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
####################################################################
# Version7    : LTE 20.16
# Revision    : CXP 903 0491-369-1
# Jira        : NSS-32209
# Purpose     : Instantaneous Licensing functionality for Radionode
# Description : Instantaneous Licensing functionality for Radionode
# Date        : September 2020
# Who         : xmitsin
####################################################################
####################################################################
## Version7    : LTE 22.05
## Revision    : CXP 903 0491-379-1
## Jira        : NSS-38493
## Purpose     : Adding MOs and attributes to support firmware upgrade of generic support unit
## Description : Adding MOs and attributes to support firmware upgrade of generic support unit
## Date        : February 2022
## Who         : znrvbia
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
  # check cell type
  if(($NODECOUNT<=$NUMOFRBS) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))){
      $TYPE="Lrat:EUtranCellFDD";
      $cbrsType="SKIP";
  }# end if
  else{
     $TYPE="Lrat:EUtranCellTDD";
     $cbrsType=&getCbrsType($nodecountinteger,$CELLNUM);
  }# end else

  # check for CBRS nodes
  if($cbrsType ne "SKIP") {
     $NODECOUNT++;
     next;
  }
  # check no of RetSubUnit's required
  # CXP 903 0491-288-1
  if (&isNodeNumLocInReqPer($nodecountinteger) eq "true") {
	$maxAntennaUnit=2;
	$maxRetSubUnit=2;
  }
  else {
  	$maxAntennaUnit=1;
	$maxRetSubUnit=1;
  }

   ################################
   # start SectorCarrier
   ################################
   $tempcellnum=1;
   # enable cell multi sectors
   if ($nodecountinteger % $multisectornodeinterval==0){# start if multi sectors
      $requiredsectorcarriers=($CELLNUM*$maxmultisectors);
      if($requiredsectorcarriers>$MAXALLOWEDSECTORMOS){$requiredsectorcarriers=$MAXALLOWEDSECTORMOS;}
   }# end if
   # enable cell single sector
   else{$requiredsectorcarriers=$CELLNUM;}
   @MOCmds=(); 
   while($tempcellnum<=$requiredsectorcarriers){
    @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1"
       identity $tempcellnum
       moType Lrat:SectorCarrier
       exception none
       nrOfAttributes 11
        sectorCarrierId  String $tempcellnum
        maximumTransmissionPower Int32 $maxtranspower
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
       while($tempcellnum<=$CELLNUM){
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
       
       SET
      (
        mo "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1,RmeLicenseSupport:LicenseSupport=1,RmeLicenseSupport:InstantaneousLicensing=1"
        exception none
        nrOfAttributes 3
        "swltId" String "19DZ725311F4595D22D12666"
        "euft" String "949525"
        "availabilityStatus" Array Integer 1
          3

    )
    CREATE
    (
     parent "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1"
     identity "1"
     moType ReqExternalUpManager:ExternalUpManager
     exception none
     nrOfAttributes 1
     "externalUpManagerId" String "1"
    )
    SET
    (
     mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqSupportUnit:SupportUnit=1,ReqFwSlot:FwSlot=1"
     exception none
     nrOfAttributes 2
     "slotStatus" Integer 0
     "prioritized" Boolean false
    )
    CREATE
    (
     parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqSupportUnit:SupportUnit=1"
     identity "2"
     moType ReqFwSlot:FwSlot
     exception none
     nrOfAttributes 4
     "slotStatus" Integer 0
     "prioritized" Boolean false
     "fwSlotId" String "2"
     "activated" Boolean false
    )
    CREATE
    (
     parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
     identity "2"
     moType ReqSupportUnit:SupportUnit
     exception none
     nrOfAttributes 12
     "supportUnitId" String "2"
     "administrativeState" Integer 1
     "availabilityStatus" Array Integer 0
     "operationalState" Integer "null"
     "faultIndicator" Integer "null"
     "operationalIndicator" Integer "null"
     "productData" Struct
         nrOfElements 5
         "productionDate" String ""
         "productName" String ""
         "productNumber" String ""
         "productRevision" String ""
         "serialNumber" String ""

     "providedServices" Array Integer 0
     "reservedBy" Array Ref 0
     "specialIndicator" Array Struct 0
     "suAddressInfo" Array Struct 0
     "commandResult" String "null"
     )
    SET
    (
    mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqSupportUnit:SupportUnit=2,ReqFwSlot:FwSlot=1"
    exception none
    nrOfAttributes 2
    "slotStatus" Integer 0
    "prioritized" Boolean false
    )
    CREATE
    (
     parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqSupportUnit:SupportUnit=2"
     identity "2"
     moType ReqFwSlot:FwSlot
     exception none
     nrOfAttributes 3
     "slotStatus" Integer 0
     "prioritized" Boolean false
     "fwSlotId" String "2"
     "activated" Boolean false
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
   while($tempcellnum<=$CELLNUM){
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
   ################################
   # start AntennaUnitGroup
   ################################
   $tempcellnum=1;
   while($tempcellnum<=$CELLNUM){ 
    @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
       identity $tempcellnum 
       moType ReqAntennaSystem:AntennaUnitGroup
       exception none
       nrOfAttributes 1
       antennaUnitGroupId String $tempcellnum 
       )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ################################
   # end AntennaUnitGroup
   ################################
   ################################
   # start RfBranch
   ################################
   $tempcellnum=1;
   while($tempcellnum<=$CELLNUM){ 
    @MOCmds=qq^ CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum"
    identity 1 
    moType ReqAntennaSystem:RfBranch
    exception none
    nrOfAttributes 1
    rfBranchId String 1 
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=qq^ CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum"
    identity 2 
    moType ReqAntennaSystem:RfBranch
    exception none
    nrOfAttributes 1
    rfBranchId String 2     
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ################################
   # end RfBranch
   ################################
   ################################
   # start AntennaNearUnit
   ################################
   $tempcellnum=1;
   while($tempcellnum<=$CELLNUM){ 
    @MOCmds=qq^ CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum"
    identity 1 
    moType ReqAntennaSystem:AntennaNearUnit
    exception none
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ################################
   # end AntennaNearUnit
   ################################
  ################################
  # start TmaSubUnit
  ################################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){
    $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
    @MOCmds=qq^ CREATE
    (
      parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaNearUnit=1"
      identity 1
      moType ReqAntennaSystem:TmaSubUnit
      exception none
      nrOfAttributes 3
      tmaSubUnitId String 1 
      iuantAntennaBearing  Int32 $bearing 
      iuantAntennaOperatingGain Array Int32 1
      185
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
 }# end while
 ################################
 # end TmaSubUnit
 ################################
 ################################
 # start RetSubUnit
 ################################
 $tempcellnum=1;
 if ($ANTENNAGAINMO eq 'iuantAntennaGain'){
  while($tempcellnum<=$CELLNUM){
  $tempRetSubUnit=1;
     $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
	 while ($tempRetSubUnit <= $maxRetSubUnit) {
		 @MOCmds=qq^ CREATE
		 (
		   parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaNearUnit=1"
		   identity $tempRetSubUnit
		   moType ReqAntennaSystem:RetSubUnit
		   exception none
		   nrOfAttributes 3
			retSubUnitId String $tempRetSubUnit
			iuantAntennaBearing Int32 $bearing
			$ANTENNAGAINMO $intDataType 185
		 )
		 ^;# end @MO
		 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		 $tempRetSubUnit++;
	 }
    $tempcellnum++;
  }# end while
 }# end if

 else{
  while($tempcellnum<=$CELLNUM){
  $tempRetSubUnit=1;
  $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
	while ($tempRetSubUnit <= $maxRetSubUnit) {
		 @MOCmds=qq^ CREATE
		 (
		   parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaNearUnit=1"
		   identity $tempRetSubUnit
		   moType ReqAntennaSystem:RetSubUnit
		   exception none
		   nrOfAttributes 3
			retSubUnitId String $tempRetSubUnit
			iuantAntennaBearing Int32 $bearing
			$ANTENNAGAINMO Array Int32 4
			185
			0
			0
			0
		 )
		 ^;# end @MO
		 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		 $tempRetSubUnit++;
	 }
    $tempcellnum++;
  }# end while
 }# end if

 ################################
 # end RetSubUnit
 ################################
 ################################
 # start AntennaUnit
 ################################
 $tempcellnum=1;
 while($tempcellnum<=$CELLNUM){
 $tempAntennaUnit=1;
 	while ($tempAntennaUnit <= $maxAntennaUnit){
	  @MOCmds=qq^ CREATE
	  (
	  parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum"
	  identity $tempAntennaUnit
	  moType ReqAntennaSystem:AntennaUnit
	  exception none
	  nrOfAttributes 1
	  antennaUnitId String $tempAntennaUnit
	  )
	  ^;# end @MO
	  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	  $tempAntennaUnit++;
	  }
 $tempcellnum++;
 }# end while
 ################################
 # end AntennaUnit
 ################################
 ################################
 # start AntennaSubUnit
 ################################
 $tempcellnum=1;
 while($tempcellnum<=$CELLNUM){
 $tempAntennaUnit=1;
	while ($tempAntennaUnit <= $maxAntennaUnit){
	@MOCmds=qq^ CREATE
	(
	parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaUnit=$tempAntennaUnit"
	identity 1
	moType ReqAntennaSystem:AntennaSubunit
	exception none
	nrOfAttributes 1
	 antennaSubunitId String 1
	 totalTilt Int32 -900
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	$tempAntennaUnit++;
	}
   $tempcellnum++;
 }# end while
 ################################
 # end AntennaSubUnit
 ################################
 ################################
 # start AuPort
 ################################
 $tempcellnum=1;
 while($tempcellnum<=$CELLNUM){
 $tempAntennaUnit=1;
	while ($tempAntennaUnit <= $maxAntennaUnit){
		@MOCmds=qq^ CREATE
		(
		parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaUnit=$tempAntennaUnit,ReqAntennaSystem:AntennaSubunit=1"
		identity 1
		moType ReqAntennaSystem:AuPort
		exception none
		nrOfAttributes 3
		auPortId String 1
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

		@MOCmds=qq^ CREATE
		(
		parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$tempcellnum,ReqAntennaSystem:AntennaUnit=$tempAntennaUnit,ReqAntennaSystem:AntennaSubunit=1"
		identity 2 
		moType ReqAntennaSystem:AuPort
		exception none
		nrOfAttributes 3
		auPortId String 2 
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;
		}
   $tempcellnum++;
 }# end while tempcellnum
 ################################
 # end AuPort
 ################################

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

