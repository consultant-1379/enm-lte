#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-151-1
# Jira        : OSS-77951
# Purpose     : To create DG2ExternalCdma2kNetwork
# Description : Creates MOs Cdma2000Network, Cdma2000FreqBand,
#               Cdma2000Freq & ExternalCdma2000Cell
#               sets Cdma2000CellRelation moref
# Date        : May 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 15.16
# Revision    : CXP 903 0491-182-1
# Jira        : NSS-91
# Purpose     : hrpdBaseClass attribute deprecated for MIM versions
#               >= MRRBS-16A-V2
# Description : deprecate hrpdBaseClass attribute for MIM versions
#               >= MRRBS-16A-V2
# Date        : Oct 2015
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
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $DG2NUMOFNODESPERSIM=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $TTLEXTERNALCDMA2KCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2KCELLS");
local $nodecountinteger;
local $nodecountfornodestringname;

local $externalcellid,$loopcounter,$loopcounter2;
local $totalexternalcellid;
local $EXTERNALCELLSPERNODE=2;
local $TTLEXTCELLS=1;
local $TTLEXTERNALCDMACELLS=$TTLEXTERNALCDMA2KCELLS;
local $cellGlobalIdHrpd;
local $pnOffset=1,$MaxpnOffset=511;
local $totalcdma2000freqband=1,$countercdma2000freqband=1;
local $totalcdma2000freq=1,$countercdma2000freq=1;
local $exceed=0; # is 1 if total CDMA2K cells has been exceeded, 0 is not exceeded
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
$pnOffset=1;
#------------------------------------------
# start determine External CDMA cell number
#------------------------------------------
# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFNODESPERSIM);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$DG2NUMOFNODESPERSIM){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFNODESPERSIM)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

# check that externalcellid does not exceed TTLEXTERNALCDMA2KCELLS
$externalcellid=($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1);

#---------------------------------------------------------------------------------
# start spread external cells throughout the entire network
#---------------------------------------------------------------------------------
# ensure $TTLEXTERNALCDMA2KCELLS are spread throughout the entire LTE network
# by resetting $externalcellid=1 each time $externalcellid>$TTLEXTERNALCDMA2KCELLS
if($externalcellid>$TTLEXTERNALCDMA2KCELLS){$externalcellid=1;}
#---------------------------------------------------------------------------------
# end spread external cells throughout the entire network
#---------------------------------------------------------------------------------

if($externalcellid>$TTLEXTERNALCDMA2KCELLS){
   $exceed=1;
   print "INFO : CDMA2K cells $externalcellid exceeds required CDMA2K cells $TTLEXTERNALCDMA2KCELLS\n";
}# end if

