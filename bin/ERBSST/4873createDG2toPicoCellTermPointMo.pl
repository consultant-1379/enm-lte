#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-155-1
# Purpose     : creates DG2toPICO ExternalENodeBFunction.ExternalCells                
# Description : creates support for the creation of LTE cell relations 
#               to PICO nodes
# Jira        : NETSUP-3047
# Date        : 05-June-2015
# Who         : xkamvat
####################################################################
####################################################################
# Version2    : LTE 17B
# Revision    : CXP 903 0491-282-1
# Jira        : NSS-9304
# Purpose     : LtetoPicoCell relation scripts to be updated
# Description : LtetoPicoCell relation scripts should skip when no
#               relations are created
# Date        : 12-Jan-2017
# Who         : xkatmri
####################################################################
#####################
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
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTE15B-V9x160-RVDG2-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# CXP 903 0491-119-1 - get SETPICOENABLED varialbe
local $SETPICOENABLED=&getENVfilevalue($ENV,"SETPICOENABLED");
# CXP 903 0491-91-1 - check if PICO is enabled
if($SETPICOENABLED ne "YES"){exit;}

# check if SIMNAME is of type PICO
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
# end verify params

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
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $minimumcellsize=3; # minimum LTE node cell size to be related with PICO nodes # <CHECK THE CHANGE FROM 6 TO 3>
local $command1="./writePICO2LTEcellassociations.pl $minimumcellsize";
local $retval;
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
####################################################################################
#
#
#  Check the network break down starts
#
#########################################################################################
local $PICOCELLNUM=&getENVfilevalue($ENV,"PICOCELLNUM");
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
####################################################################################
#
#
#  Check the network break down ends
#
#########################################################################################
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."PICO".$PICONETWORKCELLSIZE."networkcellrelations.csv";
local @PICO2LTECELLRELATIONS=();
local $pico2ltecellrelationssize=0;
local $arrsize;
local $temppicosimnum;
local $temppiconodenum;
local $temppiconodecount;
local $TYPE="ExternalEUtranCellFDD";
local $TYPEID="ExternalEUtranCellFDDId";
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

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

local $ltearrayposition=0;
local $configLTEnodename;
local $configPICOnodename;
local $configLTEnodecellname;
local $configPICOnodecellname;
local $element;
local $ltematch=0;
local $downLinkFreq;

# cycle thru LTE simulation
while ($NODECOUNT<=$DG2NUMOFRBS){

    # get LTE node name
    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    # find LTE node array position in @PICO2LTECELLRELATIONS
    $ltearrayposition=0;$ltematch=0;
    if($NODECOUNT<=$DG2NUMOFRBS){
       # cyle thru PICO2LTE cell relations config file
       foreach $element(@PICO2LTECELLRELATIONS){
             if($element =~/\#/){$ltearrayposition++;next;}
             if(!($element=~/LTE/)){$ltearrayposition++;next;}
             if($element=~/running/){$ltearrayposition++;next;}
            ($configPICOnodecellname,$configLTEnodecellname)=split(/\;/,$element);
             $configLTEnodename=$configLTEnodecellname;
             $configPICOnodename=$configPICOnodecellname;
             $configLTEnodename=~s/\-.*//;
             $configPICOnodename=~s/\-.*//;
             $configLTEnodename=~ s/^\s+|\s+$//g;
             # check for match
             if($LTENAME=~m/$configLTEnodename/){
               $ltematch=1;
               last;
             }# end if
             $ltearrayposition++;
       }# end foreach
    }# end if 
    $arrsize=@PICO2LTECELLRELATIONS;
    # did not find a match for current LTE node
    if($ltematch==0){$NODECOUNT++;next;} 
    ############################################
    # start set LTE2PICO ExternalENodeBFunction
    ############################################
   
    #####################################
    # start get LTE related PICOnodename
    #####################################
    while ($ltearrayposition<=$arrsize){
    ($configPICOnodecellname,$configLTEnodecellname,$downLinkFreq)=split(/\;/,$PICO2LTECELLRELATIONS[$ltearrayposition]);
    $configLTEnodename=$configLTEnodecellname;
    $configPICOnodename=$configPICOnodecellname;
    $configLTEnodename=~s/\-.*//;
    $configPICOnodename=~s/\-.*//;
    $configPICOnodename=~ s/^\s+|\s+$//g;
    $configLTEnodename=~ s/^\s+|\s+$//g;
    $downLinkFreq=$downLinkFreq-18000;
    
    # exit when mismatch
    if(!($LTENAME=~m/$configLTEnodename/)){$ltearrayposition++;next;}

    # get eNBId
    $temppicosimnum=$configPICOnodename;
    $temppicosimnum=~s/pERBS.*//;
    $temppicosimnum=~s/LTE0//;
    $temppicosimnum=~s/LTE//;

    $temppiconodenum=$configPICOnodename;
    $temppiconodenum=~s/.*ERBS0000//;
    $temppiconodenum=~s/.*ERBS000//;
    $temppiconodenum=~s/.*ERBS00//;

    $temppiconodecount=&getPICOSimIntegerNodeNum($PICOSIMSTART,$temppicosimnum,$temppiconodenum,$PICONUMOFRBS); 

   if($configPICOnodename eq $old){$ltearrayposition++;next;}

    # build mo script
    @MOCmds=qq( CREATE
      (
       parent "ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$configPICOnodename"
       identity 1
        moType TermPointToENB
        exception none
        nrOfAttributes 0
     );
    );# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds); 
    
    $ltearrayposition++;
    $old=$configPICOnodename;

   }# end while match LTE node 
   #####################################
   # end LTE related PICOnodename
   #####################################
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
}# end outer while not end of array

#CXP 903 0491-282-1
if ( $NETSIMMMLSCRIPT eq "") {
    print "... ${0} ended running as no LTEtoPICO relations are available at $date\n";
    exit;
    }

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
print "... ${0} ended running at $date\n";
################################
# END
################################
