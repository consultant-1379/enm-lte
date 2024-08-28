#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : Created for LTE O 10.0 TERE
# Purpose     :
# Description :
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Version2    : Created for req id:2757
# Purpose     : To correct cellId of ExternalEUtranCellFDD 
# Description :
# Date        : 07 Nov 2009
# Who         : Fatih ONUR
####################################################################
# Version3    : Created for req id:4313, 0-10.3.7
# Purpose     : Modifying and adding EUtranFreqRelations
# Description : Currently in the O10.3 ST simulations there are 33 
#		EUtranCellRelations under one EUtranFreqRelation under 
#		each EUtranCell. This will change so that some EUtranCells 
#		have more than one EUtranFreqRelation 10% of the cells 
#               will have 2 EUtranFrequencyRelations 10% of the cells 
#               will have 4 EUtranFrequencyRelations 10% of the cells 
#               will have 1 EUtranFrequencyRelations
# Date        : 26 May 2010
# Who         : Fatih ONUR
####################################################################
# Version4    : Created for reqId:4710 
# Description : FDD and TDD node division provided
# Date        : 09 JUL 2010
# Who         : Fatih ONUR
####################################################################
# Version5    : Created for reqId:4951
# Purpose     : fixing error
# Description : error in FDD and TDD node division fixed
# Date        : 21 JUL 2010
# Who         : Fatih ONUR
####################################################################
# Version6    : Created for reqId:5569
# Purpose     : TERE 11.1
# Date        : 27 OCT 2010
# Who         : Fatih ONUR
####################################################################
####################################################################
# Version7    : Created for LTE ST Simulations 
# Purpose     : TEP Request : 5024
# Description : LTE PCI values in LTE ST Simulations 
# Date        : Dec 2010
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover Internal
# Description : enable flexible LTE EUtran cell LTE handover
# Date        : Feb 2012
# Who         : epatdal
####################################################################
####################################################################
# Version10   : LTE 13A
# Purpose     : LTE 13A LTE Handover
# Description : revising cell relations as a whole
# Date        : August 2012
# Who         : lmieody
####################################################################
####################################################################
# Version11   : LTE 13A
# Purpose     : LTE 13 Sprint 2 Frequencies
# Description : sorting out frequencies
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version12   : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version13   : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version14   : LTE 13A
# Purpose     : Snag : deprecate support for imLoadBalancingActive
# Description : deprecate support for attribte imLoadBalancingActive
#               in node MIMs < C174 
# Date        : Oct 2012
# Who         : epatdal
####################################################################
####################################################################
# Version15   : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version16   : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version17   : LTE 15B
# Revision    : CXP 903 0491-124-1
# Jira        : OSS-67768
# Purpose     : deprecate support for imLoadBalancingActive
# Description : deprecate support for attribute imLoadBalancingActive
#		in node MIMs > F180   
# Date        : Feb 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version18   : LTE 15B
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
# Version19   : LTE 16A
# Revision    : CXP 903 0491-158-1
# Jira        : NETSUP-3078
# Purpose     : Resolve build error for standalone simulations 
# Description : Exits script if no internal relations are required
#	        to be created
# Date        : June 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version20   : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version21   : LTE 18B
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
local $forcounter,$cellid,$cellid2;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$ORIGTYPE;$DESTTYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# for node cells/adjacent cells
local @nodecells=(),$nodecountinteger2;
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local @primarycellsarchive;
local $tempadjacentcellsize,$adjacentcellsize;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;

#------------------------------------------------------------------------
# 60K optimisation
#------------------------------------------------------------------------
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);
#------------------------------------------------------------------------

