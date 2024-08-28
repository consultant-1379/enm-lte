#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : GA-LTE14B 
# Purpose     : re-set iuantAntennaGain for RetSubUnit and TmaSubUnit MOs 
# Description : for MIM >= E1200 re-set iuantAntennaGain for RetSubUnit 
#               and TmaSubUnit MOs on copied 1240createFullAntennaSupport_E1200.pl 
# Date        : Nov 2014
# Who         : epatdal
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
# Version3    : LTE 15B
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
# Version4    : LTE 17A
# Revision    : CXP 903 0491-252-1
# Jira        : NSS-6119
# Purpose     : H1120 cpp mim throwing error in build due to change
#               in MO structure
# Description : Updated the checking condition as per the updated
#               MO Structure
# Date        : Aug 2016
# Who         : xmitsin
####################################################################
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

###################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use POSIX;
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
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $MIMVERSION=&queryMIM($SIMNAME);
local $nodecountinteger,$tempcellnum,$tempAntennaUnit,$maxAntennaUnit,$tempRetSubUnit,$maxRetSubUnit;
local $bearing,$ANTENNAGAINMO;
local $NODESIM,$nodecountinteger;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);

# Combined Cell mim support requirements
local $MIMiuantAntennaGainSupport="B153";
local $MIMiuantAntennaGainSupport_new="H1100";
local $MIMCombinedCellSupport="D125";# indicates support for pre Combined Cell feature
local $MIMiuantSupport="E1200";
local $mimcomparisonstatus="oops";# indicates support for Combined Cell (yes/no)
local $mimcomparisonstatus_new="oops";# indicates support for Combined Cell (yes/no)
local $mimcomparisonstatus2="oops";# indicates support for Combined Cell (yes/no)
local $mimcomparisonstatus3="oops";
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
# Workaround for continuted usage of iuantAntennGain in 12.2.7
#            -> should change to iuantAntennaOperatingGain presently
# check if this sim mimversion is greater than $MIMiuantAntennaGainSupport
# if ($MIMVERSION lt 'B153')

$mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMiuantAntennaGainSupport);
$mimcomparisonstatus_new=&isgreaterthanMIM($MIMiuantAntennaGainSupport_new,$MIMVERSION);


if($mimcomparisonstatus eq "yes" && $mimcomparisonstatus_new eq "yes")
{
    $ANTENNAGAINMO='iuantAntennaGain';
}
else {
$ANTENNAGAINMO='iuantAntennaOperatingGain';
}
# end else


# check if combined cell sector feature supported for sim mim version
$mimcomparisonstatus2=&isgreaterthanMIM($MIMVERSION,$MIMCombinedCellSupport);

