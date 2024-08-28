#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16A
# Revision    : CXP 903 0491-151-1
# Jira        : OSS-77885
# Purpose     : Cdma2k1Rtt proxy and relation support
# Description : support for Cdma2k1xRtt external cells and cell relation
# Date        : May 2015
# Who         : xkamvat
####################################################################
####################################################################
# Version2    : LTE16A
# Revision    : CXP 903 0491-156-1
# Jira        : NETSUP-3065
# Purpose     : To sync DG2 Nodes on OSS
# Description : setting attributes cdma20001xRttFreqRelationId
#		cdma20001xRttBandRelationId
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version3    : LTE 15.16
# Revision    : CXP 903 0491-183-1
# Jira        : NSS-685
# Purpose     : set userLabel attribute
# Description : set userLabel attribute under ComTop:ManagedElement,
#               Lrat:ENodeBFunction=1,Lrat:EUtranCell
# Date        : Nov 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : LTE 17A
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
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}

# check isCdmaRtt Feature turned ON or OFF
if(&isCdma20001xRttYes=~/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $LTESIMSTART=&getENVfilevalue($ENV,"DG2SIMSTART");
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $TTLEXTERNALCDMA2K1xRTTCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2K1xRTTCELLS");
local $nodecountinteger;
local $nodecountfornodestringname;
local $tempcellid;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3,$loopcounter4;
local $EXTERNALCELLSPERNODE=30,$EXTERNALCELLSPERFREQBAND=8;
local @GeranFreqGroup;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $pnOffset=1,$MaxpnOffset=511;
local $totacdmfreqbandrelation=2,$countercdmfreqbandrelation=1;
local $totalcdmafreqband=2,$countercdmafreqband=1;
local $totalcdmafreq=2,$countercdmafreq=1;
local $exceed=0; # is 1 if total CDMA2K cells has been exceeded, 0 is not exceeded
local $cdmfreqbandrelationcellrelations=($EXTERNALCELLSPERNODE/2);# cells per freqbandrelation
local $countercdmfreqbandrelationcellrelations=1;
local $cellrelationid=1;
local $freqcounter;
local $tempcdmafreqband;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
################################
# MAIN
################################
print "... ${0} started running at $date\n";
################################

#------------------------------------------
# start determine External CDMA cell number
#------------------------------------------
# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

# check that externalcellid does not exceed TTLEXTERNALCDMA2K1xRTTCELLS
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2K1xRTTCELLS;

if($externalcellid>$TTLEXTERNALCDMA2K1xRTTCELLS){
   $exceed=1;
   print "INFO : CDMA2K cells $externalcellid exceeds required CDMA2K cells $TTLEXTERNALCDMA2K1xRTTCELLS\n";
}# end if
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------

while (($NODECOUNT<=$NUMOFRBS)&&($exceed==0)){

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

print "Creating Cdma2k1xRtt External Cell Relations for $LTENAME\n";

# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

@primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
$CELLNUM=@primarycells;

# check cell type
# checking one cell on the node in this instance and then assuming all other cells are the same
# this is a good assumption but would have been future proof to do per cell
# CXP 903 0491-135-1
if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
    #print "Creating Cdma2000 Cell Relations for $LTENAME FDD Cells...\n";
    $TYPE="EUtranCellFDD";
}# end if
else{
    #print "Creating Cdma2000 Cell Relations for $LTENAME TDD Cells...\n";
    $TYPE="EUtranCellTDD";
}# end else
########################################
# start create Cdma20001xRttBandRelation
########################################
$CELLCOUNT=1;$loopcounter=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $loopcounter=1;
 while ($loopcounter<3){ # start while loopcounter
 @MOCmds=();
 @MOCmds=qq^ CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT"
      identity "$loopcounter"
      moType Lrat:Cdma20001xRttBandRelation
      exception none
       nrOfAttributes 6
       "cdma20001xRttBandRelationId" String "$loopcounter"
       "cdma2000FreqBandRef" Ref "null"
       "cellReselectionPriority" Int32 4
       "threshXHigh1xRtt" Int32 63
       "threshXLow1xRtt" Int32 63
       "userLabel" String $LTENAME
      )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $loopcounter++;
 } # end while loopcounter
 $CELLCOUNT++;
}# end CELLCOUNT
#######################################
# end create Cdma20001xRttBandRelation
#######################################
########################################
# start create Cdma20001xRttFreqRelation
########################################
$CELLCOUNT=1;$loopcounter=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $loopcounter=1;
 while ($loopcounter<3){ # start while loopcounter
 @MOCmds=();
 @MOCmds=qq^ CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$loopcounter"
      identity "$loopcounter"
      moType Lrat:Cdma20001xRttFreqRelation
      exception none
      nrOfAttributes 6
       "cdma20001xRttFreqRelationId" String "$loopcounter"
       "cdma2000FreqRef" Ref "null"
       "csFallbackPrio" Int32 0
       "csFallbackPrioEC" Int32 0
       "qOffsetFreq" Int32 0
       "userLabel" String $LTENAME
      )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $loopcounter++;
 } # end while loopcounter
 $CELLCOUNT++;
}# end CELLCOUNT
#######################################
# end create Cdma20001xRttFreqRelation
#######################################
#######################################
# start create Cdma2001xRttCellRelation
#######################################
#-----------------------------------------------------------------------------
# DG2 16A
# CDMA2000CellRellation per cell = 30
# 15 relations per each FreqBandRelation
#-----------------------------------------------------------------------------
$CELLCOUNT=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT

  $countercdmfreqbandrelation=1;$cellrelationid=1;
  while ($countercdmfreqbandrelation<=$totacdmfreqbandrelation){

         $countercdmfreqbandrelationcellrelations=1;
         while ($countercdmfreqbandrelationcellrelations<=$cdmfreqbandrelationcellrelations){
              @MOCmds=();
              @MOCmds=qq^ CREATE
              (
              parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$countercdmfreqbandrelation,Lrat:Cdma20001xRttFreqRelation=$countercdmfreqbandrelation"
			  identity "$cellrelationid"
              moType Lrat:Cdma20001xRttCellRelation
              exception none
              nrOfAttributes 9
              "cdma20001xRttCellRelationId" String "$cellrelationid"
              "externalCdma20001xRttCellRef" Ref "null"
              "includeInSystemInformation" Boolean true
              "includeInSystemInformationRel9" Boolean false
              "userLabel" String $LTENAME
              )
              ^;# end @MO
             $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
             $countercdmfreqbandrelationcellrelations++;
             $cellrelationid++;
         }# end while cdmfreqbandrelationcellrelations

   $countercdmfreqbandrelation++;
  }# end while totacdmfreqbandrelation

 $CELLCOUNT++;
}# end CELLCOUNT
#######################################
# end create Cdma2001xRttCellRelation
########################################
#####################################
# start set Cdma20001xRttBandRelation
#####################################
$CELLCOUNT=1;$loopcounter=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $loopcounter=1;
 while ($loopcounter<3){ # start while loopcounter
 @MOCmds=();
 @MOCmds=qq^ SET
      (
     mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$loopcounter"
     exception none
     nrOfAttributes 1
    "cdma2000FreqBandRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$loopcounter"
      )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $loopcounter++;
 } # end while loopcounter
 $CELLCOUNT++;
}# end CELLCOUNT
#####################################
# end set Cdma20001xRttBandRelation
#####################################
#####################################
# start set ExternalCdma20001xRttCell
#####################################
#-----------------------------------------------------------------------------
# DG2 16A
# CDMA2000CellRellation per cell = 30
#-----------------------------------------------------------------------------
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2K1xRTTCELLS;

