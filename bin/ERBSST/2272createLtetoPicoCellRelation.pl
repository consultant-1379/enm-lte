#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : creates LTE2PICO CellRelation              
# Description : creates support for the creation of LTE cell relations 
#               to PICO nodes
# Jira        : NETSUP-1019
# Date        : Jan 2014
# Who         : epatdal
####################################################################
# Version2    : LTE 14B.1
# Revision    : 
# Purpose     : exit on SETPICOENABLED=NO
# Description : exit this script if a PICO build has not been enabled
#               for the scripts
# Date        : 24 Sept 2014
# Who         : edalrey
####################################################################            
# Version3    : LTE 15B         
# Revision    : CXP 903 0491-119-1              
# Purpose     : exit on SETPICOENABLED=NO
# Description : creates support for the creation of LTE cell relations 
#               to PICO nodes 
# Date        : 12 Jan 2015             
# Who         : edalrey         
####################################################################
####################################################################
# Version4    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : To make script only to run for LTE ERBS nodes
# Description : As DG2 support is also provided, the script should not
#               DG2 nodes. So, checking whethe sim is DG2 or not/
#               renaming script to 2272createLtetoPicoCellRelation.pl
#               as LTE ERBS scripts should be 1000 or 2000 series 
# Date        : May 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version5    : LTE 17B
# Revision    : CXP 903 0491-282-1
# Jira        : NSS-9304
# Purpose     : LtetoPicoCell relation scripts to be updated
# Description : LtetoPicoCell relation scripts should skip when no
#               relations are created
# Date        : 12-Jan-2017
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
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# CXP 903 0491-119-1 - get SETPICOENABLED varialbe
local $SETPICOENABLED=&getENVfilevalue($ENV,"SETPICOENABLED");
# CXP 903 0491-91-1 - check if PICO is enabled
if($SETPICOENABLED ne "YES"){exit;}

# check if SIMNAME is of type LTE
# CXP 903 0491-152-1
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
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
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
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

local $picotype="ExternalENodeBFunction";
local $cellcount=1;
local $picoarrayposition=0;
local $ltearrayposition=0;
local $configLTEnodename;
local $prevLTENodename;
local $configPICOnodename;
local $configLTEnodecellname;
local $configPICOnodecellname;
local $element;
local $ltematch=0;

# cycle thru LTE simulation
while ($NODECOUNT<=$NUMOFRBS){

    # get LTE node name
    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    # find LTE node array position in @PICO2LTECELLRELATIONS
    $ltearrayposition=0;$ltematch=0;
    if($NODECOUNT<=$NUMOFRBS){
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
    $RELATIONID=300;
    #####################################
    # start get LTE related PICOnodename
    #####################################
    while ($ltearrayposition<=$arrsize){
     $prevLTENodename=$configLTEnodename;
    ($configPICOnodecellname,$configLTEnodecellname)=split(/\;/,$PICO2LTECELLRELATIONS[$ltearrayposition]);
    $configLTEnodename=$configLTEnodecellname;
    $configPICOnodename=$configPICOnodecellname;
    $configLTEnodename=~s/\-.*//;
    $configPICOnodename=~s/\-.*//;
    $configPICOnodename=~ s/^\s+|\s+$//g;
    $configLTEnodename=~ s/^\s+|\s+$//g;
    
    # check for duplication
    #if(!($prevconfigLTEnodename=~m/$configLTEnodename/)){$ltearrayposition++;next;}

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

    $moline="ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=$configLTEnodecellname,EUtranFreqRelation=1";
    $moline=~s/\n//;

   # build mo script
    @MOCmds=qq( CREATE
            (
            parent \"$moline\"
            identity $RELATIONID
            moType EUtranCellRelation
            exception none
            nrOfAttributes 3
            coverageIndicator Integer 2
            neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$configPICOnodename,ExternalEUtranCellFDD=$configPICOnodecellname
            );
            );# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds); 
    
    $ltearrayposition++;
    $RELATIONID++;
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
