#!/usr/bin/perl
### VERSION HISTORY
######################################################################################
# Version1 
# Description : writes a file to for ex: 
#               ~/customdata/networkarchive/LTE28000EUtranCellData.csv
#               which is an archive of LTE28K EUtranCell data which is used when generating
#               the ExeternalEUtranCell network to negate SNAD issue particularly with PCI
#               cell data missing (SNAD CC RuleSet LMI-14:001152 Issue 4)
# SNID        : LMI-14:001152 (SNAD CC RuleSet.xls)
# Syntax      : ./archiveEUtranCelldata.pl
# Example     : ./archiveEUtranCelldata.pl
# Date        : July 2014
# who         : epatdal
######################################################################################
######################################################################################
# Version2    : LTE 14B.1
# Revision    : CXP 903 0491-90-1
# Purpose     : check cellnum increment does not become 0 valued
# Date        : September 2014
# Who         : edalrey
######################################################################################
######################################################################################
# Version3    : LTE 15B
# Revision    : CXP 903 0491-135-1
# Purpose     : resolves an issue where TDD cells are represented 
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Jira        : NETSUP-2748 
# Description : ensure TDD and FDD cells are not represented 
#               incorrectly 
# Date        : Mar 2015
# Who         : epatdal
######################################################################################
######################################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-141-1
# Purpose     : Generate new ext n/w files for new MULTISIMS.env configs
# Description : create updated nodeTypesForSims.env from ~/dat/MULTISIMS.env 
# Date        : 20/04/2015
# Who         : edalrey
######################################################################################
######################################################################################
# Version5    : LTE 15.14
# Revision    : CXP 903 0491-171-1
# Purpose     : Generate cell pattern based cell ratios before creating EUtran data
# Description : add subroutine calls to generate cell pattern from cell ratios defined 
#               in CONFIG.env and write the generated cell pattern to the CONFIG.env 
# Date        : Sept 2015
# Who         : ejamfur
######################################################################################
######################################################################################
# Version6    : LTE 17.1
# Revision    : CXP 903 0491-278-1
# Purpose     : Generate correct cell pattern for PICO nodes
# Description : PICO cells to be fetched properly
# Date        : Dec 2016
# Who         : xkatmri
######################################################################################
######################################################################################
# Version7    : LTE 17.5
# Revision    : CXP 903 0491-287-1
# JIRA        : NSS-10178
# Purpose     : LTE code base to be updated
# Description : physicalLayerSubCellId and physicalLayerCellIdGroup to be made 0 and 0
#               for PICO cells
# Date        : Feb 2017
# Who         : xkatmri
######################################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local @helpinfo=qq(

Usage : ${0}
Example: $0

Description  : this script archives EUtranCell data for any LTE network to a file
               in for ex: ~/customdata/networkarchive/LTE28000EUtranCellData.csv
               and outputs data as rows = LTENAME-CELLCOUNT;physicalLayerSubCellId;physicalLayerCellIdGroup
               - see SNAD CC RuleSet LMI-14:001152 Issue 4 
               );

local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
#----------------------------------------------------------------
local $CONFIG="CONFIG.env"; # script base CONFIG.env
$ENV=$CONFIG;

local $linepattern= "#" x 100;
local $inputfilesize,$arrelement,$element;
local $tempcounter,$inputfileposition=0;
local $startdate=`date`;
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pci\//;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $DATDIR=$scriptpath;
$DATDIR=~s/bin.*/dat\//;
$lineCount = `wc -l < $DATDIR/nodeTypesForSims.env`;
local @nodeTypesForSims=();

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
# get cell configuration ex: 6,3,3,1 etc.....
local @CELLPATTERN=&generateCellPattern($ENV,"CELLRATIOS");
&writeCellPatternToConfigFile(@CELLPATTERN);
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
@CELLPATTERN=split(/\,/,$CELLPATTERN);
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# populate network grid with all cell data
local (@FULLNETWORKGRID)=&getAllNodeCells(2,1,$NETWORKCELLSIZE);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
local ($cellid,$latitutde,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup);
local @NETSIMMOSCRIPTS=();
local $MIMCombinedCellSupport="D125";
local $isCombinedCellSupported;

local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/networkarchive\//;
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."EUtranCellData.csv";
# cell channelbandwith values
local $command1="./archiveEUtranCelldata.pl";
local @bandwidthrange=qw/1400 3000 5000 10000 15000 20000/;
local $bandwidthrangesize=@bandwidthrange;
local $tempbandwidthrangesize=0;
local $CHANNELBANDWIDTH="";
local $channelbandwidthvalue;

