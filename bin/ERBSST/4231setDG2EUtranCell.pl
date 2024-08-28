#!/usr/bin/perl 
### VERSION HISTORY
##################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-151-1
# User Story  : OSS-77951
# Purpose     : To set attributes of DG2 EUtranCell
# Description : sets attributes cellId for TDD &FDD, tac for TDD 
#               & FDD, bPlmnList for TDD & FDD, earfcn for TDD, 
#               earfcndl for FDD, earfcnul for FDD
# Date        : May 2015
# Who         : xsrilek
###################################################################
####################################################################
# Version2    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77930
# Purpose     : Generalising methods of getting nondename & nodenum
# Description : Modifying methods getDG2SimStringNodeName & 
#		getDG2SimIntegerNodeNum to getLTESimStringNodeName &
#		getLTESimIntegerNodeNum
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version3    : LTE 16A
# Revision    : CXP 903 0491-154-1
# Jira        : NETSUP-3055
# Purpose     : resolve error in TDD builds while setting attributes
# Description : Modifying methods getDG2SimStringNodeName & 
#		getDG2SimIntegerNodeNum to getLTESimStringNodeName &
#		getLTESimIntegerNodeNum
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version4    : LTE 16.7
# Revision    : CXP 903 0491-210-1
# Jira        : NSS-1867
# Purpose     : EUtranCellFDD administrativeState should be 
#               set to unlocked by default across all sims
# Description : Setting administrativeState to unlocked in
#               EUtranCellFDD MO
# Date        : May 2016
# Who         : xkatmri
###################################################################
####################################################################
# Version4    : LTE 16.10
# Revision    : CXP 903 0491-228-1
# Jira        : NSS-3544
# Purpose     : EUtranCellTDD administrativeState should be 
#               set to unlocked by default across all sims
# Description : Setting administrativeState to unlocked in
#               EUtranCellTDD MO
# Date        : June 2016
# Who         : xkatmri
###################################################################
####################################################################
# Version5    : ENM 17.14
# Revision    : CXP 903 0491-307-1
# Jira        : NSS-13661
# Purpose     : Attribute out of range exception for DG2 Nodes
# Description : Setting the mandatory attributes for BCG export 
#		& import to pass for DG2 Nodes. Setting attributes
#		prsMutingPattern, additionalPlmnList, freqBand	        
# Date        : Aug 2017
# Who         : xkatmri
####################################################################
####################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_Relations;
use LTE_General;
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
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

# for node cells/adjacent cells

local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
local ($cellid,$latitutde,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup);
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);

local ($NODESIM,$freqid,$EUTRANCELLFREQID,$CID,$TACID);

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

  # get the node eutran frequency id
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);

  # get node primary cells
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  ###############################################################################
  #
  # cellId (cId) can take range from 0 to 255 and must be unique within the ERBS
  #
  ###############################################################################
  
  $CID=1;$TACID=1;$CELLCOUNT=1;
  foreach $Cell (@primarycells) {
    $Frequency = getCellFrequency($Cell, $ref_to_Cell_to_Freq);
   
    if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="Lrat:EUtranCellFDD";
      $UL_Frequency = $Frequency + 18000;
    }# end if
    else{
      $TYPE="Lrat:EUtranCellTDD";
      if($Frequency<36005){$Frequency=$Frequency+36004;}
    }# end else
    
	print "Set ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT on Frequency $Frequency\n";
    

    ##################################################
    # Start of update due to NETSim TR TRSPS00013074 #
    ##################################################
    if ($TYPE eq "Lrat:EUtranCellTDD"){
    # build mo script
    @MOCmds=();
    @MOCmds=qq^SET
      (
      mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
          identity 1
          exception none
          nrOfAttributes 8
          cellId Int32 $CID
          tac Int32 $TACID
          activePlmnList Array Struct 1
         	nrOfElements 3
           	mcc Int32 353
            	mnc Int32 57
            	mncLength Int32 2
          earfcn Int32 $Frequency
          freqBand Int32 $Frequency
          subframeAssignment Int32 1
          prsMutingPattern String "1"
          administrativeState Integer 1
     );
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    }# end TDD if
    ################################################
    # End of update due to NETSim TR TRSPS00013074 #
    ################################################
    if ($TYPE eq "Lrat:EUtranCellFDD"){
    # build mo script
     @MOCmds=();
     @MOCmds=qq^SET
      (
      mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
        identity 1
        exception none
        nrOfAttributes 8
          cellId Int32 $CID
          tac Int32 $TACID
          activePlmnList Array Struct 1
          nrOfElements 3
            mcc Int32 353
            mnc Int32 57
            mncLength Int32 2
        earfcndl Int32 $Frequency
        earfcnul Int32 $UL_Frequency
        freqBand Int32 $Frequency
        prsMutingPattern String "1"
        administrativeState Integer 1
     );
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   } # end FDD if
   push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
   $CELLCOUNT++;$CID++;  
  }# end inner CELL foreach
  
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
# remove mo scripts
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
