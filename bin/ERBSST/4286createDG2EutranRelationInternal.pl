#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : Eutan Relation Internal to DG2 for LTE 16A
# Description : Creates Internal Eutran Relations for DG2
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
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
# Version4    : LTE 18B
# Revision    : CXP 903 0491-357-1
# Jira        : NSS-26165
# Description : Create diff files for EUtranCellRelation
# Date        : July 2019
# Who         : xmitsin
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
local $forcounter,$cellid,$cellid2;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$ORIGTYPE;$DESTTYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
# for node cells/adjacent cells
local @nodecells=(),$nodecountinteger2;
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local @primarycellsarchive;
local $tempadjacentcellsize,$adjacentcellsize;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);

#------------------------------------------------------------------------
# 60K optimisation
#------------------------------------------------------------------------
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);
#------------------------------------------------------------------------

####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/EUtranCellRelation4286.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
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
  

  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);
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

    $NODESIM=&getLTESimNum($nodecountinteger,$DG2NUMOFRBS);

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodecountinteger>$DG2NUMOFRBS){
       $nodecountfornodestringname=$nodecountinteger-($LTE-1)*$DG2NUMOFRBS;
    }# end if
    else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

    $NODESTRING=&getLTESimStringNodeName($NODESIM,$nodecountfornodestringname);

    print "####################################################################\n";
    print "# INTERNAL RELATIONS of $ORIGTYPE=$NODESTRING-$originating_cellindex\n";
    print "####################################################################\n";

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
     
      if($originating_cellindex!=$destination_cellindex) {
           # build mo script
           @MOCmds=qq( CREATE
            (
            parent "ManagedElement=$LTENAME,ENodeBFunction=1,$ORIGTYPE=$NODESTRING-$originating_cellindex,EUtranFreqRelation=$Frequency"
            identity $RELATIONID
            moType Lrat:EUtranCellRelation
            exception none
            nrOfAttributes 3
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=$LTENAME,ENodeBFunction=1,$DESTTYPE=$NODESTRING-$destination_cellindex
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