#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : creates PICO External Network for PICO               
# Jira        : NETSUP-1019
# Date        : Feb 2014
# Who         : ecasjim
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
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;
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
local $MAJORPICORELATIONSNUMBER=8;
local $MINORPICORELATIONSNUMBER=10;
local $PICORELATIONSNUMBER=0;
local $maxrelatednodes;
local @relatednodes=();
local $element,$arrcounter,$arrcounter2,$tempnum,$tempstringnode;
local $networkblockflag=0;
local $outercounter;
local $counter;
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
local $filename = "$topologyDirPath/TermPointToEnb.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picotype="ExternalEUtranCellFDD";
local $cellcount=1;
$outercounter=0;
local $TermPoint="TermPointToENB";
local $ipaddress="0.0.0.0";

while ($NODECOUNT<=$PICONUMOFRBS){
    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get node current nodecountnumber
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    # check for current node's position in the network breakdown
    if($nodecountinteger<=$MAJORPICONETWORKNODES){
       $PICORELATIONSNUMBER=$MAJORPICORELATIONSNUMBER;}
    else{$PICORELATIONSNUMBER=$MINORPICORELATIONSNUMBER;}

    $maxrelatednodes=$PICORELATIONSNUMBER;

    if($outercounter>=$maxrelatednodes){$outercounter=0;$networkblockflag=0;}
     
    if($networkblockflag==0){
       $networkblockflag=1;

       # populate the related nodes
       $tempnum=$nodecountinteger;
       $arrcounter=0;$arrcounter2=0;

       while($arrcounter<$maxrelatednodes){
             # exclude current nodecounterintger from the relations
             $relatednodes[$arrcounter2]=$tempnum;
             $tempnum++;$arrcounter++;$arrcounter2++; 
       }# end inner while
    }# end networkblockflag
    
    ##################################
    # start creating TermToPoint MOs
    ##################################  
    $counter=1;$arrcounter=0;

    while($counter<=$PICORELATIONSNUMBER){
      
          $tempstringnode=&getPICOStringNodeName($PICOSIMSTART,$relatednodes[$arrcounter],$PICONUMOFRBS);

          # exclude current node relation to itself
          if($LTENAME=~m/$tempstringnode/){$arrcounter++;$counter++;next;}  

          # build mml script 
          @MMLCmds=(".open ".$SIMNAME,
                    ".select ".$LTENAME,
                    ".start ",
          "useattributecharacteristics:switch=\"off\";",
          "createmo:parentid=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$tempstringnode\",type=\"$TermPoint\",name=\"1\";",
          "setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$tempstringnode,$TermPoint=1\",attributes=\"ipAddress (string)=$ipaddress\";"
   
    );# end @MMLCmds
print $fh "$MMLCmds[4]";
print $fh "\n";
    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
    $counter++;$arrcounter++;

   }# end inner while

  $outercounter++;
  $NODECOUNT++;
}# end outer while PICONUMOFRBS

  # execute mml script
   @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
   print "@netsim_output\n";

  # remove mo script
  unlink "$NETSIMMMLSCRIPT";

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
