#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : sets PICO Cdma2000FreqRelation
# Description : creates support for the creation of PICO2CDMA2K
#               and PICOCDMA2KRtt
# Jira        : NETSUP-1019
# Date        : Feb 2014
# Who         : ecasjim
####################################################################
# Version2    : LTE 17A
# Revision    : CXP 903 0491-238-1
# Jira        : NSS-1954
# Purpose     : To reduce number of cdma2000 and cdma200001 relations
#               and proxies
# Description : As per the Generic NRM the cdma2000 cdma20001Rtt
#               relations and proxies are higher, So reducing cdma2000
#               relations and proxies and turnning off the feature of
#               cdma20001Rtt
# Date        : July 2016
# Who         : xsrilek
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

# check isCdma2000 Feature turned ON or OFF
if(&isCdma2000Yes=~/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $Cdmanetwork="Cdma2000Network";
local $currCdma2000Freq=1;
local $totalCdma2000Freq=1;
local $Cdma2000FreqBandRelation="Cdma2000FreqBandRelation";
local $currCdma2000FreqBandRelation=1;
local $totalCdma2000FreqBandRelation=1;
local $cellcount=1;

local $extCdmaFreqPath="ENodeBFunction=1,Cdma2000Network=1";
local $cdma2000FreqRef="cdma2000FreqRef";

local $Cdma2000FreqBand="Cdma2000FreqBand";
local $Cdma2000FreqRelation="Cdma2000FreqRelation";
local $Cdma2000Freq="Cdma2000Freq";

while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    #####################################
    # start set PICO externalCdma2000FreqRef
    #####################################
      $currCdma2000FreqBandRelation=1;

      while ($currCdma2000FreqBandRelation<=$totalCdma2000FreqBandRelation){# start Cdma2000FreqBandRelation
          $currCdma2000Freq=1;
	  while ($currCdma2000Freq<=$totalCdma2000Freq){# start Cdma2000Freq
        $mmlstring="setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtranCellFDD=$LTENAME-$cellcount,$Cdma2000FreqBandRelation=$currCdma2000FreqBandRelation,$Cdma2000FreqRelation=$currCdma2000Freq\",
attributes=\"$cdma2000FreqRef (moRef)=ManagedElement=$LTENAME,$extCdmaFreqPath,$Cdma2000FreqBand=$currCdma2000FreqBandRelation,$Cdma2000Freq=$currCdma2000Freq\";";

        $mmlstring=~s/^\s+|\s+$//g;$mmlstring=~s/\n//;

        # build mml script
        @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
          $mmlstring
        );# end @MMLCmds
             $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

             $currCdma2000Freq++;
	     }# end while Cdma2000Freq
             $currCdma2000FreqBandRelation++;
      }# end while Cdma2000FreqBandRelation

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