#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------
while (($NODECOUNT<=$DG2NUMOFNODESPERSIM)&&($exceed==0)){
    ##########################
    # MIM version support
    ##########################
    local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
    local $disableHrpdBandClass=&isgreaterthanMIM($MIMVERSION,"16A-V2");
    local $hrpdBandClassSupport;

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

print "Creating Cdma2k External Cells for $LTENAME\n";

# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFNODESPERSIM);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$DG2NUMOFNODESPERSIM){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFNODESPERSIM)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

################################
# start create Cdma2000 Network
################################
@MOCmds=();
@MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1"
       identity "1"
       moType Lrat:Cdma2000Network
       exception none
       nrOfAttributes 1
       "cdma2000NetworkId" String "1"
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("write",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end create Cdma2000 Network
################################
#####################################
# start create Cdma2000Freq  Network
#####################################
 $countercdma2000freqband=1;$loopcounter2=0;
 while ($countercdma2000freqband<=$totalcdma2000freqband){ # start while countercdma2000freqband

 # CXP 903 0491-182-1
 $hrpdBandClassSupport=($disableHrpdBandClass eq "yes") ? '' : "hrpdBandClass Integer $loopcounter2";

 @MOCmds=();
 @MOCmds=qq^ CREATE
      (
       parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:Cdma2000Network=1"
       identity "$countercdma2000freqband"
       moType Lrat:Cdma2000FreqBand
       exception none
       nrOfAttributes 3
       "cdma2000FreqBandId" String "$countercdma2000freqband"
       $hrpdBandClassSupport
       "cdmaBandClass" Integer $loopcounter2
      )
    ^;# end @MO

 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 $countercdma2000freqband++;$loopcounter2++;
 } # end while countercdma2000freqband
#####################################
# end create Cdma2000Freq Network
#####################################
#####################################
# start create Cdma2000FreqBand
#####################################
 $countercdma2000freqband=1;
 while ($countercdma2000freqband<=$totalcdma2000freqband){ # start while countercdma2000freqband
  $countercdma2000freq=1;
  while ($countercdma2000freq<=$totalcdma2000freq){ # start while countercdma2000freq
  @MOCmds=();
  @MOCmds=qq^ CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:Cdma2000Network=1,Lrat:Cdma2000FreqBand=$countercdma2000freqband"
      identity "$countercdma2000freq"
      moType Lrat:Cdma2000Freq
      exception none
      nrOfAttributes 2
      "cdma2000FreqId" String "$countercdma2000freq"
      "freqCdma" Int32 $loopcounter2
      )
    ^;# end @MO
  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  $countercdma2000freq++;
  } # end while countercdma2000freq
  $countercdma2000freqband++;
 } # end while countercdma2000freqband
#####################################
# end create Cdma2000FreqBand
#####################################
#####################################
# start create ExternalCdma2000Cell
#####################################
#-----------------------------------------------------------------------------
# LTE 13B
# CDMA2000CellRellation per cell = 8
# 4 relations per each FreqBandRelation, changed from 16 per FreqBandRelation
# External Cdma2K cells = 8 per node
#
# ensure to spread external cells throughout the entire network
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# LTE 17A
# CDMA2000CellRellation per cell = 2
# 1 relations per each FreqBandRelation, changed from 8 per FreqBandRelation
# External Cdma2K cells = 2 per node
#-----------------------------------------------------------------------------
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2KCELLS;
# CXP 903 0491-97-1 : SNAD issue 5/13
if($externalcellid==1){$pnOffset=1;}

$totalexternalcellid=$EXTERNALCELLSPERNODE+$externalcellid;

while ($externalcellid < $totalexternalcellid){

  $countercdma2000freqband=1;
  while ($countercdma2000freqband<=$totalcdma2000freqband){ # start while totalcdmafreqband

    $countercdma2000freq=1;$freqcounter=1;
    while ($countercdma2000freq<=$totalcdma2000freq){ # start while totalcdmafreq

         # CXP 903 0491-96-1 : SNAD issue 15
         $cellGlobalIdHrpd = sprintf("%u",$externalcellid);

         @MOCmds=();
         @MOCmds=qq^ CREATE
         (
          parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:Cdma2000Network=1,Lrat:Cdma2000FreqBand=$countercdma2000freqband,Lrat:Cdma2000Freq=$countercdma2000freq"
          identity "$externalcellid"
          moType Lrat:ExternalCdma2000Cell
          exception none
          nrOfAttributes 3
	  "externalCdma2000CellId" String "$externalcellid"
          "cellGlobalIdHrpd" String "0000:0000:0000:0000:0000:0000:0000:$cellGlobalIdHrpd"
          "pnOffset" Int32 $pnOffset
         )
         ^;# end @MO

         # check cell id
         $pnOffset++;
         if($pnOffset>$MaxpnOffset){$pnOffset=1;}

         $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

         $externalcellid++;$freqcounter++;
         $countercdma2000freq++;

         if($freqcounter==2){$countercdma2000freq=1;}# maintain sequential extercellids per cdmafreq
         if($freqcounter==4){$countercdma2000freq=2;}# maintain sequential extercellids per cdmafreq
      }# end while totalcdma2000freq

  $countercdma2000freqband++;
  }# end while totalcdma2000freqband

} # end outer totalexternalcellid
#####################################
# end create ExternalCdma2000Cell
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

