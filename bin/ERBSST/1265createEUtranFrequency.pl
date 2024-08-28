#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : Created to replace a shell script 
# Purpose     : Inter Frequency Relations support in 13A 
# Description : Creates EUtranFrequencies under EUtranNetwork 
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version2    : 
# Purpose     : Speeing up sim creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version3    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version4    : LTE 14A
# Revision    : CXP 903 0491-42-19
# Jira        : NETSUP-1019
# Purpose     : check sim type which is either of type PICO or LTE 
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next 
#               script                             
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 16A
# Revision    : CXP 903 0491-151-1
# Purpose     : resolves an issue where in some simulations empty 
#               frequencies are created 
# Description : ensure FrequencyRElation 1 is created. 
# Date        : 28th May 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version7    : LTE 18B
# Revision    : CXP 903 0491-319-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
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
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodenum,$nodenum2;
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");;

# start size network by major minor breakdown
local $ttlnetworknodes=int($NETWORKCELLSIZE/$STATICCELLNUM);# ttl lte nodes in network
local $ltenetwork_major=$LTENETWORKBREAKDOWN,$ltenetwork_minor=$LTENETWORKBREAKDOWN;
$ltenetwork_major=~s/\:.*//;$ltenetwork_major=~s/^\s+//;$ltenetwork_major=~s/\s+$//;
$ltenetwork_minor=~s/^.*://;$ltenetwork_minor=~s/^\s+//;$ltenetwork_minor=~s/\s+$//;
local $ttlnetworknodes_major=int(($ttlnetworknodes/100)*$ltenetwork_major);
local $ttlnetworknodes_minor=int(($ttlnetworknodes/100)*$ltenetwork_minor);
local $NumOfFreqAllowed;
# end size network by major minor breakdown

# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local $nodecountfornodestringname,$nodecountfornodestringname2;
local $numofexternalenodebfuncs,$adjacentcellsize;
local $eNBId,$ExternalENodeBFunctionId;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);

#------------------------------------------------------------------------
# 60K optimisation
#------------------------------------------------------------------------
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
local $networkblockslastnodenum=0;
local $element4,$counter,$match;
local @nodeeutranextnodes=();
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
  
  # get nodenum 
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

# Determine the number of frequency to be used based on major minor network
  if($nodecountfornodestringname>$ttlnetworknodes_minor){
     $NumOfFreqAllowed=4;
  }# end if
  else{$NumOfFreqAllowed=9;
	   }# end else
  # end number of frequency determination based on major minor network

  #######################################################
  # start get EUtranFrequencies
  #######################################################
  # Want to start with the number of the node ($nodecountfornodestringname)
  # and from that work out the cells that are related to its 
  # cells (@exteutrancells)
  # then the frequencies of those cells
  
  # Cells related to the cells in our node
  local @exteutrancells = &getNodeExternalEUtranCells($nodecountfornodestringname, $ref_to_CellRelations, \@PRIMARY_NODECELLS);

  # Initially Frequencies were being set up for ExternalEUtranCells but we also need to consider cells in our own node 
  # in order to support Intra relations. Right now all cells in the same node are on the same Frequency but let's
  # assume that this may not always be the case. We will however assume that we will always have relations to all
  # cells in our node.
  local @cells_in_our_node = @{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  
  local @related_cells = (@exteutrancells, @cells_in_our_node); 
  
  # Frequencies covered by those cells
  local @Frequencies = &getCellsFrequencies($ref_to_Cell_to_Freq, @related_cells);
  @Frequencies_tmp = @Frequencies;
  # Removing blank elements in @Frequencies array.
  @Frequencies = grep($_,@Frequencies_tmp);

  # Counter to check if $NumOfFreqAllowed is satisfied 
  local $counter=0;
  
  #######################################################
  # end get EUtranFrequencies 
  #######################################################
  #####################################
  # start create EUtranFrequencies
  #####################################
  print "Create EUtranFrequencies for $LTENAME\n";
    
  foreach $Frequency (@Frequencies) {
# workaround to remove empty frequencies  
# CXP 903 0491-151-1
    $counter=$counter+1;
    if($Frequency =="") {
    $counter=$counter-1;
    next;}	
    print "EUtranFrequency=$Frequency\n";
    # build mo script
    @MOCmds=qq( CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"
       identity $Frequency
       moType EUtranFrequency
       exception none
       nrOfAttributes 2
       EUtranFrequencyId String $Frequency
       arfcnValueEUtranDl Integer $Frequency
     );
    );# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

    if($counter eq $NumOfFreqAllowed) {last;}

  } # end foreach
  #####################################
  # end create external enobdeb funcs
  #####################################
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
#unlink "$NETSIMMMLSCRIPT";
#unlink @NETSIMMOSCRIPTS;
print "... ${0} ended running at $date\n";
################################
# END
################################

