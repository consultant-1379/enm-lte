#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : Created for LTE ST Simulations 
# Purpose     : TEP Request : 5024
# Description : LTE PCI values in LTE ST Simulations 
# Date        : Dec 2010
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
# Version3    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover Internal
# Description : enable flexible LTE EUtran cell LTE handover
# Date        : Feb 2012
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover
# Description : support for EXTERNALENODEBFUNCTION major minor network breakdown
# Date        : April 2012
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 13A
# Purpose     : LTE 12.2 LTE Handover
# Description : revising cell relations as a whole
# Date        : August 2012
# Who         : lmieody
####################################################################
####################################################################
# Version6    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version7    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version8    : LTE 13B
# Revision    : CXP 903 0491-29
# Jira        : NETSUP-784
# Purpose     : Updating ExternalEUtranCellFDD.masterEUtranCellFDDId
#               and ExternalEUtranCellFDD.masterEUtranCellTDDId
#               with "$EXTERNALNODESTRING-$nodecellindex" as per 
#               stakeholder request
# Date        : Oct 2013
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version10   : LTE 14B.1
# Purpose     : copies EUtranCell PCI values to External EUtran network
# Description : LMI-14:001152 (SNAD CC RuleSet.xls) Issue 4
#               works in conjuction with ./archiveEUtranCelldata.pl
#               and depending on total LTE network cellsize reads from 
#		a .csv for ex: 
#               ~/LTESimScripts/customdata/networkarchive/LTE28000EUtranCellData.csv
# Date        : July 2014
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 14B.1
# Purpose     : Supports MIM E1180 
# Description : If statement changes plmn variable name if MIM E1180
#		is in use. 
# Date        : August 2014
# Who         : ecasjim
####################################################################
#####################################################################
# Version12   : LTE 14B.1
# Purpose     : remove comment
# Description : Discovered problems building 6KPCI, issues related
#               to functionality which was commented out on $retval
# Date        : Aug 2014
# Who         : ecasjim
####################################################################
####################################################################
# Version13   : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version14   : LTE 15B
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
# Version15   : LTE 17A
# Revision    : CXP 903 0491-245-1
# Jira        : NSS-5222
# Purpose     : Remove 2131,2132 scripts from enm-lte codebase
# Description : Merge the operations of scripts 2131,2132 into 1281,
#               1282 and remove 2131,2132 such that time for build
#               reduces for ERBS nodes
# Date        : July 2016
# Who         : xravlat
####################################################################
####################################################################
# Version16   : LTE 17A
# Revision    : CXP 903 0491-268-1
# Jira        : NSS-5225
# Purpose     : Reduce the time taken for Eutra Scripts for last sims.
# Description : To make build time uniform for all sims, logic of
#               generating data has been changed such that it will be
#               same for all nodes.
# Date        : Oct 2016
# Who         : xmitsin
####################################################################
####################################################################
# Version17    : LTE 18B
# Revision    : CXP 903 0491-319-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version18   : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               ExternalEUtranCellFDD MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_CellConfiguration;
use LTE_General;
use LTE_OSS12;
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
local $forcounter,$cellid;
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
local $TDDWORKAROUND=&getENVfilevalue($ENV,"TDDWORKAROUND");
local $nodenum,$nodenum2,$nodenum3,$nodecountfornodestringname,$nodecountfornodestringname2;
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local $tempadjacentcellsize,$adjacentcellsize;
local $eNBId,$ExternalENodeBFunctionId;
local $EXTERNALNODESIM,$EXTERNALNODESTRING,$tempcellnum;
# ensure TDD and FDD cells are not related
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
local $TEMPNODESIM="",$TDDMATCH=0;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);

#------------------------------------------------------------------------
# 60K optimisation
#------------------------------------------------------------------------
local $ref_to_Cell_to_Node = &buildCelltoNode(\@PRIMARY_NODECELLS);
my @Cell_to_Node = @{$ref_to_Cell_to_Node};
&store_Cells_to_Node(@Cell_to_Node);

local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);
#------------------------------------------------------------------------

# EUtran network configuration
local $GENERICNODECELLS=&getENVfilevalue($ENV,"GENERICNODECELLS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local $EXTERNALEUTRANCELLPROXIES_MAJOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MAJOR");
local $EXTERNALEUTRANCELLPROXIES_MINOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MINOR");
local @networkblocks=(),@networkblockswithlteproxies=(),@eutranextnodes=();
local @designatedlteproxies=(),@nodematchedlteproxies;
local $networkblockslastnodenum=0;
local $element4,$counter,$match;
local @nodeeutranextnodes=();
local $nmatch,$nelement1,$nelement2,$ncounter2,$ncounter3;
local @nallexternalnodecelldata,@nexternalnodecelldata;
local @sortednexternalnodecelldata;
local $nodecellindex;

