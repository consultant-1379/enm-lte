#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : Inter Frequency Relations support for DG2 for LTE 16A
# Description : Creates EUtranFrequencies under EUtranNetwork
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 18B
# Revision    : CXP 903 0491-316-1
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
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
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
local $nodecountinteger,$nodecountfornodestringname,@primarycells=();
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
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);
#------------------------------------------------------------------------

# EUtran network configuration
local $GENERICNODECELLS=&getENVfilevalue($ENV,"GENERICNODECELLS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local $EXTERNALEUTRANCELLPROXIES_MAJOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MAJOR");
local $EXTERNALEUTRANCELLPROXIES_MINOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MINOR");

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

while ($NODECOUNT<=$DG2NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  # get nodenum 
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$DG2NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
  
  # Determine the number of frequency to be used based on major minor network
  if($nodecountfornodestringname>$ttlnetworknodes_minor){
     $NumOfFreqAllowed=4;
  }# end if
  else{$NumOfFreqAllowed=9;
	   }# end else
  # end number of frequency determination based on major minor netwrok

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
  
  $counter=$counter+1;
    
  print "EUtranFrequency=$Frequency\n";
    # build mo script
    @MOCmds=qq( CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:EUtraNetwork=1"
       identity $Frequency
       moType Lrat:EUtranFrequency
       exception none
       nrOfAttributes 2
       eUtranFrequencyId String $Frequency
       arfcnValueEUtranDl Int32 $Frequency
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

#  # execute mml script
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
