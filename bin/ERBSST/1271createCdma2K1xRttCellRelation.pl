#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : LTE 13B
# Revision    :
# Purpose     : Sprint 0.5 - Cell Reselection Priority
# Description : reset freq band cellReselectionPriority attribute
#               in accordance with below assignment ruleset :
#               GSM = 1
#               CDMA2000 = 2
#               UMTS = 3
#               CDMA2001 x rtt = 4
#               LTE = 5
# Date        : Jan 2013
# Who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 13B
# Revision    : 9
# Purpose     : Sprint/Feature 1.1 Cdma2k1Rtt proxy and relation support
# Description : support for Cdma2k1xRtt external cells and cell relations
# Date        : Feb 2013
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 14A
# Revision    : CXP 903 0491-42-19
# Jira        : NETSUP-1019
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Jan 2014
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 15B
# Revision    : CXP 903 0491-135-1
# Jira        : NETSUP-2748
# Purpose     : resolves an issue where TDD cells are represented
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Description : ensure TDD and FDD cells are not represented
#               incorrectly
# Date        : Mar 2015
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 17A
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
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# check isCdmaRtt Feature turned ON or OFF
if(&isCdma20001xRttYes=~/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $TTLEXTERNALCDMA2K1xRTTCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2K1xRTTCELLS");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $element,$secequipnum;
local $nodenum,$freqgroup,$fregroup2,fregroup3;
local $EXTERNALCDMA2000CELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
local $tempcellid;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3,$loopcounter4;
local $EXTERNALCELLSPERNODE=30,$EXTERNALCELLSPERFREQBAND=8;
local $TTLEXTERNALCDMACELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
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
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMCdma2K1xRttSupport="D1120";
local $mimsupport=&isgreaterthanMIM($MIMVERSION,$MIMCdma2K1xRttSupport);
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

# check if Cdma2K1xRtt is supported in MIM
if( $mimsupport eq "yes"){}
   else { print "INFO : CDMA2K1xRtt cells are not supported in $MIMVERSION only $MIMCdma2K1xRttSupport onwards\n";
          $exceed=1;}

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
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
      identity "$loopcounter"
      moType Cdma20001xRttBandRelation
      exception none
       nrOfAttributes 6
       "Cdma20001xRttBandRelationId" String ""
       "cdma2000FreqBandRef" Ref "null"
       "cellReselectionPriority" Integer 4
       "threshXHigh1xRtt" Integer 63
       "threshXLow1xRtt" Integer 63
       "userLabel" String ""
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
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$loopcounter"
      identity "$loopcounter"
      moType Cdma20001xRttFreqRelation
      exception none
      nrOfAttributes 6
       "Cdma20001xRttFreqRelationId" String ""
       "cdma2000FreqRef" Ref "null"
       "csFallbackPrio" Integer 0
       "csFallbackPrioEC" Integer 0
       "qOffsetFreq" Integer 0
       "userLabel" String ""
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
# LTE 13B
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
              parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$countercdmfreqbandrelation,Cdma20001xRttFreqRelation=$countercdmfreqbandrelation"
    identity "$cellrelationid"
              moType Cdma20001xRttCellRelation
              exception none
              nrOfAttributes 9
              "Cdma20001xRttCellRelationId" String "$cellrelationid"
              "externalCdma20001xRttCellRef" Ref "null"
              "includeInSystemInformation" Boolean true
              "includeInSystemInformationRel9" Boolean false
              "pmHoPrepAttCsfb" Integer 0
              "pmHoPrepAttCsfbEm" Integer 0
              "pmHoPrepSuccCsfb" Integer 0
              "pmHoPrepSuccCsfbEm" Integer 0
              "userLabel" String ""
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
     mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$loopcounter"
     exception none
     nrOfAttributes 1
    "cdma2000FreqBandRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$loopcounter"
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
# LTE 13B
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
                      mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$tempcdmafreqband,Cdma20001xRttFreqRelation=$tempcdmafreqband,Cdma20001xRttCellRelation=$cellrelationid"
                     exception none
                     nrOfAttributes 1
                     "externalCdma20001xRttCellRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdmafreqband,Cdma2000Freq=$countercdmafreq,ExternalCdma20001xRttCell=$externalcellid"
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
       mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$loopcounter,Cdma20001xRttFreqRelation=$loopcounter"
        exception none
        nrOfAttributes 6
        "Cdma20001xRttFreqRelationId" String ""
        "cdma2000FreqRef" Ref "null"
        "csFallbackPrio" Integer 0
        "csFallbackPrioEC" Integer 0
        "qOffsetFreq" Integer 0
        "userLabel" String ""
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
   mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma20001xRttBandRelation=$loopcounter,Cdma20001xRttFreqRelation=$loopcounter"
        exception none
        nrOfAttributes 1
     "cdma2000FreqRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$loopcounter,Cdma2000Freq=$loopcounter"
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
