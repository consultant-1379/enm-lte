#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : creates PICO UtranFreqRelation.UtranCellRelation             
# Description : creates support for the creation of PICO2WRAN
#               network support
# Jira        : NETSUP-1019
# Date        : January 2014
# Who         : SimNet/epatdal
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
use LTE_OSS13;
use LTE_Relations;
use LTE_OSS14;
####################
# Vars
####################
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEMSRBSV1x160-RVPICO-FDD-LTE36 CONFIG.env 36);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# end verify params

local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICOCELLNUM=&getENVfilevalue($ENV,"PICOCELLNUM");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
local $PICOSIMEND=&getENVfilevalue($ENV,"PICOSIMEND");
local $PICONETWORKCELLSIZE=&getENVfilevalue($ENV,"PICONETWORKCELLSIZE");
local $PICOMAJORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMAJORPERCENTNETWORK");
local $PICOMINORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMINORPERCENTNETWORK");
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/UtranCellRelation.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picocelltype="UtranCellRelation";
local $UtranCellRelationcounter;
local $TotalUtranFrequency=6;
local $currUtranFrequency=1;
local $ExternalUtranCellFDDID;
local $MaxExternalUtranCellFDD=600;
# ExternalUtranCells with ratio of 1:6
local $NodeExternalUtranCellFDD=6;
local $Minus1NodeExternalUtranCellFDD=$NodeExternalUtranCellFDD-1;
local $currExternalUtranCellFDD=1;
local $externalcellsperUtranFrequency=int($NodeExternalUtranCellFDD/$TotalUtranFrequency);
local $currexternalcellsperUtranFrequency;
local $cellcount=1;

# cycle thru PICO sim
while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get current node count number
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    ########################################################
    # start create PICO UtranFrequency.ExternalUtranCellFDD
    ########################################################
    $currUtranFrequency=1;
    $UtranCellRelationcounter=1;

    # cycle thru the UtranFrequency
    while($currUtranFrequency<=$TotalUtranFrequency){# start while
     
     $currexternalcellsperUtranFrequency=1;

     $externalcellsperUtranFrequency=int($NodeExternalUtranCellFDD/$TotalUtranFrequency);

     # create ExternalUtranCellFDD
       while($currexternalcellsperUtranFrequency<=$externalcellsperUtranFrequency){
    
         # ensure last UtranFrequency has 5 cells
         #if($currUtranFrequency==6){$externalcellsperUtranFrequency=5;}
        
         # build mml script 
         @MMLCmds=(".open ".$SIMNAME,
           ".select ".$LTENAME,
           ".start ",
           "useattributecharacteristics:switch=\"off\";",
        "createmo:parentid=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtranCellFDD=$LTENAME-$cellcount,UtranFreqRelation=$currUtranFrequency\",type=\"$picocelltype\",name=\"$UtranCellRelationcounter\";" 
         );# end @MMLCmds
print $fh "$MMLCmds[4]";
print $fh "\n";
       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

       $currexternalcellsperUtranFrequency++;
       $UtranCellRelationcounter++;
      }# end inner while 

       $currUtranFrequency++;
    }# end while cycle thru the UtranFrequency

  $NODECOUNT++;
}# end outer while PICONUMOFRBS

  # execute mml script
  @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
  print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink "$NETSIMMMLSCRIPT";
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
