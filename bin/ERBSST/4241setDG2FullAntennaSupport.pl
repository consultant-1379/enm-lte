#!/usr/bin/perl
### VERSION HISTORY
############################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-154-1
# Jira        : OSS-77930
# Purpose     : implements PCI dependent full antenna support for DG2 nodes
# Description : setting MOs RfBranch,AntennaSubunit
# Date        : June 2015
# Who         : xsrilek
############################################################################
############################################################################
# Version2    : LTE 15.16
# Revision    : CXP 903 0491-178-1
# Jira        : NS-220
# Purpose     : create NodeSupport SectorEquipmentFunction rfBranchRef
# Description : create SectorEquipmentFunction rfBranchRef under
#               ManagedElement=$LTENAME, NodeSupport=1;
# Date        : Oct 2015
# Who         : ejamfur
############################################################################
############################################################################
# Version3    : LTE 17B
# Revision    : CXP 903 0491-288-1
# Jira        : NSS-8645
# Purpose     : Increase RetSubUnit to 1.5 per cell
# Description : To increase the RetSubUnits average for the network
#               to be 1.5
# Date        : March 2017
# Who         : xsrilek
############################################################################
############################################################################
# Version4    : LTE 19.04
# Revision    : CXP 903 0491-348-1
# Jira        : NSS-22789
# Purpose     : Creating the mos for TDD cell nodes for CBSD support 
# Description : To create references for Rfbranches and AuPorts
#               of 6cell mRRUs
# Date        : January 2019
# Who         : xharidu
####################################################################
# Version5    : LTE 20.08
# Revision    : CXP 903 0491-361-1
# Jira        : NSS-30062
# Purpose     : Modify CBSD support for only DOTS and 4408
# Description : Skip this script for TDD DG2
# Date        : April 2020
# Who         : xharidu
####################################################################
####################################################################
# Version6    : LTE 20.16
# Revision    : CXP 903 0491-368-1
# Jira        : NSS-28950
# Purpose     : Modify CBSD support for DOT, 4408 and 6448
# Description : Bypass this script for the nodes assigned for CBSD
# Date        : September 2020
# Who         : xharidu
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
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

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

while ($NODECOUNT<=$DG2NUMOFRBS){
    ##########################
    # MIM version support
    ##########################
    local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
    local $post15BV11MIM=&isgreaterthanMIM($MIMVERSION,"15B-V13");

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);
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
  @MOCmds=();
 if ($post15BV11MIM=~m/yes/) {
    ###############################
    # start NodeSupport rfBranchRef
    ###############################
     $tempcellnum=1;
     while($tempcellnum<=$CELLNUM){
       @MOCmds=qq^ SET
       (
        mo "ManagedElement=$LTENAME,NodeSupport=1,SectorEquipmentFunction=$tempcellnum"
        exception none
        nrOfAttributes 2
        "rfBranchRef" Array Ref 2
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=1"
           "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=2"
       )
       ^;# end @MO
       $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
       $tempcellnum++;
     }# end while CELLNUM
     #############################
     # end NodeSupport rfBranchRef
     #############################
   } else { 
     ############################
     # start rfBranchRef
     ############################
     $tempcellnum=1;
     while($tempcellnum<=$CELLNUM){
     @MOCmds=qq^ SET
     (
      mo "ManagedElement=$LTENAME,SectorEquipmentFunction=$tempcellnum"
      exception none
      nrOfAttributes 2
      "rfBranchRef" Array Ref 2
         "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=1"
         "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=2"
     )
     ^;# end @MO
     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
     $tempcellnum++;
    }# end while CELLNUM
    ############################
    # end rfBranchRef
    ############################
  }# end if
  ############################
  # start auPortRef
  ############################
  $tempcellnum=1;
  while($tempcellnum<=$CELLNUM){
    @MOCmds=qq^ SET
   (
    mo "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=1"
    exception none
    nrOfAttributes 1^;#end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        $tempAntennaUnit=1;
        @MOCmds=qq^"auPortRef" Array Ref $maxAntennaUnit^;# end @MO
        while ($tempAntennaUnit <= $maxAntennaUnit) {
		@MOCmds=qq^      "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1,AuPort=1"^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;
        }
    @MOCmds=qq^)
	SET
   (
    mo "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,RfBranch=2"
    exception none
    nrOfAttributes 1^;#end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	    $tempAntennaUnit=1;
            @MOCmds=qq^"auPortRef" Array Ref $maxAntennaUnit^;# end @MO
            $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	    while ($tempAntennaUnit <= $maxAntennaUnit) {
		@MOCmds=qq^      "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1,AuPort=2"^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$tempAntennaUnit++;
            }

   @MOCmds=qq^) ^;# end @MO
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
  $tempAntennaUnit=1;
  $tempRetSubUnit=1;
  while($tempcellnum<=$CELLNUM){ # while CELLNUM
	while ($tempAntennaUnit <= $maxAntennaUnit) {
		@MOCmds=qq^ SET
		(
		mo "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaUnit=$tempAntennaUnit,AntennaSubunit=1"
		exception none
		nrOfAttributes 1
		retSubunitRef Ref "ManagedElement=$LTENAME,Equipment=1,AntennaUnitGroup=$tempcellnum,AntennaNearUnit=1,RetSubUnit=$tempRetSubUnit"
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

