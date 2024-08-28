#!/usr/bin/perl 
### VERSION HISTORY
####################################################################
# Version1    : Created for LTE O 10.0 TERE
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Version2    : Created for req id:2757
# Purpose     : Set "eutranFrequencyRef" 
# Date        : 04 Nov 2009
# Who         : Fatih ONUR
####################################################################
# Version3    : Created for req id:4313, 0-10.3.7
# Purpose     : Modifying and adding EUtranFreqRelations
# Description : Currently in the O10.3 ST simulations there are 33 
#		EUtranCellRelations under one EUtranFreqRelation under 
#               each EUtranCell.This will change so that some EUtranCells 
#               have more than one EUtranFreqRelation
#               10% of the cells will have 2 EUtranFrequencyRelations
#               10% of the cells will have 4 EUtranFrequencyRelations
#               10% of the cells will have 1 EUtranFrequencyRelations
# Date        : 26 May 2010
# Who         : Fatih ONUR
####################################################################
# Version4    : Created for reqId:4710 
# Purpose     :
# Description : FDD and TDD node division provided
# Date        : 09 JUL 2010
# Who         : Fatih ONUR
####################################################################
# Version5    : Created for reqId:5569
# Purpose     : TERE 11.1
# Date        : 27 OCT 2010
# Who         : Fatih ONUR
####################################################################
####################################################################
# Version6    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover 
# Description : enables flexible LTE EUtran cell LTE handover
# Date        : Feb 2012
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 13A
# Purpose     : LTE 13 Sprint 2 Frequencies
# Description : sorting out frequencies
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version9    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script on netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version10   : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version11   : LTE 13B
# Revision    : 4
# Purpose     : Sprint 0.5 - Cell Reselection Priority
# Description : reset freq band cellReselectionPriority attribute
#               in accordance with below assignment ruleset :
#               GSM = 1
#               CDMA2000 = 2
#               UMTS = 3
#               CDMA2001 x rtt = 4
#               LTE = 5
# Date        : Jan 2013
# Who         : epatdal
####################################################################
####################################################################
# Version12   : LTE 14A
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
# Version15   : LTE 16A
# Revision    : CXP 903 0491-149-1
# Purpose     : resolves an issue where in some simulations EutranFrequencyRELATION=1 is 
#               created
# Description : ensure FrequencyRElation 1 is created. 
# Date        : 18th May 2015
# Who         : ekamvat
####################################################################
####################################################################
# Version16   : LTE 16A
# Revision    : CXP 903 0491-151-1
# Purpose     : resolves an issue where in some simulations empty 
#               frequencies are created 
# Description : ensure FrequencyRElation 1 is created. 
# Date        : 28th May 2015
# Who         : xsrilek
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
local $whilecounter,$gen="..",$tempnodenum,$eutranfreqband,$element;
local $EUTRANCELLFREQRELATIONID=0;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
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
local @nodecells=();
local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $Frequency=0;
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

local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local ($START,$STOP,$RELCOUNT);
local @eutranfreqbands=&getNetworkEUtranFrequencyBands($NETWORKCELLSIZE,$EXTERNALENODEBFUNCTION,@PRIMARY_NODECELLS);

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

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get the node eutran frequency id
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);

# Determine the number of frequency to be used based on major minor network
  if($nodecountinteger>$ttlnetworknodes_minor){
     $NumOfFreqAllowed=4;
  }# end if
  else{$NumOfFreqAllowed=9;
	   }# end else
  # end number of frequency determination based on major minor network
 
  # get node flexible primary cells
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
 
  $cell_index=1;
  foreach $Cell (@primarycells) {
    local $fre_counter=0;
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
        	
     # check cell type
     # CXP 903 0491-135-1
     if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
       $TYPE="EUtranCellFDD";
     }# end if
     else{
       $TYPE="EUtranCellTDD";
       # CXP 903 0491-135-1
       if($Frequency<36005){$Frequency=$Frequency+36004;}
     }# end else

        # build mo script
        @MOCmds=();
        @MOCmds=qq^CREATE
        (
        parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index"
            identity $Frequency
            moType EUtranFreqRelation
            exception none
            nrOfAttributes 3
            "timeOfCreation" String "2017-11-29T09:32:56"
            cellReselectionPriority Integer 5
            eutranFrequencyRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=$Frequency    
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