# start size network by major minor breakdown
local $ttlnetworknodes=int($NETWORKCELLSIZE/$STATICCELLNUM);# ttl lte nodes in network
local $ltenetwork_major=$LTENETWORKBREAKDOWN,$ltenetwork_minor=$LTENETWORKBREAKDOWN;
$ltenetwork_major=~s/\:.*//;$ltenetwork_major=~s/^\s+//;$ltenetwork_major=~s/\s+$//;
$ltenetwork_minor=~s/^.*://;$ltenetwork_minor=~s/^\s+//;$ltenetwork_minor=~s/\s+$//;
local $ttlnetworknodes_major=int(($ttlnetworknodes/100)*$ltenetwork_major);
local $ttlnetworknodes_minor=int(($ttlnetworknodes/100)*$ltenetwork_minor);
local $RelationsPerFreqBand,$RELATIONID;
# end size network by major minor breakdown

# start size network by major minor EXTERNALENODEFUNCTION breakdown
local $extenodeb_major=$EXTERNALENODEBFUNCTION;
local $extenodeb_minor=$EXTERNALENODEBFUNCTION;
$extenodeb_major=~s/\:.*//;$extenodeb_major=~s/^\s+//;$extenodeb_major=~s/\s+$//;
$extenodeb_minor=~s/^.*://;$extenodeb_minor=~s/^\s+//;$extenodeb_minor=~s/\s+$//;
# end size network by major minor EXTERNALENODEFUNCTION breakdown

# LTE14B.1 EUtranCell data archive support
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/networkarchive\//;
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."EUtranCellData.csv";
local $command1="./archiveEUtranCelldata.pl";
local ($archivecellname,$archivephysicalLayerSubCellId,$archivephysicalLayerCellIdGroup);
local $TempExternalEUtranCell;
local @archivelist=();
#-----------------------------------------------------
#OPTIMISATION
#-----------------------------------------------------
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM");
local $NETWORK_BREAKDOWN=&getENVfilevalue($ENV,"NETWORK_BREAKDOWN");
local @NETWORK_BREAKDOWN=split(/\,/,$NETWORK_BREAKDOWN);
local $EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN");
local @EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN=split(/\,/,$EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN);
local $totalNodes=int ($NETWORKCELLSIZE/$CELLNUM);
local $majorNodes=int (($NETWORK_BREAKDOWN[0]/100)*$totalNodes);
local $externalEnb=($nodeNum<=$majorNodes) ? $EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN[0] : $EXTERNALENODEBFUNCTIONSPERNODE_BREAKDOWN[1];
$blockSize=$externalEnb+1;
#----------------------------------------------------

# E1180 Support
local $PlmnVar;
###############
# struct vars
###############
local $plmnList=6;
local $mcc=353;
local $mnc=57;
local $mncLength=2;
local $plmnCounter;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}

# check if EUtranCellData archive  file exits
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

# open EUTRANCELLDATAARCHIVE csv file for reading
local @EUTRANCELLDATAARCHIVE=();
open FH3, "$LTENetworkOutput" or die $!;
     @EUTRANCELLDATAARCHIVE=<FH3>;
close(FH3);
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################

while ($NODECOUNT<=$NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

# start size network by major minor EXTERNALENODEFUNCTION breakdown
  if($nodecountfornodestringname>$ttlnetworknodes_minor){
     $EXTERNALENODEBFUNCTION=$extenodeb_major;
  }# end if
  else{$EXTERNALENODEBFUNCTION=$extenodeb_minor;}# end else
  # end size network by major minor EXTERNALENODEFUNCTION breakdown

  @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  $CELLNUM=@primarycells;# flexible cellnum
  #######################################################
  # start get external enodebfuntion
  #######################################################
  # We'll come into this with @primarycells from above
  # and from that work out the cells that are related to its
  # cells (@exteutrancells)
  # then the nodes holding those cells (@nodeeutranextnodes).
  # We then create the ExternalENodeBFunction for each of those nodes
  # Coming in to this phase all we need is $nodecountinteger and
  # on the way out we need @nodeeutranextnodes
  # That should do it

  # Cells related to the cells in our node
  local @exteutrancells=();
  foreach $cell (@primarycells) {
    local $ref_to_exteutrancells=\@exteutrancells;
    local @related_Cells = &getInterEUtranCellRelations($cell, $ref_to_CellRelations);
    @exteutrancells=&union($ref_to_exteutrancells, \@related_Cells);
  }

  # Nodes where those cells reside
  %nodes = ();
  foreach $cell (@exteutrancells) {
  	
    $nodenum = &getCelltoNode_Upgrade($cell);
    $EXTERNALNODESIM=&getLTESimNum($nodenum,$NUMOFRBS);
    
    ##################
    # check cell type
    ##################
    # CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$EXTERNALNODESIM)))) {
        $TYPE="ExternalEUtranCellFDD";
        $TYPEID="ExternalEUtranCellFDDId";
    }# end if
    else{
        $TYPE="ExternalEUtranCellTDD";
	$TYPEID="ExternalEUtranCellTDDId";
    }# end else

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodenum>$NUMOFRBS){
         $nodecountfornodestringname2=($nodenum-($EXTERNALNODESIM-1)*$NUMOFRBS);
    }
    else{$nodecountfornodestringname2=$nodenum;}# end workaround 
  
    $EXTERNALNODESTRING=&getLTESimStringNodeName($EXTERNALNODESIM,$nodecountfornodestringname2);

