#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : To create External Eutran Relations for DG2 for LTE 16A
# Description : External Eutran Relations to be made for DG2 to DG2 and DG2 to CPP 
# Date        : June 2015
# Who         : xsrilek
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
# Version3    : LTE 17.2
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
# Version4    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               EUtranCellRelation MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version18   : LTE 18.12
# Revision    : CXP 903 0491-342-1
# Jira        : NSS-19508
# Purpose     : Increase the relation count as per NRM 4.1
# Description : The RELATIONMODERATOR has been added to scaleup the 
#               relations with externalcells with multiple frequencies
# Date        : Jun 2018
# Who         : xravlat
####################################################################
# Version19    : LTE 18B
# Revision    : CXP 903 0491-357-1
# Jira        : NSS-26165
# Description : Create diff files for EUtranCellRelation 
# Date        : July 2019
# Who         : xmitsin
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
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;$TYPE2;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT,$FREQCOUNT;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $RELATIONMODERATOR=&getENVfilevalue($ENV,"RELATIONMODERATOR");
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
local $ref_to_Cell_to_Node = &buildCelltoNode(\@PRIMARY_NODECELLS);
my @Cell_to_Node = @{$ref_to_Cell_to_Node};
&store_Cells_to_Node(@Cell_to_Node);

local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);

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
local $nodecellindex,$ttlsizenallexternalnodecelldata;
local @eutranfreqbands=();

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
#####################
#Open file
#####################
local $filename = "$topologyDirPath/EUtranCellRelation4287.txt";
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
  $NODESTRING=$LTENAME;

  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$DG2NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround


  @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  $nodecellsize=@primarycells;# flexible cellnum

  #====================================
  # start get INTEREUTRANCELLRELATIONS 
  #====================================
  $originating_nodecellindex=1;
  foreach $originating_cell (@primarycells) {

      # check cell type
      # CXP 903 0491-135-1
      if((&isCellFDD_Upgrade($originating_cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
          $ORIGTYPE="EUtranCellFDD";
      }# end if
      else{
          $ORIGTYPE="EUtranCellTDD";
      }# end else

      $RELATIONID=$nodecellsize; # allow for offset of intrarelations
      local @relatedCells=&getInterEUtranCellRelations($originating_cell, $ref_to_CellRelations);
     
      $exteutrancellsReltnCount=1; 
      foreach $destination_cell (@relatedCells) {
	  if ($exteutrancellsReltnCount == 200) {next;} # Major:135, Minor:350(NRM6_2)
	  print "exteutrancellsCount=$exteutrancellsReltnCount , LTENAME=$LTENAME\n";
          #$destination_node = &getCelltoNode_Upgrade($destination_cell);
          $destination_node = &getCelltoNode_Upgrade($destination_cell);
 
	  #$Frequency = $Cell_to_Freq[$destination_cell];
          $Frequency = $Cell_to_Freq[$destination_cell];

   	  $EXTERNALNODESIM=&getLTESimNum($destination_node,$DG2NUMOFRBS);
          # nasty workaround for error in &getLTESimStringNodeName
          if($destination_node>$DG2NUMOFRBS){
             $destination_node=($destination_node-($EXTERNALNODESIM-1)*$DG2NUMOFRBS);
          }

          $EXTERNALNODESTRING=&getLTESimStringNodeName($EXTERNALNODESIM,$destination_node);

          # workaround to leave node ending with "0000"
          @EXT1 = split /ERBS/, $EXTERNALNODESTRING;
          if ("$EXT1[1]" == "0000") {next;}

          $destination_nodecellindex=&getNodeFlexibleCellIndex($destination_cell,$NETWORKCELLSIZE,$nodecountinteger,$blockSize,@PRIMARY_NODECELLS);
          
          # check cell type
          # CXP 903 0491-135-1
          if((&isCellFDD_Upgrade($destination_cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$EXTERNALNODESIM)))) {
              $DESTTYPE="ExternalEUtranCellFDD";
          }# end if
          else{
              $DESTTYPE="ExternalEUtranCellTDD";
          }# end else

          # CXP 903 0491-135-1
	      if($ORIGTYPE eq "EUtranCellTDD"){
	        if($Frequency<36005){$Frequency=$Frequency+36004;}
	      }
         
          #------------------------------------------------------------------------------------------------
          # START : ensure FDD cells handshake with FDD cells only and TDD cells handshake TDD cells only
          #------------------------------------------------------------------------------------------------

	  #See NETSUP-1735 for details of removal.

          #------------------------------------------------------------------------------------------------
          # END : ensure FDD cells handshake with FDD cells only and TDD cells handshake TDD cells only
          #------------------------------------------------------------------------------------------------
          @MOCmds=();
          my $FREQUENCY = 1 ;
    if($Frequency <= $RELATIONMODERATOR){
         while ($FREQUENCY <= $RELATIONMODERATOR){
           @MOCmds=qq( CREATE
            (
            parent "ManagedElement=$LTENAME,ENodeBFunction=1,$ORIGTYPE=$NODESTRING-$originating_nodecellindex,EUtranFreqRelation=$FREQUENCY"
            identity $RELATIONID
            moType Lrat:EUtranCellRelation
            exception none
            nrOfAttributes 4
            "timeOfCreation" String "2017-11-29T09:32:56"
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING,$DESTTYPE=$EXTERNALNODESTRING-$destination_nodecellindex
            );
            );# end @MO
print $fh "@MOCmds";          

            $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
            $RELATIONID++;
            $FREQUENCY++;
            }
                         }
                         else
                         {
                                    @MOCmds=qq( CREATE
            (
            parent "ManagedElement=$LTENAME,ENodeBFunction=1,$ORIGTYPE=$NODESTRING-$originating_nodecellindex,EUtranFreqRelation=$Frequency"
            identity $RELATIONID
            moType Lrat:EUtranCellRelation
            exception none
            nrOfAttributes 3
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTERNALNODESTRING,$DESTTYPE=$EXTERNALNODESTRING-$destination_nodecellindex
            );
            );# end @MO
print $fh "@MOCmds";

            $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
            $RELATIONID++;
	    $exteutrancellsReltnCount++;
                         }
       }
       $originating_nodecellindex++;
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
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
