#!/usr/bin/perl 
### VERSION HISTORY
##################################################################
# Version1    : Created new script for E1180 attribute name changes
# Purpose     : Runs for attributes specific to E1180
# Date        : 6 August 2014
# Who         : ecasjim
###################################################################
###################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
###################################################################
####################################################################
# Version3    : LTE 15B
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
# Version4    : LTE 16.7
# Revision    : CXP 903 0491-210-1
# Jira        : NSS-1867
# Purpose     : EUtranCellFDD administrativeState should be 
#               set to unlocked by default across all sims
# Description : Setting administrativeState to unlocked in
#               EUtranCellFDD MO
# Date        : May 2016
# Who         : xkatmri
####################################################################
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
####################################################################
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
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
local ($cellid,$latitutde,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup);
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $EARFCNVALUE=0;
local $MAXEARFCNVALUE=8;
local $EARFCNDL;
local ($NODESIM,$freqid,$EUTRANCELLFREQID,$CID,$TACID);

# Check support for updated GSM configuration
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMsupportforupdatedGSMconfiguration="E1180";

# Check support for updated GSM configuration
$mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMsupportforupdatedGSMconfiguration);
if(!$mimcomparisonstatus eq "yes"){
  print "GSM configuration not supported for MIM $MIMVERSION in script ${0}\n";
  exit;
}# end if

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

  # get the node eutran frequency id
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);

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
    # check cell type
    # SJ NETSUP-2748 - CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="EUtranCellFDD";
      $UL_Frequency = $Frequency + 18000;
    }# end if
    else{
      $TYPE="EUtranCellTDD";
      # SJ NETSUP-2748 - CXP 903 0491-135-1
      if($Frequency<36005){$Frequency=$Frequency+36004;}
    }# end else
    print "Set ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT on Frequency $Frequency\n";
    

    ##################################################
    # Start of update due to NETSim TR TRSPS00013074 #
    ##################################################
    if ($TYPE eq "EUtranCellTDD"){
    # build mo script
    @MOCmds=();
    @MOCmds=qq^SET
      (
      mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
          identity 1
          exception none
          nrOfAttributes 6
          cellId Integer $CID
          tac Integer $TACID
          activePlmnList Array Struct 1
         	nrOfElements 3
           	mcc Integer 353
            	mnc Integer 57
            	mncLength Integer 2
          earfcn Integer $Frequency
          subframeAssignment Integer 1
          administrativeState Integer 1
     );
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    }# end TDD if
    ################################################
    # End of update due to NETSim TR TRSPS00013074 #
    ################################################
    if ($TYPE eq "EUtranCellFDD"){
    # build mo script
     @MOCmds=();
     @MOCmds=qq^SET
      (
      mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
        identity 1
        exception none
        nrOfAttributes 7
          cellId Integer $CID
          tac Integer $TACID
        activePlmnList Array Struct 1
          nrOfElements 3
            mcc Integer 353
            mnc Integer 57
            mncLength Integer 2
        earfcndl Integer $Frequency
        earfcnul Integer $UL_Frequency
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
