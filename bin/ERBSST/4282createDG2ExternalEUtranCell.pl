#!/usr/bin/perl
### VERSION HISTORY
####################################################################
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : DG2 to LTE handover for LTE 16A
# Description : Creates DG2 External Eutran Cells
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2   : LTE 17A
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
# Version3    : LTE 18B
# Revision    : CXP 903 0491-316-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               ExternalEUtranCellFDD MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################################################################
####################################################################
# Version5    : LTE 19.15
# Revision    : CXP 903 0491-366-1
# Jira        : NSS-32242
# Purpose     : LTE 35K Design impact for ExternalEUtranCellFDD/TDD
# Description : Design change to meet specific counts mentioned in  
#               above JIRA.
# Date        : Sep 2020
# Who         : xmitsin

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
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
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
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

local $nodenum,$nodenum2,$nodenum3,$nodecountfornodestringname,$nodecountfornodestringname2;
# for node cells/adjacent cells
local @nodecells=();
local $nodecountInt32,@primarycells=(),@adjacentcells=();
local $tempadjacentcellsize,$adjacentcellsize;
local $eNBId,$ExternalENodeBFunctionId;
local $EXTERNALNODESIM,$EXTERNALNODESTRING,$tempcellnum;
# ensure TDD and FDD cells are not related
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
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

while ($NODECOUNT<=$DG2NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  # get node primary and adjacent cells
  $nodecountInt32=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountInt32>$DG2NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountInt32;}# end workaround

  # start size network by major minor EXTERNALENODEFUNCTION breakdown
  if($nodecountfornodestringname>$ttlnetworknodes_minor){
     $EXTERNALENODEBFUNCTION=$extenodeb_major;
  }# end if
  else{$EXTERNALENODEBFUNCTION=$extenodeb_minor;}# end else
  # end size network by major minor EXTERNALENODEFUNCTION breakdown

  @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  
  #######################################################
  # start get external enodebfuntion
  #######################################################
  # We'll come into this with @primarycells from above
  # and from that work out the cells that are related to its
  # cells (@exteutrancells)
  # then the nodes holding those cells (@nodeeutranextnodes).
  # We then create the ExternalENodeBFunction for each of those nodes
  # Coming in to this phase all we need is $nodecountInt32 and
  # on the way out we need @nodeeutranextnodes
  # That should do it

  # Cells related to the cells in our node
  local @exteutrancells = ();
  
  foreach $cell (@primarycells) {
  
    local $ref_to_exteutrancells=\@exteutrancells;
    local @related_Cells = &getInterEUtranCellRelations($cell, $ref_to_CellRelations);
    @exteutrancells=&union($ref_to_exteutrancells, \@related_Cells);
  }

  # Nodes where those cells reside
  %nodes = ();
  
  $exteutrancellsCount=1;  
  foreach $cell (@exteutrancells) {
 	if ($exteutrancellsCount == 233) {next;} ############ NRM6.2 , Major=233 & Minor=813
	$nodenum = &getCelltoNode_Upgrade($cell);
        $EXTERNALNODESIM=&getLTESimNum($nodenum,$DG2NUMOFRBS);
	
    
    ##################
    # check cell type
    ##################
    # CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$EXTERNALNODESIM)))) {
        $TYPE="Lrat:ExternalEUtranCellFDD";
        $TYPEID="externalEUtranCellFDDId";
    }# end if
    else{
            $TYPE="Lrat:ExternalEUtranCellTDD";
	    $TYPEID="externalEUtranCellTDDId";
    }# end else

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodenum>$DG2NUMOFRBS){
         $nodecountfornodestringname2=($nodenum-($EXTERNALNODESIM-1)*$DG2NUMOFRBS);
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
  # LTE14B.1 - end : get EUtran Cell PCI data $archivephysicalLayerSubCellId,$archivephysicalLayerCellIdGroup 
  ##############################################################################################################

    if($TYPE =~ "ExternalEUtranCellFDD"){ 
	
    # build mo script
    @MOCmds=qq( CREATE
      (
     parent "ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING"
        identity $EXTERNALNODESTRING-$nodecellindex
        moType $TYPE
        exception none
        nrOfAttributes 6
        $TYPEID String $EXTERNALNODESTRING-$nodecellindex
        "timeOfCreation" String "2017-11-29T09:32:56"
        activePlmnList Array Struct 1
        nrOfElements 3
         mcc Int32 353
         mnc Int32 57
         mncLength Int32 2
        physicalLayerCellIdGroup Int32 $archivephysicalLayerCellIdGroup
        physicalLayerSubCellId Int32 $archivephysicalLayerSubCellId
        masterEUtranCellFDDId String $EXTERNALNODESTRING-$nodecellindex
        localCellId Int32 $nodecellindex
        dlChannelBandwidth Int32 10000
        tac Int32 1 
        ulChannelBandwidth Int32 10000
     );
    );# end @MO
    }# end if TYPE FDD
    else{
    @MOCmds=qq( CREATE
      (
      parent "ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING"
        identity $EXTERNALNODESTRING-$nodecellindex
        moType $TYPE
        exception none
        nrOfAttributes 6
        "timeOfCreation" String "2017-11-29T09:32:56"
        $TYPEID String $EXTERNALNODESTRING-$nodecellindex
        activePlmnList Array Struct 1
        nrOfElements 3
         mcc Int32 353
         mnc Int32 57
         mncLength Int32 2
        physicalLayerCellIdGroup Int32 $archivephysicalLayerCellIdGroup
        physicalLayerSubCellId Int32 $archivephysicalLayerSubCellId
        masterEUtranCellTDDId String $EXTERNALNODESTRING-$nodecellindex
        localCellId Int32 $nodecellindex
        channelBandwidth Int32 10000
        tac Int32 1
     );
    );# end @MO
    }# end else TYPE TDD
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	
   $exteutrancellsCount++; ##nrm6_2
#   if ($exteutrancellsCount == 812) {next;}	
  } #end foreach

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

