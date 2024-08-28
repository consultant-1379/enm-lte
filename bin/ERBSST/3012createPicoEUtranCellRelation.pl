#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.7
# Revision    : CXP 903 0491-42-19
# Purpose     : creates PICO cell relations among PICO nodes
# Description : creates support for the creation of PICO cell relations 
#               amongst PICO nodes
# Jira        : NETSUP-1019
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################            
# Version2    : LTE 15B         
# Revision    : CXP 903 0491-115-1              
# Purpose     : Correct number of nodes in Major/Minor PICO network.
# Description : Correct number of nodes in Major/Minor PICO network.
# Date        : 17 Dec 2014             
# Who         : edalrey         
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
local $TOTALPICONODES=int($PICONETWORKCELLSIZE/$PICOCELLNUM);
# 80% of the nodes in the network
local $MAJORPICONETWORKNODES=int($TOTALPICONODES/100)*$PICOMAJORPERCENTNETWORK;
local $MINORPICONETWORKNODES=$TOTALPICONODES-$MAJORPICONETWORKNODES;

# CXP 903 0491-115-1             
local $MAJORPICORELATIONSNUMBER=8;
local $MINORPICORELATIONSNUMBER=10;

local $PICORELATIONSNUMBER=0;
local $counter;
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
local $picocelltype="EUtranCellFDD";
local $picoeutranfregrelation="EUtranFreqRelation";
local $picoeutrancellrelation="EUtranCellRelation";
local $cellcount=1;

while ($NODECOUNT<=$PICONUMOFRBS){
    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get node count number
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    # check for current node's position in the network breakdown
    if($nodecountinteger<=$MAJORPICONETWORKNODES){
       $PICORELATIONSNUMBER=$MAJORPICORELATIONSNUMBER;}
    else{$PICORELATIONSNUMBER=$MINORPICORELATIONSNUMBER;} 

    ##################################
    # start create PICO cellrelations
    ##################################  
    $counter=1;
    while($counter<=$PICORELATIONSNUMBER){

    # build mml script 
    @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
"createmo:parentid=\"ManagedElement=$LTENAME,ENodeBFunction=1,$picocelltype=$LTENAME-$cellcount,$picoeutranfregrelation=$cellcount\",type=\"$picoeutrancellrelation\",name=\"$counter\";"
    );# end @MMLCmds

    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
   $counter++;

   }# end inner while

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
