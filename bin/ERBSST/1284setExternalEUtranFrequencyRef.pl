#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover 
# Description : enable flexible LTE EUtran cell LTE handover
# Date        : Feb 2012
# Who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover
# Description : cater for EXTERNALENODEBFUNCTION major minor network breakdown 
# Date        : April 2012
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover
# Description : support for EXTERNALENODEBFUNCTION major minor network breakdown
# Date        : April 2012
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 13A
# Purpose     : LTE 13 Sprint 2 Frequencies
# Description : sorting out frequencies
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
# Version6    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version7    : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 15B
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
# Version10   : LTE 17A
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
# Version11   : LTE 18B
# Revision    : CXP 903 0491-319-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################
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
local $forcounter,$cellid,$cellid2;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;$TYPE2;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT,$FREQCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecellsize;
# for node cells/adjacent cells
local @nodecells=(),$nodecountinteger2;
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local @primarycellsarchive;
local $tempadjacentcellsize,$adjacentcellsize;
local $nodecountfornodestringname;
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
local $tempnodenum,$EUTRANCELLFREQRELATIONID,$eutranfreqband,$element;
local $tcount1,$tcount2,$telement,$tempextnodenum,$tempextnodecell;
# EUtran network configuration
local $GENERICNODECELLS=&getENVfilevalue($ENV,"GENERICNODECELLS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local $EXTERNALEUTRANCELLPROXIES_MAJOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MAJOR");
local $EXTERNALEUTRANCELLPROXIES_MINOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MINOR");
local $INTEREUTRANCELLRELATIONS_MAJOR=&getENVfilevalue($ENV,"INTEREUTRANCELLRELATIONS_MAJOR");
local $INTEREUTRANCELLRELATIONS_MINOR=&getENVfilevalue($ENV,"INTEREUTRANCELLRELATIONS_MINOR");
local $tempintereutrancellrelations;
local @networkblocks=(),@networkblockswithlteproxies=(),@eutranextnodes=();
local @designatedlteproxies=(),@nodematchedlteproxies;
local $networkblockslastnodenum=0;
local $element4,$counter,$match,$tempcounter,$tempcounter2,$tcounter;
local @nodeeutranextnodes=();
local $nmatch,$nelement1,$nelement2,$ncounter2,$ncounter3;
local @nallexternalnodecelldata,@nexternalnodecelldata;
local @sortednexternalnodecelldata;
local $nodecellindex,$ttlsizenallexternalnodecelldat;
local @eutranfreqbands=();

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
# Make MO & MML Scripts
################################
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  $NODESTRING=$LTENAME;
  
  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround


  #######################################################
  # start 
  #######################################################
  # Want to start with the number of the node ($nodecountfornodestringname)
  # and from that work out the cells that are related to its
  # cells (@exteutrancells)
  #

  # Cells related to the cells in our node
  local @exteutrancells = &getNodeExternalEUtranCells($nodecountfornodestringname, $ref_to_CellRelations, \@PRIMARY_NODECELLS);

  foreach $cell (@exteutrancells) {
  	
    $nodenum = &getCelltoNode_Upgrade($cell);
    $Frequency = $Cell_to_Freq[$cell];
    $EXTERNALNODESIM=&getLTESimNum($nodenum,$NUMOFRBS);
  	
    ##################
    # check cell type
    ##################
    # CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$EXTERNALNODESIM)))) {
        $TYPE="ExternalEUtranCellFDD";
    }# end if
    else{
        $TYPE="ExternalEUtranCellTDD";
        # CXP 903 0491-135-1
		if($Frequency<36005){$Frequency=$Frequency+36004;}
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

    #========================================
    # start set EUtranFreqBand
    #========================================
    @MOCmds=();
    @MOCmds=qq( SET
      (
       mo "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING,$TYPE=$EXTERNALNODESTRING-$nodecellindex"
       exception none
       nrOfAttributes 1
       eutranFrequencyRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=$Frequency
      );
     );# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    #========================================
    # end set EUtranFreqBand
    #========================================
} # end foreach


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

 ########################################
 # end set ExternalEUtranCell Relations
 ########################################

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
