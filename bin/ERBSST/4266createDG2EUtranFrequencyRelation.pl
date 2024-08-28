#!/usr/bin/perl 
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : Modifying and adding EUtranFreqRelations
# Description : Creates EUtranCellRelations under EUtranFreqRelation under each EUtranCell.
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 16A
# Revision    : CXP 903 0491-155-1
# Jira        : NETSUP-3047
# Purpose     : Adding the Missing Frequency "1"
# Description : Work Around to add the missing Frequency "1" for the issue identified during the 
#				NETSUP-3047 implementation
# Date        : June 2015
# Who         : xkamvat
####################################################################
####################################################################
# Version3    : ENM 17.14
# Revision    : CXP 903 0491-307-1
# Jira        : NSS-13661
# Purpose     : Attribute out of range exception for DG2 Nodes
# Description : Setting the mandatory attributes for BCG export 
#               & import to pass for DG2 Nodes. Setting attributes
#               prsMutingPattern, additionalPlmnList, freqBand          
# Date        : Aug 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 18B
# Revision    : CXP 903 0491-316-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               EUtranFreqRelation MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
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
local $whilecounter,$gen="..",$tempnodenum,$eutranfreqband,$element;
local $EUTRANCELLFREQRELATIONID=0;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");

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
local $nodecountinteger,@primarycells=();
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local @eutranfreqbands=&getNetworkEUtranFrequencyBands($NETWORKCELLSIZE,$EXTERNALENODEBFUNCTION,@PRIMARY_NODECELLS);

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
if(@eutranfreqbands<1){
   print "FATAL ERROR : @eutranfreqbands < 1\n";
   exit;
}# end if
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
  # end number of frequency determination based on major minor network
 
  # get node flexible primary cells
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  $cell_index=1;
  foreach $Cell (@primarycells) {

    @InterEUtranCellRelations = &getInterEUtranCellRelations($Cell, $ref_to_CellRelations);
    @cells_in_our_node = @{$PRIMARY_NODECELLS[$nodecountinteger]}; 
    @related_cells = (@InterEUtranCellRelations, @cells_in_our_node);
    # Frequencies covered by those cells
  local @Frequencies = &getCellsFrequencies($ref_to_Cell_to_Freq, @related_cells);
  @Frequencies_tmp = @Frequencies;
  # Removing blank elements in @Frequencies array.
  @Frequencies = grep($_,@Frequencies_tmp);
	
  # Counter to check if $NumOfFreqAllowed is satisfied
    local $counter=0;
	
    foreach $Frequency (@Frequencies) {

    $counter=$counter+1;

     # check cell type
     if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
       $TYPE="EUtranCellFDD";
     }# end if
     else{
       $TYPE="EUtranCellTDD";
     
       if($Frequency<36005){$Frequency=$Frequency+36004;}
     }# end else

        # build mo script
        @MOCmds=();
        @MOCmds=qq^CREATE
        (
        parent "ManagedElement=$LTENAME,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index"
            identity $Frequency
            moType Lrat:EUtranFreqRelation
            exception none
            nrOfAttributes 6
            "timeOfCreation" String "2017-11-29T09:32:56"
            cellReselectionPriority Int32 5
            userLabel String "$LTENAME-$cell_index"
            eutranFreqToQciProfileRelation Array Struct 0
            candNeighborRel Array Struct 0
            eutranFrequencyRef Ref ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=$Frequency    
        );
        ^;# end @MO
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

    if($counter eq $NumOfFreqAllowed) {last;}
    }
    $cell_index++;
  }
  
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
#unlink "$NETSIMMMLSCRIPT";
#unlink @NETSIMMOSCRIPTS;
print "... ${0} ended running at $date\n";
################################
# END
################################