local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMimLoadBalancingActive="C174";# indicates support for attribute imLoadBalancingActive
# CXP 903 0491-124-1, 19/02/2015 
local $MIMimLoadBalancingDeactive="F180";# indicates no support for attribute imLoadBalancingActive
local $imLoadBalancingEnable=&isgreaterthanMIM($MIMVERSION,$MIMimLoadBalancingActive);# either yes or no
local $imLoadBalancingDisable=&isgreaterthanMIM($MIMimLoadBalancingDeactive,$MIMVERSION);# either yes or no
local $mimcomparisonstatus=&checkMIMVersionRange($imLoadBalancingEnable,$imLoadBalancingDisable);# either yes or no
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/EUtranCellRelation1286.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
# CXP 903 0491-158-1
if (!(grep {$_ > 1} @CELLPATTERN)) {	
    print "Exiting ${0} NO INTERNAL RELATIONS CREATED for $SIMNAME \n";
    print "Cellpattern defined in CONFIG.env $CELLPATTERN \n";
    print "Exiting  ${0} stopped running at $date \n"; 
    exit;
}
################################
# Make MO & MML Scripts
################################
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  

  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  local $EUTRANCELLFREQID,$NODESIM,$NODESTRING,$NODEINDEX;
  local $NODESIM2,$NODESTRING2,$NODEINDEX2;
  local $RELATIONID;
  local $nodecountfornodestringname,$nodecountfornodestringname2;
  local $freqid;
  #####################################
  # start Internal Cell Relations
  #####################################
  $originating_cellindex=1;
  foreach $originating_cell(@primarycells){

    # check cell type
    # CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $originating_cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
        $ORIGTYPE="EUtranCellFDD";
    }# end if
    else{
        $ORIGTYPE="EUtranCellTDD";
    }# end else  

    $RELATIONID=1;
    
    # build the LTE node cell name

    $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodecountinteger>$NUMOFRBS){
       $nodecountfornodestringname=$nodecountinteger-($LTE-1)*$NUMOFRBS;
    }# end if
    else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

    $NODESTRING=&getLTESimStringNodeName($NODESIM,$nodecountfornodestringname);

    print "############################################\n";
    print "# INTERNAL RELATIONS of $ORIGTYPE=$NODESTRING-$originating_cellindex\n";
    print "############################################\n";

    $destination_cellindex=1;
    foreach $destination_cell (@primarycells){# inner2 foreach
    
       $Frequency = $Cell_to_Freq[$destination_cell];

       # check cell type
       # CXP 903 0491-135-1
       if((&isCellFDD($ref_to_Cell_to_Freq, $destination_cell)) &&(!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
           print "... towards $LTENAME-$destination_cellindex EUtranCellFDD\n";
           $DESTTYPE="EUtranCellFDD";
       }# end if
       else{
           print "... towards $LTENAME-$destination_cellindex EUtranCellTDD\n";
           $DESTTYPE="EUtranCellTDD";
           # CXP 903 0491-135-1
           if($Frequency<36005){$Frequency=$Frequency+36004;}           
       }# end else 
     
       # support for attribute imLoadBalancingActive
       if(($originating_cellindex!=$destination_cellindex)&&($mimcomparisonstatus eq "yes")) {
           # build mo script
           @MOCmds=qq( CREATE
            (
            parent "ManagedElement=1,ENodeBFunction=1,$ORIGTYPE=$NODESTRING-$originating_cellindex,EUtranFreqRelation=$Frequency"
            identity $RELATIONID 
            moType EUtranCellRelation
            exception none
            nrOfAttributes 3
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,$DESTTYPE=$NODESTRING-$destination_cellindex
            imLoadBalancingActive Boolean True
            );
           );# end @MO
print $fh "@MOCmds";
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           $RELATIONID++;
       }# end if

       # support for attribute imLoadBalancingActive
      if(($originating_cellindex!=$destination_cellindex)&&($mimcomparisonstatus eq "no")) {
           # build mo script
           @MOCmds=qq( CREATE
            (
            parent "ManagedElement=1,ENodeBFunction=1,$ORIGTYPE=$NODESTRING-$originating_cellindex,EUtranFreqRelation=$Frequency"
            identity $RELATIONID
            moType EUtranCellRelation
            exception none
            nrOfAttributes 3
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,$DESTTYPE=$NODESTRING-$destination_cellindex
            );
           );# end @MO

print $fh "@MOCmds";
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           $RELATIONID++;
      }# end if

       $destination_cellindex++;
   }# end inner2 foreach
   $originating_cellindex++;
  }# end inner foreach 
  #####################################
  # end Internal Cell Relations
  #####################################
  if (@primarycells > 1) {
           push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

            # build mml script 
            @MMLCmds=(".open ".$SIMNAME,
            ".select ".$LTENAME,
            ".start ",
            "useattributecharacteristics:switch=\"off\"; ",
            "kertayle:file=\"$NETSIMMOSCRIPT\";"
            );# end @MMLCmds
            $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
  }

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
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
