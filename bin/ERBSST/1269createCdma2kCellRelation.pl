#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# verion1     : LTE 12.0 ST Simulations
# purpose     : creates Cdma2000 cell relations
# description : as per reqs. in OSS 12.0 LTE16K TERE
# cdm         : 1/152 74-AOM 901 075 PA20
# date        : June 2011
# who         : epatdal
# Updated     : Nov 2011 - included 12.0 patches
####################################################################
####################################################################
# Version2    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 3 Fix
# Description : Corrected looping mechanism for the ExternalCdma2000 Cells.
# Date        : Mar 2012
# Who         : qgormor
####################################################################
####################################################################
# Version4    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version5    : LTE 13A
# Purpose     : Support for 12 cell node
# Description : ensure cdma support for 12 cell node
# Date        : Aug 2012
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version7    : LTE 13B
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
# Version8    : LTE 13B
# Purpose     : Sprint/Feature 2.4 Cdma2k proxy and relation resize
# Description : updates total numbers for proxy and relations for
#               Cdma2K
# Date        : Feb 2013
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 14A
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
# Version10   : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 15B
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
# Version12    : LTE 17A
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

# check isCdma2000 Feature turned ON or OFF
if(&isCdma2000Yes=~/NO/){exit;}
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
local $CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $TTLEXTERNALCDMA2KCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2KCELLS");
local $nodecountinteger;
local $nodecountfornodestringname;
local $tempcellid;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3;
local $EXTERNALCELLSPERNODE=2;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $totalcdma2000freqbandrelation=1,$countercdma2000freqbandrelation=1;
local $totalcdma2000freq=1,$countercdma2000freq=1;
local $totalcdma2000freqrelation=1,$countercdma2000freqrelation=1;
local $exceed=0; # is 1 if total CDMA2K cells has been exceeded, 0 is not exceeded
local $cdma2000freqbandrelationcellrelations=$EXTERNALCELLSPERNODE;# cells per freqbandrelation
local $countercdma2000freqbandrelationcellrelations=1;
local $cellrelationid=1;
local $freqcounter;
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

# check that externalcellid does not exceed TTLEXTERNALCDMA2KCELLS
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2KCELLS;

if($externalcellid>$TTLEXTERNALCDMA2KCELLS){
   $exceed=1;
   print "INFO : CDMA2K cells $externalcellid exceeds required CDMA2K cells $TTLEXTERNALCDMA2KCELLS\n";
}# end if
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------

while(($NODECOUNT<=$NUMOFRBS)&&($exceed==0)){

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

print "Creating Cdma2k External Cells Relations for $LTENAME\n";

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
    print "Creating Cdma2000 Cell Relations for $LTENAME FDD Cells...\n";
    $TYPE="EUtranCellFDD";
}# end if
else{
    print "Creating Cdma2000 Cell Relations for $LTENAME TDD Cells...\n";
    $TYPE="EUtranCellTDD";
}# end else
#######################################
# start create Cdma2000FreqBandRelation
#######################################
$CELLCOUNT=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $countercdma2000freqbandrelation=1;
 while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){ # start while countercdma2000freqbandrelation
 @MOCmds=();
 @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
      identity "$countercdma2000freqbandrelation"
      moType Cdma2000FreqBandRelation
      exception none
      nrOfAttributes 6
      "Cdma2000FreqBandRelationId" String "$countercdma2000freqbandrelation"
      "cdma2000FreqBandRef" Ref "null"
      "cellReselectionPriority" Integer 2
      "threshXHighHrpd" Integer 63
      "threshXLowHrpd" Integer 63
      )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $countercdma2000freqbandrelation++;
 } # end while countercdma2000freqbandrelation
 $CELLCOUNT++;
}# end CELLCOUNT
#####################################
# end create Cdma2000FreqBandRelation
#####################################
#####################################
# start create Cdma2000CellRelation
#####################################
#-----------------------------------------------------------------------------
# LTE 13B
# CDMA2000CellRellation per cell = 8
# 4 relations per each FreqBandRelation, changed from 16 per FreqBandRelation
# External Cdma2K cells = 8 per node
#-----------------------------------------------------------------------------
$CELLCOUNT=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT

  $countercdma2000freqbandrelation=1;$cellrelationid=1;
  while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){

         $countercdma2000freqbandrelationcellrelations=1;
         while ($countercdma2000freqbandrelationcellrelations<=$cdma2000freqbandrelationcellrelations){
              @MOCmds=();
              @MOCmds=qq^ CREATE
              (
              parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
              identity "$cellrelationid"
              moType Cdma2000CellRelation
              exception none
              nrOfAttributes 4
             "Cdma2000CellRelationId" String "$cellrelationid"
             "externalCdma2000CellRef" Ref "null"
             "includeInSystemInformation" Boolean true
              )
              ^;# end @MO
             $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
             $countercdma2000freqbandrelationcellrelations++;
             $cellrelationid++;
         }# end while cdma2000freqbandrelationcellrelations

   $countercdma2000freqbandrelation++;
  }# end while totalcdma2000freqbandrelation

 $CELLCOUNT++;
}# end CELLCOUNT
#####################################
# end create Cdma2000CellRelation
#####################################
#####################################
# start set Cdma2000FreqBandRelation
#####################################
$CELLCOUNT=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $countercdma2000freqbandrelation=1;
 while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){ # start while countercdma2000freqbandrelation
 @MOCmds=();
 @MOCmds=qq^ SET
      (
     mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
     exception none
     nrOfAttributes 1
    "cdma2000FreqBandRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation"
      )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $countercdma2000freqbandrelation++;
 } # end while countercdma2000freqbandrelation
 $CELLCOUNT++;
}# end CELLCOUNT
#####################################
# end set Cdma2000FreqBandRelation
#####################################
#####################################
# start set Cdma2000CellRelation
#####################################
#-----------------------------------------------------------------------------
# LTE 13B
# CDMA2000CellRellation per cell = 8
# 4 relations per each FreqBandRelation, changed from 16 per FreqBandRelation
# External Cdma2K cells = 8 per node
#-----------------------------------------------------------------------------
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2KCELLS;


