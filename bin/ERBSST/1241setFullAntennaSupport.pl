#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : Patch for LTE 11.2.8 ST Simulations 
# Purpose     : TEP Request : 6038
# Description : implements PCI dependent full antenna support  
# CDM         : LMI-11:0119  
# Date        : Feb 2011
# Who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 13A
# Purpose     : Sprint 2 Feature 3b -> Combined Cell (Multi-sector Cell)-Part 2
#               Sprint 2 Feature 3c -> Combined Cell (Multi-sector Cell)-Part 3
# Description : Enables support for single and/or multiple SectorCarrier
#               with Combined Cell from MIM L13A (MIM D125) onwards.
#               Also supports MIMs that are older than L13A (MIM D125) with
#               no Combined Cell support
#               Includes for FDD/TDD cell deprecation of the following attributes :
#               - maxTransmissionPower and SectorFunctionRef
#               Feature Summation :
#               1. maintains support for non Combinced Cells (per L13A/D125)
#               2. supports Combined Cell single sector
#               3. supports Combinde Cell multi sectors
# CDM         : 25/159 41-FCP 121 9272
# Date        : August 2012
# Who         : epatdal
#####################################################################
####################################################################
# Version4    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version5    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version6    : LTE 14A 
# Revision    : CXP 903 0491-42-19
# Jira        : NETSUP-1019
# Purpose     : check sim type which is either of type PICO or LTE 
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next 
#               script                             
# Date        : Jan 2014
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 15B
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
# Version9    : LTE 17B
# Revision    : CXP 903 0491-288-1
# Jira        : NSS-8645
# Purpose     : Increase RetSubUnit to 1.5 per cell
# Description : To increase the RetSubUnits average for the network
#               to be 1.5
# Date        : March 2017
# Who         : xsrilek
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
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
local $MIMVERSION=&queryMIM($SIMNAME);
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum,$tcellnum,$tcount,$asu,$tempAntennaUnit,$maxAntennaUnit,$tempRetSubUnit,$maxRetSubUnit;
local $NODESIM,$nodecountinteger;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);

