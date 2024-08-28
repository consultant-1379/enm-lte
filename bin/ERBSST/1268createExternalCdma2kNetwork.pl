#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# version1    : LTE 12.0 ST Simulations
# purpose     : creates Cdma2000 external network
# description : as per reqs. in OSS 12.0 LTE16K TERE
# cdm         : 1/152 74-AOM 901 075 PA20
# date        : June 2011
# who         : epatdal
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
# Version5    : LTE 13B
# Revision    :
# Purpose     : Create an unique CDMA physical cell identity
# Description : update External CDMA proxy atrribute pnOffset
# Date        : Jan 2013
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 13B
# Revision    : 8
# Purpose     : Sprint/Feature 2.4 Cdma2k proxy and relation resize
# Description : updates total numbers for proxy and relations for
#               Cdma2K
# Date        : Feb 2013
# Who         : epatdal
####################################################################
###################################################################
# Version7    : LTE 14A.1
# Revision    : CXP 903 0491-40
# Purpose     : Cdma2K support for D125 & C174 MIM specific query for
#               new attribute Cdma2000FreqBand.cdmaBandClass
#               added post D125 & C174 MIMs
# Description : as above
# Date        : Dec 2013
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 14A
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
# Version9    : LTE 14A.1
# Revision    : CXP 903 0491-96-1
# Purpose     : Correct SNAD issue 15 seen in LTE network
# Description : The end of ExternalCdma2000Cell::cellGlobalIdHrpd
#		string should match
#	        ExternalCdma2000Cell::ExternalCdma2000CellId
# Date        : Oct 2014
# Who         : edalrey
####################################################################
####################################################################
# Version10   : LTE 14A.1
# Revision    : CXP 903 0491-97-1
# Purpose     : Correct SNAD issue 5 (& partly 13) seen in LTE network
# Description : Reset pnOffset count when externalcellid returns to 1
# Date        : Oct 2014
# Who         : edalrey
####################################################################
####################################################################
# Version11   : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version12   : LTE 15.16
# Revision    : CXP 903 0491-182-1
# Jira        : NSS-91
# Purpose     : hrpdBaseClass attribute deprecated for
#	        MIM versions >= G160
# Description : deprecate hrpdBaseClass attribute for
#               MIM versions >= G160
# Date        : Oct 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version13    : LTE 17A
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
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $TTLEXTERNALCDMA2KCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2KCELLS");
local $nodecountinteger;
local $nodecountfornodestringname;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3;
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
#########################
# MIM version support
#########################
local $MIMVERSION=&queryMIM($SIMNAME);
local $enableCdmaBandClassSupport=&isgreaterthanMIM($MIMVERSION,"D145");
local $cdmaBandClassSupport;
local $disableHrpdBandClass=&isgreaterthanMIM($MIMVERSION,"G160");
local $hrpdBandClassSupport;
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
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
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
while (($NODECOUNT<=$NUMOFRBS)&&($exceed==0)){

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

print "Creating Cdma2k External Cells for $LTENAME\n";

# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

################################
# start create Cdma2000 Network
################################
@MOCmds=();
@MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1"
       identity "1"
       moType Cdma2000Network
       exception none
       nrOfAttributes 2
       "Cdma2000NetworkId" String "1"
       "userLabel" String ""
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
 while ($countercdma2000freqband<=$totalcdma2000freqband){ # start while loopcounter cdma2000freqband
     @MOCmds=();

     # CXP 903 0491-40
     $cdmaBandClassSupport=($enableCdmaBandClassSupport eq "yes") ? "cdmaBandClass Integer $loopcounter2" : '';
     # CXP 903 0491-182-1
     $hrpdBandClassSupport=($disableHrpdBandClass eq "yes") ? '' : "hrpdBandClass Integer $loopcounter2";

      @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1"
       identity "$countercdma2000freqband"
       moType Cdma2000FreqBand
       exception none
       nrOfAttributes 3
       "Cdma2000FreqBandId" String "$countercdma2000freqband"
       $hrpdBandClassSupport
       $cdmaBandClassSupport
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
      parent "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqband"
      identity "$countercdma2000freq"
      moType Cdma2000Freq
      exception none
      nrOfAttributes 4
      "Cdma2000FreqId" String "$countercdma2000freq"
      "freqCdma" Integer $countercdma2000freq
      "reservedBy" Array Ref 0
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
          parent "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdma2000freqband,Cdma2000Freq=$countercdma2000freq"
          identity "$externalcellid"
          moType ExternalCdma2000Cell
          exception none
          nrOfAttributes 5
          "ExternalCdma2000CellId" String "$externalcellid"
          "cellGlobalIdHrpd" String "0000:0000:0000:0000:0000:0000:0000:$cellGlobalIdHrpd"
          "pnOffset" Integer $pnOffset
          "reservedBy" Array Ref 0
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