$totalexternalcellid=$EXTERNALCELLSPERNODE+$externalcellid;

$CELLCOUNT=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT

  $externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2K1xRTTCELLS;


       $countercdmafreqband=1;$cellrelationid=1;
       while ($countercdmafreqband<=$totalcdmafreqband){ # start while totalcdmafreqband

              $countercdmafreq=1;$freqcounter=1;
              while ($countercdmafreq<=$totalcdmafreq){ # start while totalcdmafreq

                     if($cellrelationid>$EXTERNALCELLSPERNODE){last;}
                     if ($externalcellid >= $totalexternalcellid){last;}

                     # determine external cell cdmafreq
                     if($freqcounter<=$EXTERNALCELLSPERFREQBAND){$countercdmafreq=1;}
                     if(($freqcounter>$EXTERNALCELLSPERFREQBAND)&&($freqcounter<=($EXTERNALCELLSPERFREQBAND*2))){
                        $countercdmafreq=2;}
                     if($freqcounter>($EXTERNALCELLSPERFREQBAND*2)){last;}

                     # determine relational cdmafreqband
                     if($cellrelationid<=$cdmfreqbandrelationcellrelations){$tempcdmafreqband=1;}
                        else{$tempcdmafreqband=2;}

                     @MOCmds=();
                     @MOCmds=qq^ SET
                     (
                      mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$tempcdmafreqband,Lrat:Cdma20001xRttFreqRelation=$tempcdmafreqband,Lrat:Cdma20001xRttCellRelation=$cellrelationid"
                     exception none
                     nrOfAttributes 1
                     "externalCdma20001xRttCellRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdmafreqband,Cdma2000Freq=$countercdmafreq,ExternalCdma20001xRttCell=$externalcellid"
                     )
                     ^;# end @MO

                     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

                     $cellrelationid++;$externalcellid++;
                     $freqcounter++;

                     if ($cellrelationid>$EXTERNALCELLSPERNODE){$cellrelationid=1;}

              }# end while totalcdmafreq

      $countercdmafreqband++;
      }# end while totalcdmafreqband

 $CELLCOUNT++;
}# end CELLCOUNT
######################################
# ExternalCdma20001xRttCell
#######################################
########################################
# start set Cdma20001xRttBandRelation
########################################
$loopcounter=1;$CELLCOUNT=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
       $loopcounter=1;
 while ($loopcounter<3){ # start while loopcounter
  $loopcounter2=1;
  @MOCmds=();
  @MOCmds=qq^ SET
      (
       mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$loopcounter,Lrat:Cdma20001xRttFreqRelation=$loopcounter"
        exception none
        nrOfAttributes 6
        "cdma20001xRttFreqRelationId" String "$loopcounter"
        "cdma2000FreqRef" Ref "null"
        "csFallbackPrio" Int32 0
        "csFallbackPrioEC" Int32 0
        "qOffsetFreq" Int32 0
        "userLabel" String $LTENAME
      )
    ^;# end @MO
  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  $loopcounter++;
 } # end while loopcounter
 $CELLCOUNT++;
}# end CELLCOUNT
######################################
# end set Cdma20001xRttBandRelation
######################################
#####################################
# start set cdma2000freqref
#####################################

$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2K1xRTTCELLS;$exceed=0;


$tempcellid=$externalcellid;
$CELLCOUNT=1;$loopcounter=1;$loopcounter2=1;$loopcounter3=1;
$TTLEXTCELLS=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $loopcounter=1;
  while ($loopcounter<=2){

  @MOCmds=();
  @MOCmds=qq^ SET
      (
   mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma20001xRttBandRelation=$loopcounter,Lrat:Cdma20001xRttFreqRelation=$loopcounter"
        exception none
        nrOfAttributes 1
     "cdma2000FreqRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$loopcounter,Cdma2000Freq=$loopcounter"
      )
    ^;# end @MO

  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  $loopcounter++;
  }# end while loopcounter
 $CELLCOUNT++;
}# end CELLCOUNT
####################################
# end set cdma2000freqref
#####################################

push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

###############################
# build MML script
################################
@MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
);# end @MMLCmds

$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

$NODECOUNT++;
}# end outer NODECOUNT while

#------------------------------------------
# start determine External CDMA cell number
#------------------------------------------

if($exceed==0){# start if exceed
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
}# end if exceed
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------

print "... ${0} ended running at $date\n";

################################
# END
################################