# Combined Cell mim support requirements
local $MIMiuantAntennaGainSupport="B153";
local $MIMCombinedCellSupport="D125";# indicates support for pre Combined Cell feature
local $mimcomparisonstatus="oops";# indicates support for Combined Cell (yes/no)
local $mimcomparisonstatus2="oops";# indicates support for Combined Cell (yes/no)
local $percentmultisector=&getENVfilevalue($ENV,"PERCENTAGEOFMULTISECTORCELLS");
local $maxmultisectors=&getENVfilevalue($ENV,"MAXMULTISECTORCELLS");
local $numberofmultisectornodes=ceil(($NETWORKCELLSIZE/100)*$percentmultisector);
# when supported node interval for multisector cells
local $multisectornodeinterval=ceil(($NETWORKCELLSIZE/$numberofmultisectornodes)/$STATICCELLNUM);
local $requiredsectorcarriers;
local $MAXALLOWEDSECTORMOS=48;
local $maxtranspower=120;
local $sectorcarrierrefpercell=0;
local $sectorcarriersectorfuntionrefnumber;
local $sectorcarrierid;
local $sectorstatus;
local $tempcellcounter=0;
local @tempsectorcarrierrefarray;
local $mycounter,$mycounter2;
local $numofsectorfuncequiment=0;
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
# check if combined cell sector feature supported for sim mim version
$mimcomparisonstatus2=&isgreaterthanMIM($MIMVERSION,$MIMCombinedCellSupport);

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
  $CELLNUM=@primarycells;

  # check cell type
  # checking one cell on the node in this instance and then assuming all other cells are the same
  # this is a good assumption but would have been future proof to do per cell
  # CXP 903 0491-135-1
  if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
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
  # deprecate cell sectorFunctionRef for sectorCarrierRef
  ############################
  # start cell sectorCarrierRef
  ############################
  $tempcellnum=1;
  # enable cell multi sectors
  if ($nodecountinteger % $multisectornodeinterval==0){# start if multi sectors
      $requiredsectorcarriers=($CELLNUM*$maxmultisectors);
      if($requiredsectorcarriers>$MAXALLOWEDSECTORMOS){$requiredsectorcarriers=$MAXALLOWEDSECTORMOS;}
        $sectorstatus=2;
  }# end if
  # enable cell single sector
  else{$requiredsectorcarriers=$CELLNUM;$sectorstatus=1;}
  $sectorcarrierrefpercell=int($requiredsectorcarriers/$CELLNUM);

  $tempcellcounter=0;
  
  # create cell single sector reference 
  while(($tempcellnum<=$CELLNUM)&&($sectorstatus==1)){

    @MOCmds=qq^ SET
    (
    mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$tempcellnum"
    exception none
    nrOfAttributes 1
     sectorCarrierRef Array Ref $sectorcarrierrefpercell
        "ManagedElement=1,ENodeBFunction=1,SectorCarrier=$tempcellnum"
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellnum++;
  }# end while cell single sector reference


   # create multi single sector reference
    $mycounter2=1;
    while(($tempcellnum<=$CELLNUM)&&($sectorstatus==2)){
     
     $mycounter=0;
     
     @tempsectorcarrierrefarray=();
     # build sectorCarrierRef multiple sector array
     while($mycounter<$sectorcarrierrefpercell){
          $sectorcarrierrefarray[$mycounter]="ManagedElement=1,ENodeBFunction=1,SectorCarrier=$mycounter2\n";
          $mycounter++;$mycounter2++
     }# end while build sectorCarrierRef multiple array

    @MOCmds=qq^ SET
    (
    mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$tempcellnum"
    exception none
    nrOfAttributes $sectorcarrierrefpercell
     sectorCarrierRef Array Ref $sectorcarrierrefpercell
     @sectorcarrierrefarray
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellnum++;
  }# end while multi single sector reference

  ############################
  # end cell sectorCarrierRef
  ############################
  }# end if combined cell required

  if($mimcomparisonstatus2 eq "yes"){ # start if combined cell required
  ########################################
  # start sectorCarrier sectorFunctionRef
  ########################################
  $sectorcarriersectorfuntionrefnumber=int($requiredsectorcarriers/$CELLNUM);
  $tempcellnum=1;$sectorcarrierid=1;
  $tempcellcounter=0;

  # single sector
  while(($tempcellnum<=$requiredsectorcarriers)&&($sectorstatus==1)){ # workaround
    @MOCmds=qq^ SET
    (
    mo "ManagedElement=1,ENodeBFunction=1,SectorCarrier=$sectorcarrierid"
    exception none
    nrOfAttributes 1
    sectorFunctionRef Ref "ManagedElement=1,SectorEquipmentFunction=$tempcellnum"
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellcounter++;

    if($tempcellcounter==$sectorcarriersectorfuntionrefnumber){
        $tempcellnum++;
        $tempcellcounter=0;
    }# end inner if

    $sectorcarrierid++;
  }# end while single sector
 
  $sectorcarrierid=1;
  $numofsectorfuncequiment=$CELLNUM;

  # multi sector
  while(($sectorcarrierid<=$requiredsectorcarriers)&&($sectorstatus==2)){
    @MOCmds=qq^ SET
     (
      mo "ManagedElement=1,ENodeBFunction=1,SectorCarrier=$sectorcarrierid"
      exception none
      nrOfAttributes 1
      sectorFunctionRef Ref "ManagedElement=1,SectorEquipmentFunction=$tempcellnum"
     )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellcounter++;

    if($tempcellcounter==$sectorcarriersectorfuntionrefnumber){
       $tempcellnum++;
      if($tempcellnum>$numofsectorfuncequiment){$tempcellnum=$numofsectorfuncequiment;}
        else{$tempcellcounter=0};
    }# end inner if

    $sectorcarrierid++;
  }# end while multi sector

  ########################################
  # end sectorCarrier sectorFunctionRef
  ########################################
  }# end if combined cell required

  if($mimcomparisonstatus2 eq "no"){ # start if combined cell not required
  ############################
  # start cell sectorFunctionRef
  ############################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){ 
    @MOCmds=qq^ SET
    (
    mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$tempcellnum"
    exception none
    nrOfAttributes 1
    sectorFunctionRef Ref "ManagedElement=1,SectorEquipmentFunction=$tempcellnum"
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
  }# end while
  ############################
  # end cell sectorFunctionRef
  ############################
  }# end if combined cell not required

  ############################
  # start rfBranchRef
  ############################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){ 
    @MOCmds=qq^ SET
   (
    mo "ManagedElement=1,SectorEquipmentFunction=$tempcellnum"
    exception none
    nrOfAttributes 2
    "rfBranchRef" Array Ref 2
        "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=1"
        "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=2"
   )
     ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
  }# end while CELLNUM
  ############################
  # end rfBranchRef
  ############################
  ############################
  # start auPortRef
  ############################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){
    @MOCmds=qq^ SET
   (
    mo "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=1"
    exception none
    nrOfAttributes 1
    "auPortRef" Array Ref $maxAntennaUnit ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	$tempAntennaUnit=1;
	while ($tempAntennaUnit <= $maxAntennaUnit) {
        @MOCmds=qq^      "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1,AuPort=1"^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;
		}

    @MOCmds=qq^ )
     SET
    (
    mo "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=2"
    exception none
    nrOfAttributes 1
    "auPortRef" Array Ref $maxAntennaUnit ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	$tempAntennaUnit=1;
	while ($tempAntennaUnit <= $maxAntennaUnit) {
        @MOCmds=qq^      "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1,AuPort=2"^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;
		}
   @MOCmds=qq^ )^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $tempcellnum++;
  }# end while
  ############################
  # end auportRef
  ############################
   ############################
  # start retSubunitRef
  ############################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){ # while CELLNUM
  $tempAntennaUnit=1;
  $tempRetSubUnit=1;
	while ($tempAntennaUnit <= $maxAntennaUnit) {
		@MOCmds=qq^ SET
		(
		mo "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1"
		exception none
		nrOfAttributes 1
		retSubunitRef Ref "ManagedElement=1,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaNearUnit=1,RetSubUnit=$tempRetSubUnit"
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;$tempRetSubUnit++;
		}
   $tempcellnum++;
  }# end while
  ############################
  # end retSubunitRef
  ############################

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