$totalexternalcellid=$EXTERNALCELLSPERNODE+$externalcellid;

$CELLCOUNT=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT

  $externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2KCELLS;

  $countercdma2000freqbandrelation=1;$cellrelationid=1;
       while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){ # start while countercdma2000freqbandrelation

              $countercdma2000freq=1;$freqcounter=1;
              while ($countercdma2000freq<=$totalcdma2000freq){ # start while totalcdma2000freq

                     @MOCmds=();
                     @MOCmds=qq^ SET
                     (
                      mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma2000FreqBandRelation=$countercdma2000freqbandrelation,Cdma2000CellRelation=$cellrelationid"
                     exception none
                     nrOfAttributes 1
                     "externalCdma2000CellRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation,Cdma2000Freq=$countercdma2000freq,ExternalCdma2000Cell=$externalcellid"
                     )
                     ^;# end @MO

                     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

               $cellrelationid++;$externalcellid++;
               $countercdma2000freq++;$freqcounter++;

               if ($cellrelationid>$EXTERNALCELLSPERNODE){$cellrelationid=1;}

               # check extercellidrange
               if($externalcellid>=$totalexternalcellid){$externalcellid=($externalcellid-$EXTERNALCELLSPERNODE)};

               if($freqcounter==2){$countercdma2000freq=1;}# maintain sequential extercellids per cdmafreq
               if($freqcounter==4){$countercdma2000freq=2;}# maintain sequential extercellids per cdmafreq

              }# end while totalcdma2000freq

      $countercdma2000freqbandrelation++;
      }# end while totalcdma2000freqbandrelation

 $CELLCOUNT++;
}# end CELLCOUNT
###################################n
# end set Cdma2000CellRelation
#####################################
#####################################
# start create Cdma2000FreqRelation
#####################################
$CELLCOUNT=1;
while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
       $countercdma2000freqbandrelation=1;
 while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){ # start while countercdma2000freqbandrelation
  $countercdma2000freqrelation=1;
  while ($countercdma2000freqrelation<=$totalcdma2000freqrelation){ # start while countercdma2000freqrelation
  @MOCmds=();
  @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
       identity "$countercdma2000freqrelation"
       moType Cdma2000FreqRelation
       exception none
       nrOfAttributes 5
      "Cdma2000FreqRelationId" String "$countercdma2000freqrelation"
      "cdma2000FreqRef" Ref "null"
       "connectedModeMobilityPrio" Integer 6
      "qOffsetFreq" Integer 0
      )
    ^;# end @MO
  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  $countercdma2000freqrelation++;
  } # end while countercdma2000freqrelation
  $countercdma2000freqbandrelation++;
 } # end while countercdma2000freqbandrelation
 $CELLCOUNT++;
}# end CELLCOUNT
#####################################
# end create Cdma2000FreqRelation
#####################################
#####################################
# start set cdma2000freqref
#####################################

$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2KCELLS;$exceed=0;

$tempcellid=$externalcellid;
$CELLCOUNT=1;
$TTLEXTCELLS=1;

while ($CELLCOUNT<=$CELLNUM){ # start CELLCOUNT
 $countercdma2000freqbandrelation=1;
  while ($countercdma2000freqbandrelation<=$totalcdma2000freqbandrelation){
  $countercdma2000freqrelation=1;
  while ($countercdma2000freqrelation<=$totalcdma2000freqrelation){
  @MOCmds=();
  @MOCmds=qq^ SET
      (
   mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Cdma2000FreqBandRelation=$countercdma2000freqbandrelation,Cdma2000FreqRelation=$countercdma2000freqrelation"
        exception none
        nrOfAttributes 1
"cdma2000FreqRef" Ref "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation,Cdma2000Freq=$countercdma2000freqrelation"
      )
    ^;# end @MO
  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  $countercdma2000freqrelation++;
  }# end while countercdma2000freqrelation
  $countercdma2000freqbandrelation++;
  }# end while countercdma2000freqbandrelation
 $CELLCOUNT++;
}# end CELLCOUNT
###################################n
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
