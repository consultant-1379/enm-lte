#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : LTE 14.1.8
#
# User Story  : NETSUP-1019
#
# Purpose     : creates PICO UtraNetwork.UtranFrequency.ExternalUtranCellFDD
#              
# Description : creates support for the creation of PICO2WRAN
#               network support
#
# Date        : January 2014
#
# Who         : SimNet/epatdal
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

#--------------------------------------------
# START Reuse LTE utran proxies in PICO nodes
# get EXTUTRANCELLID
#--------------------------------------------
# array row header = nodenum-utranfrequency-cellnum-extutrancellid
#                eg. 1-1-2-20001
local ($lteutranproxynodenum,$lteutranproxyfrequency,$lteutranproxydellnum,$lteutranproxycellid);
local $STARTINGPICONODENUM=1280;# starts at LTE09 and reuses the extutrancellid
local $tempstartingnodenum;
local $SNADUTRANMASTERS=600; # max of 600 PICO SNAD utran masters required
local $MAXSNADUTRANMASTERS=$SNADUTRANMASTERS+$STARTINGPICONODENUM;# total nodes that include for max of 600 PICO SNAD utran masters 
local @EXTUTRANCELLID=();
local $NODENUMBERNETWORKNINETYFIVE; # nodes in 95% of network
local $NODENUMBERNETWORKFIVE;# nodes in 5% of network
local $TOTALNODESINNETWORK;
local $IRATHOMENABLED=&getENVfilevalue($ENV,"IRATHOMENABLED");
# determine breakdown of nodes in the network
$TOTALNODESINNETWORK=int($NETWORKCELLSIZE/$STATICCELLNUM);

# ensure IRATHOM cells are removed from total network nodes
# as IRATHOM Utran external cells are static
if (uc($IRATHOMENABLED) eq "YES"){
    local $IRATHOMTTLNODES=int(&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS")/($STATICCELLNUM*$STATICCELLNUM));
    $IRATHOMTTLUTRANCELLS=&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS");
    $TOTALNODESINNETWORK=$TOTALNODESINNETWORK-$IRATHOMTTLNODES;
}# end if IRATHOMENABLED

$NODENUMBERNETWORKNINETYFIVE=int(($TOTALNODESINNETWORK/100)*95);# nodes in 95% of network
$NODENUMBERNETWORKFIVE=ceil(($TOTALNODESINNETWORK/100)*5);# nodes in 5% of network

# establish external utran cells per frequency network breakdown
local $EXTCELLSPERFREQNINETYFIVE=4;
local $EXTCELLSPERFREQFIVE=10;

@EXTUTRANCELLID=&getNetworkExtUtranCellID($IRATHOMENABLED,$IRATHOMTTLUTRANCELLS,$NODENUMBERNETWORKNINETYFIVE,$EXTCELLSPERFREQNINETYFIVE,$NODENUMBERNETWORKFIVE,$EXTCELLSPERFREQFIVE);

local $elementcounterforEXTUTRANCELLID=0;
local $arrsize = @EXTUTRANCELLID;
local $element;

if ($arrsize<1){
   print "FATAL Error : @EXTUTRANCELLID has no external utran proxy frequencies\n";
   exit;
}# end if
#------------------------------------------
# END Reuse LTE utran proxies in PICO nodes
# get EXTUTRANCELLID
#------------------------------------------
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picocelltype="ExternalUtranCellFDD";
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

# cycle thru PICO sim
while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get current node count number
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    # Reuse LTE utran proxies in PICO nodes
    $tempstartingnodenum=$nodecountinteger+$STARTINGPICONODENUM;

    if($tempstartingnodenum>$MAXSNADUTRANMASTERS){ # ensures max of 600 SNAD masters
       $tempstartingnodenum=$tempstartingnodenum-$SNADUTRANMASTERS;   
    }# end if   

    # get starting sim $ExternalUtranCellFDDID
    $ExternalUtranCellFDDID=($nodecountinteger*$NodeExternalUtranCellFDD)-$Minus1NodeExternalUtranCellFDD;

    # ensure MaxExternalUtranCellFDD not exceeded
    if($ExternalUtranCellFDDID>$MaxExternalUtranCellFDD){
       $ExternalUtranCellFDDID=$ExternalUtranCellFDDID-$SNADUTRANMASTERS;
       $elementcounterforEXTUTRANCELLID=0;
    }# end if

    ########################################################
    # start create PICO UtranFrequency.ExternalUtranCellFDD
    ########################################################
    $currUtranFrequency=1;

    # cycle thru the UtranFrequency
    while($currUtranFrequency<=$TotalUtranFrequency){# start while
     
     $currexternalcellsperUtranFrequency=1;
     $externalcellsperUtranFrequency=int($NodeExternalUtranCellFDD/$TotalUtranFrequency);

     # create ExternalUtranCellFDD
       while($currexternalcellsperUtranFrequency<=$externalcellsperUtranFrequency){

         #---------------------------------------------
         # START Reuse LTE utran proxies in PICO nodes
         #---------------------------------------------   
         while($elementcounterforEXTUTRANCELLID<=$arrsize){
              ($lteutranproxynodenum,$lteutranproxyfrequency,$lteutranproxydellnum,$lteutranproxycellid)=split(/-/,$EXTUTRANCELLID[$elementcounterforEXTUTRANCELLID]); 
               if(($tempstartingnodenum==$lteutranproxynodenum)&&($lteutranproxyfrequency==$currUtranFrequency)){
                   last;
               }# end if
         $elementcounterforEXTUTRANCELLID++;
         }# end while
        $ExternalUtranCellFDDID=$lteutranproxycellid; 
        #-------------------------------------------
        # END Reuse LTE utran proxies in PICO nodes 
        #-------------------------------------------
    
         # build mml script 
         @MMLCmds=(".open ".$SIMNAME,
           ".select ".$LTENAME,
           ".start ",
           "useattributecharacteristics:switch=\"off\";", 
           "createmo:parentid=\"ManagedElement=$LTENAME,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$currUtranFrequency\",type=\"$picocelltype\",name=\"$ExternalUtranCellFDDID\";" 
         );# end @MMLCmds

       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

       $currexternalcellsperUtranFrequency++;
       $ExternalUtranCellFDDID++;

       # ensure MaxExternalUtranCellFDD not exceeded
       #if($ExternalUtranCellFDDID>$MaxExternalUtranCellFDD){$ExternalUtranCellFDDID=1;}

      }# end inner while create ExternalUtranCellFDD

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
print "... ${0} ended running at $date\n";
################################
# END
################################
