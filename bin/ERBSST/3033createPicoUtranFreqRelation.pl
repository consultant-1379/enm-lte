#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : creates PICO UtranFreqRelation             
# Description : creates support for the creation of PICO2WRAN
# Jira        : NETSUP-1019
# Date        : January 2014
# Who         : epatdal
####################################################################
####################################################################
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
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picotype="UtranFreqRelation";
local $TotalUtranFrequency=6;
local $currUtranFrequency=1;
local $cellcount=1;

while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get current node count number
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    ###############################################
    # start create PICO UtraNetwork.UtranFrequency
    ###############################################
    $currUtranFrequency=1;

    while($currUtranFrequency<=$TotalUtranFrequency){# start while
       # build mml script 
       @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
        "createmo:parentid=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtranCellFDD=$LTENAME-$cellcount\",type=\"$picotype\",name=\"$currUtranFrequency\";"
    );# end @MMLCmds 

       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

       $currUtranFrequency++;
    }# end while

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
print "... ${0} ended running at $date\n";
################################
# END
################################