# workaround to leave node ending with "0000"
    @EXT1 = split /ERBS/, $EXTERNALNODESTRING;
    if ("$EXT1[1]" == "0000") {next;}

    $nodecellindex=&getNodeFlexibleCellIndex($cell,$NETWORKCELLSIZE,$nodecountinteger,$blockSize,@PRIMARY_NODECELLS);
    
    print "Create $cell ExternalEUtranCells for $EXTERNALNODESTRING-$nodecellindex\n";

   ##############################################################################################################
   # LTE14B.1 - start : get EUtran Cell PCI data $archivephysicalLayerSubCellId,$archivephysicalLayerCellIdGroup 
   ##############################################################################################################

  $TempExternalEUtranCell="$EXTERNALNODESTRING-$nodecellindex";
  $TempExternalEUtranCell==~ s/^\s+|\s+$//g ;
  @archivelist=();

  if ( @archivelist = grep( /$TempExternalEUtranCell/,@EUTRANCELLDATAARCHIVE) ) {
      ($archivecellname,$archivephysicalLayerSubCellId,$archivephysicalLayerCellIdGroup)=split(/;/,$archivelist[0]);
  }# end if

  if ($archivephysicalLayerSubCellId eq "") {next;}

  ##############################################################################################################
  # E1180 support, attribute change from bPlmnList to activePlmnList
  ##############################################################################################################

  # Check support for updated GSM configuration
  local $MIMVERSION=&queryMIM($SIMNAME);
  local $MIMsupportforupdatedGSMconfiguration="E1180";

  # Check support for updated GSM configuration
  $mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMsupportforupdatedGSMconfiguration);

  if($mimcomparisonstatus eq "yes")
  {
   	$PlmnVar = "activePlmnList";
  }
  else
  {
   	$PlmnVar = "bPlmnList";
  }
  ##############################################################################################################
  # End E1180 support
  ##############################################################################################################

  ##############################################################################################################
  # LTE14B.1 - end : get EUtran Cell PCI data $archivephysicalLayerSubCellId,$archivephysicalLayerCellIdGroup 
  ##############################################################################################################

    if($TYPE eq "ExternalEUtranCellFDD"){
    # build mo script
    @MOCmds=();
    @MOCmds=qq^ CREATE
      (
     parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING"
        identity $EXTERNALNODESTRING-$nodecellindex
        moType $TYPE
        exception none
        nrOfAttributes 6
        "timeOfCreation" String "2017-11-29T09:32:56"
        $TYPEID String $EXTERNALNODESTRING-$nodecellindex
        physicalLayerCellIdGroup Integer $archivephysicalLayerCellIdGroup
        physicalLayerSubCellId Integer $archivephysicalLayerSubCellId
        masterEUtranCellFDDId String $EXTERNALNODESTRING-$nodecellindex
        localCellId Integer $nodecellindex
        dlChannelBandwidth Integer 10000
        tac Integer 1
        ulChannelBandwidth Integer 10000
	$PlmnVar Array Struct $plmnList
    ^;# end @MO
    }# end if TYPE FDD
    else{
    @MOCmds=();
    @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING"
        identity $EXTERNALNODESTRING-$nodecellindex
        moType $TYPE
        exception none
        nrOfAttributes 6
        "timeOfCreation" String "2017-11-29T09:32:56"
        $TYPEID String $EXTERNALNODESTRING-$nodecellindex
        physicalLayerCellIdGroup Integer $archivephysicalLayerCellIdGroup
        physicalLayerSubCellId Integer $archivephysicalLayerSubCellId
        masterEUtranCellTDDId String $EXTERNALNODESTRING-$nodecellindex
        localCellId Integer $nodecellindex
        channelBandwidth Integer 10000
        tac Integer 1
	$PlmnVar Array Struct $plmnList
    ^;# end @MO
    }# end else TYPE TDD
    ###########################################
    # 1. start build PlmnVar struct array
    ###########################################
    $plmnCounter=1;
    while($plmnCounter<=$plmnList){
     # build mo script
     push(@MOCmds,(qq^        nrOfElements 4
             mcc Integer $mcc
             mnc Integer $mnc
             mncLength Integer $mncLength
             mmeGI Integer 0
    ^));# end @MOCmds
    $plmnCounter++;
    }# end
    push(@MOCmds,(qq^
      );
    ^));# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  }

   # get the union of two arrays. pass two array refs to this
   sub union {
   %union=();
   @a=@{$_[0]};
   @b=@{$_[1]};
   foreach (@a) { $union{$_} = 1 }
   foreach (@b) { $union{$_} = 1 }
   @union = keys %union;
   return(@union)
   }
  #####################################
  # end create ExternalEUtranCell
  #####################################

  push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

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
 # @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

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

