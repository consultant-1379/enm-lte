#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : sets PICO2LTE ExternalENodeBFunction.eNBId            
# Description : sets support for the creation of PICO cell relations 
#               to LTE nodes
# Jira        : NETSUP-1019
# Date        : Jan 2014
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
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pico\//;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $minimumcellsize=6; # minimum LTE node cell size to be related with PICO nodes
local $command1="./writePICO2LTEcellassociations.pl $minimumcellsize";
local $retval;
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
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."PICO".$PICONETWORKCELLSIZE."networkcellrelations.csv";
local @PICO2LTECELLRELATIONS=();
local $pico2ltecellrelationssize=0;
local $templtesimnum;
local $templtenodenum;
local $templtenodecount;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}

# check PICO2LTE network relations file exits
if(!(-e $LTENetworkOutput)){# create PICO2LTE relations
   print "Executing $command1 to create $LTENetworkOutput\n";
   $retval=system("$command1 >/dev/null 2>&1");
   if($retval!=0){
      print "FATAL ERROR : unable to create $LTENetworkOutput\n";
      $retval=0;
      exit;
   }# end inner if
}# end outer if
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################

# start get PICO2LTE cell relations
open FH1, "$LTENetworkOutput" or die $!;
         @PICO2LTECELLRELATIONS=<FH1>;
close(FH1);
$pico2ltecellrelationssize=@PICO2LTECELLRELATIONS;
if($pico2ltecellrelationssize<1){
   print "FATAL ERROR : unable to read $LTENetworkOutput\n"; 
}# end if
# end get PICO2LTE cell relations

local $picotype="ExternalENodeBFunction";
local $cellcount=1;
local $picoarrayposition=0;
local $configLTEnodename;
local $prevLTENodename;
local $configPICOnodename;
local $configLTEnodecellname;
local $configPICOnodecellname;
local $element;
local $NUMOFRBS=160;

while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get node current nodecountnumber
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

    # find PICO first node array position in @PICO2LTECELLRELATIONS
    if($NODECOUNT==1){
       # cyle thru PICO2LTE cell relations config file
       foreach $element(@PICO2LTECELLRELATIONS){
             if($element =~/\#/){$picoarrayposition++;next;}
             if(!($element=~/LTE/)){$picoarrayposition++;next;}
             if($element=~/running/){$picoarrayposition++;next;}
            ($configPICOnodecellname,$configLTEnodecellname)=split(/\;/,$element);
             $configLTEnodename=$configLTEnodecellname;
             $configPICOnodename=$configPICOnodecellname;
             $configLTEnodename=~s/\-.*//;
             $configPICOnodename=~s/\-.*//;
             # check for match
             if($LTENAME=~m/$configPICOnodename/){
               last;
             }# end if
             $picoarrayposition++;
       }# end foreach
    }# end if 
 
    ############################################
    # start set PICO2LTE ExternalENodeBFunction
    ############################################
   
    #####################################
    # start get PICO related LTEnodename
    #####################################
   while ($LTENAME=~m/$configPICOnodename/){ # match PICO node 

     $prevLTENodename=$configLTEnodename;
    ($configPICOnodecellname,$configLTEnodecellname)=split(/\;/,$PICO2LTECELLRELATIONS[$picoarrayposition]);
    $configLTEnodename=$configLTEnodecellname;
    $configPICOnodename=$configPICOnodecellname;
    $configLTEnodename=~s/\-.*//;
    $configPICOnodename=~s/\-.*//;
    $configLTEnodename=~ s/^\s+|\s+$//g;
    $configLTEnodename=~ s/^\s+|\s+$//g;
    
    # check for duplication
    if($prevconfigLTEnodename=~m/$configLTEnodename/){$picoarrayposition++;next;}

    # exit when mismatch
    if(!($LTENAME=~m/$configPICOnodename/)){last;}

    # get eNBId 
    $templtesimnum=$configLTEnodename;
    $templtesimnum=~s/ERBS.*//;
    $templtesimnum=~s/LTE0//;
    $templtesimnum=~s/LTE//;

    $templtenodenum=$configLTEnodename;
    $templtenodenum=~s/.*ERBS0000//;
    $templtenodenum=~s/.*ERBS000//;
    $templtenodenum=~s/.*ERBS00//;

     # get lte node count
     $templtenodecount=&getLTESimIntegerNodeNum($templtesimnum,$templtenodenum,$NUMOFRBS);
    
    # build mml script
    @MMLCmds=(".open ".$SIMNAME,
               ".select ".$LTENAME,
               ".start ",
               "useattributecharacteristics:switch=\"off\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,$picotype=$configLTEnodename\",attributes=\"eNBId (int32)=$templtenodecount\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,$picotype=$configLTEnodename\",attributes=\"eNodeBPlmnId (struct, PlmnIdentity)=[353,57,2]\";"
    );# end @MMLCmds

    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

    $picoarrayposition++;
   }# end while match PICO node 
   #####################################
   # end get PICO related LTEnodename
   #####################################
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