#Reading the content of nodeTypesForSims.env in an array
open FH10, "$DATDIR/nodeTypesForSims.env" or die $!;
           @nodeTypesForSims=<FH10>;
close(FH10);

####################
# Integrity Check
####################
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
   print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure params are as expected
#-----------------------------------------
if (!( @ARGV==0)){
print "@helpinfo\n";exit(1);}

if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#-----------------------------------------
# ensure innerPCInetwork file created
#-----------------------------------------
open FH1, "> $LTENetworkOutput" or die $!;
################################
# MAIN
################################
#########################
# main
##########################
$MULTISIMS=$scriptpath;
$MULTISIMS=~s/bin.*//;
$MULTISIMS=$MULTISIMS."dat/MULTISIMS.env";
local $nodeTypes=&createNodeTypesForSims($MULTISIMS);
print "Creating $nodeTypes for EUtran cell data\n";
print FH1 "Creating $nodeTypes for EUtran cell data\n";

local $csvinputfileline;

print FH1 "$linepattern\n";
print FH1 "... ${0} started running at $startdate";
print FH1 "$linepattern\n";
print FH1 "# LTE14B.1 EUtranCell data archive created\n";
print FH1 "# Note : data used when creating the ExternalEUtranCell network\n";
print FH1 "#        data output in rows as follows: LTENAME-CELLCOUNT;physicalLayerSubCellId;physicalLayerCellIdGroup\n";
print FH1 "# Resolves : LMI-14:001152 SNAD CC RuleSet.xls Issue 4\n";
print FH1 "$linepattern\n\n";
#-----------------------------------
# start build PICO2LTE associations
#-----------------------------------
$ttlcellcounter=0;$LTE=0;
################################
# start get LTE network by cell
################################
while($ttlcellcounter<=$NETWORKCELLSIZE){ # start outer while NETWORKCELLSIZE

 $NODECOUNT=1;$LTE++;

 if ($nodeTypesForSims[$LTE] eq "" || $LTE==$lineCount){exit;}

 while ($NODECOUNT<=$NUMOFRBS){
   # get node name
   $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

   # get node primary cells
   $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
   @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
   $CELLNUM=@primarycells;
   # CXP 903 0491-90-1, 24/09/2014
   # check cellnum increment does not become 0 valued
   if($CELLNUM==0){last;}

   $CELLCOUNT=1;
   $physicalLayerSubCellId=0;
   $physicalLayerCellIdGroup=0;

   if($LTENAME=~m/p/) {
     print FH1 "$LTENAME-$CELLCOUNT;$physicalLayerSubCellId;$physicalLayerCellIdGroup\n";
   }# end if

   else {

    foreach $Cell (@primarycells) {
     # check cell type
     # CXP 903 0491-135-1
     if((&isCellFDD_Upgrade($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="EUtranCellFDD";
      $CHANNELBANDWIDTH="dlChannelBandwidth";
     }# end if
     else{
      $TYPE="EUtranCellTDD";
      $CHANNELBANDWIDTH="channelBandwidth";
      if($Frequency<36005){$Frequency=$Frequency+36004;}
     }# end else

    # set round robin channelbandwith range
    if($tempbandwidthrangesize>=$bandwidthrangesize){$tempbandwidthrangesize=0;}
    if($tempbandwidthrangesize<$bandwidthrangesize){
       $channelbandwidthvalue=$bandwidthrange[$tempbandwidthrangesize];
       $tempbandwidthrangesize++;
    }# end

    # get node cell data
    ($gridrow,$gridcol)=&getCellRowCol($Cell,$NETWORKCELLSIZE);
    ($cellid,$latitude,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup)=split(/\../,$FULLNETWORKGRID[$gridrow][$gridcol]); 
    print FH1 "$LTENAME-$CELLCOUNT;$physicalLayerSubCellId;$physicalLayerCellIdGroup\n";
    $CELLCOUNT++;
  }# end inner CELL foreach
 }#end else

  $NODECOUNT++;
  $CELLCOUNT=1;
  $ttlcellcounter=$CELLNUM+$ttlcellcounter;

}# end outer while

   # check node cell size does not exceed NETWORKCELLSIZE
   # CXP 903 0491-90-1
   # check cellnum increment does not become 0 valued
   if(($ttlcellcounter>=$NETWORKCELLSIZE)||($CELLNUM==0)){last;}

}# end outer while NETWORKCELLSIZE
################################
# end get LTE network by cell
################################
################################
# CLEANUP
################################
#########################
# cleanup
#########################
$date=`date`;
print FH1 "$linepattern\n";
print FH1 "... ${0} ended running at $date";
print FH1 "$linepattern\n";
close(FH1);
#########################
# EOS
#########################