# CXP 903 0491-83-1, 29/08/2014
$mimcomparisonstatus3=&isgreaterthanMIM($MIMVERSION,$MIMiuantSupport);
if($mimcomparisonstatus3 eq "yes"){print "INFO : Full Antenna Support is being executed for $MIMVERSION which >= MIM E1200\n";}
 else {print "INFO : Full Antenna Support is NOT being executed for $MIMVERSION which < MIM E1200\n";exit;}

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # set cell configuration ex: 6,3,3,1 etc.....
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
  $CELLNUM=@primarycells;

  # check cell type
  # SJ NETSUP-2748 - CXP 903 0491-135-1
  if(($NODECOUNT<=$NUMOF_FDDNODES) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="EUtranCellFDD";
  }# end if
  else{
     $TYPE="EUtranCellTDD";
  }# end else

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

   if($mimcomparisonstatus2 eq "yes"){ # start if combined cell required
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

   while($tempcellnum<=$requiredsectorcarriers){
    @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1"
       identity $tempcellnum
       moType SectorCarrier
       exception none
       nrOfAttributes 11
        SectorCarrierId  String $tempcellnum
        availabilityStatus  Integer 0
        maximumTransmissionPower Integer $maxtranspower
        noOfRxAntennas Integer 0
        noOfTxAntennas Integer 0
        operationalState Integer 0
        partOfSectorPower Integer 100
        pmActiveUeDlSumSectorCarrier Integer 0
        pmActiveUeUlSumSectorCarrier Integer 0
        pmZtemporary56 Integer 0
        prsEnabled Boolean true
      )
     ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ################################
   # end SectorCarrier
   ################################
   }# end if combined cell required

   ################################
   # start SectorEquipmentFunction
   ################################
   $tempcellnum=1;
   while($tempcellnum<=$CELLNUM){
    @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1"
       identity $tempcellnum
       moType SectorEquipmentFunction
       exception none
       nrOfAttributes 1
       SectorEquipmentFunctionId String $tempcellnum
       )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
   }# end while
   ################################
   # end SectorEquipmentFunction
   ################################
   ################################
   # start AntennaUnitGroup
   ################################
   $tempcellnum=1;
   while($tempcellnum<=$CELLNUM){
    @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,Equipment=1"
       identity $tempcellnum
       moType AntennaUnitGroup
       exception none
       nrOfAttributes 2
       AntennaUnitGroupId String $tempcellnum
       reservedBy Array Ref 0
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
    parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum"
    identity 1 
    moType RfBranch
    exception none
    nrOfAttributes 1
    RfBranchId String 1 
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=qq^ CREATE
    (
    parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum"
    identity 2 
    moType RfBranch
    exception none
    nrOfAttributes 1
    RfBranchId String 2     
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
    parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum"
    identity 1 
    moType AntennaNearUnit
    exception none
    nrOfAttributes 18
     AntennaNearUnitId String ""
     administrativeState Integer 1
     anuType Integer 0
     availabilityStatus Integer 0
     hardwareVersion String ""
     iuantDeviceType Integer 1
     onUnitUniqueId String ""
     operationalState Integer 0
     productNumber String ""
     rfPortRef Ref "null"
     selfTestStatus Integer 0
     serialNumber String ""
     softwareVersion String ""
     uniqueId String ""
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
  # GA-LTE14B re-set iuantAntennaGain
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){
    $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
    @MOCmds=qq^ CREATE
    (
      parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaNearUnit=1"
      identity 1 
      moType TmaSubUnit
      exception none
      nrOfAttributes 3
      TmaSubUnitId String 1 
      iuantAntennaBearing  Integer $bearing 
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
 # GA-LTE14B re-set iuantAntennaGain
 $tempcellnum=1;

 if ($ANTENNAGAINMO eq 'iuantAntennaGain'){
  while($tempcellnum<=$CELLNUM){
  $tempRetSubUnit=1;
     $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
     while ($tempRetSubUnit <= $maxRetSubUnit) {
		 @MOCmds=qq^ CREATE
		 (
		   parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaNearUnit=1"
		   identity $tempRetSubUnit
		   moType RetSubUnit
		   exception none
		   nrOfAttributes 3
			RetSubUnitId String 1
			iuantAntennaBearing Integer $bearing
			$ANTENNAGAINMO Integer 185
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
     $bearing=($tempcellnum-1)*int(3600/$CELLNUM);
     $tempRetSubUnit=1;
     while ($tempRetSubUnit <= $maxRetSubUnit) {
	 @MOCmds=qq^ CREATE
	 (
	   parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaNearUnit=1"
	   identity $tempRetSubUnit
	   moType RetSubUnit
	   exception none
	   nrOfAttributes 3
		RetSubUnitId String 1
		iuantAntennaBearing Integer $bearing
		$ANTENNAGAINMO Array Integer 1
		185
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
	  parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum"
	  identity $tempAntennaUnit
	  moType AntennaUnit
	  exception none
	  nrOfAttributes 2
	  AntennaUnitId String $tempAntennaUnit
	  mechanicalAntennaTilt Integer 0
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
		parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit"
		identity 1
		moType AntennaSubunit
		exception none
		nrOfAttributes 1
		 AntennaSubunitId String 1
		 maxTotalTilt Integer 900
		 minTotalTilt Integer -900
		 retSubunitRef Ref "null"
		 totalTilt Integer -900
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
		parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1"
		identity 1
		moType AuPort
		exception none
		nrOfAttributes 3
		AuPortId String 1
		reservedBy Array Ref 0
		userLabel String ""
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		@MOCmds=qq^ CREATE
		(
		parent "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1"
		identity 2
		moType AuPort
		exception none
		nrOfAttributes 3
		AuPortId String 2
		reservedBy Array Ref 0
		userLabel String ""
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
