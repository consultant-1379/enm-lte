#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-151-1
# Jira        : To create Cdma 2k cellrelations
# Description : Creates Cdma2000FreqBandRelation MO, Cdma2000CellRelation
#               MO, sets Cdma2000FreqBandRelation moref &
#               sets Cdma2000CellRelation moref
# Date        : May 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 15.16
# Revision    : CXP 903 0491-183-1
# Jira        : NSS-685
# Purpose     : set userLabel attribute
# Description : set userLabel attribute under ComTop:ManagedElement,
#               Lrat:ENodeBFunction=1,Lrat:EUtranCell
# Date        : Nov 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version3    : LTE 17A
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

# check if SIMNAME is of type PICO or CPP
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
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
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $TTLEXTERNALCDMA2KCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2KCELLS");
local $nodecountinteger;
local $nodecountfornodestringname;
local $tempcellid;
local $externalcellid,$loopcounter,$loopcounter2;
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
    $TYPE="Lrat:EUtranCellFDD";
}# end if
else{
    $TYPE="Lrat:EUtranCellTDD";
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
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
      identity "$countercdma2000freqbandrelation"
      moType Lrat:Cdma2000FreqBandRelation
      exception none
      nrOfAttributes 6
      "cdma2000FreqBandRelationId" String "$countercdma2000freqbandrelation"
      "cdma2000FreqBandRef" Ref "null"
      "cellReselectionPriority" Int32 2
      "threshXHighHrpd" Int32 63
      "threshXLowHrpd" Int32 63
      "userLabel" String $LTENAME
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
              parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
              identity "$cellrelationid"
              moType Lrat:Cdma2000CellRelation
              exception none
              nrOfAttributes 4
             "cdma2000CellRelationId" String "$cellrelationid"
             "externalCdma2000CellRef" Ref "null"
             "includeInSystemInformation" Boolean true
             "userLabel" String $LTENAME
              )
              ^;# end @MO
             $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
             $countercdma2000freqbandrelationcellrelations++;
             $cellrelationid++;
         }# end while countercdma2000freqbandrelationcellrelations

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
     mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
     exception none
     nrOfAttributes 1
    "cdma2000FreqBandRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation"
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
                      mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma2000FreqBandRelation=$countercdma2000freqbandrelation,Lrat:Cdma2000CellRelation=$cellrelationid"
                     exception none
                     nrOfAttributes 1
                     "externalCdma2000CellRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation,Cdma2000Freq=$countercdma2000freq,ExternalCdma2000Cell=$externalcellid"
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
       parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma2000FreqBandRelation=$countercdma2000freqbandrelation"
       identity "$countercdma2000freqrelation"
       moType Lrat:Cdma2000FreqRelation
       exception none
       nrOfAttributes 5
      "cdma2000FreqRelationId" String "$countercdma2000freqrelation"
      "cdma2000FreqRef" Ref "null"
       "connectedModeMobilityPrio" Int32 6
      "qOffsetFreq" Int32 0
      "userLabel" String $LTENAME
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
   mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:Cdma2000FreqBandRelation=$countercdma2000freqbandrelation,Lrat:Cdma2000FreqRelation=$countercdma2000freqrelation"
        exception none
        nrOfAttributes 1
"cdma2000FreqRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqbandrelation,Cdma2000Freq=$countercdma2000freqrelation"
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

