#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16A
# Revision    : CXP 903 0491-151-1
# Jira        : OSS-77885
# Purpose     : Cdma2k1Rtt proxy and relation support
# Description : support for Cdma2k1xRtt external cells and cell relations
# Date        : May 2015
# Who         : xkamvat
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
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM");
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $TTLEXTERNALCDMA2K1xRTTCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2K1xRTTCELLS");
local $LTESIMSTART=&getENVfilevalue($ENV,"DG2SIMSTART");
local $nodecountfornodestringname;
local $nodecountinteger;
local $externalcellid;
local $totalexternalcellid;
local $EXTERNALCELLSPERNODE=30,$EXTERNALCELLSPERFREQBAND=8;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $cellGlobalIdHrpd;
local $pnOffset=1,$MaxpnOffset=511;
local $totacdmfreqbandrelation=2,$countercdmfreqbandrelation=1;
local $totalcdmafreqband=2,$countercdmafreqband=1;
local $totalcdmafreq=2,$countercdmafreq=1;
local $exceed=0; # is 1 if total CDMA2K1Rtt cells has been exceeded, 0 is not exceeded
local $freqcounter;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JIRA NETSUP-804 MOM cardinality update to cellid and sectorNumber
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local $MAXcellIdentifiercellid=4095;
local $MAXcellIdentifiersectorNumber=15;
local $cellIdentifiercellid=1;
local $cellIdentifiersectorNumber=0;
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
$externalcellid=($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1);

#---------------------------------------------------------------------------------
# start spread external cells throughout the entire network
#---------------------------------------------------------------------------------
# ensure $TTLEXTERNALCDMA2K1xRTTCELLS are spread throughout the entire DG2 network
# by resetting $externalcellid=1 each time $externalcellid>$TTLEXTERNALCDMA2K1xRTTCELLS
if($externalcellid>$TTLEXTERNALCDMA2K1xRTTCELLS){$externalcellid=1;}
#---------------------------------------------------------------------------------
# end spread external cells throughout the entire network
#---------------------------------------------------------------------------------

if($externalcellid>$TTLEXTERNALCDMA2K1xRTTCELLS){
   $exceed=1;
   print "INFO : CDMA2K1xRtt cells $externalcellid exceeds required CDMA2K1xRtt cells $TTLEXTERNALCDMA2K1xRTTCELLS\n";
}# end if
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------

while (($NODECOUNT<=$NUMOFRBS)&&($exceed==0)){

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

print "Creating Cdma2k1xRtt External Cells for $LTENAME\n";

# get node primary cells
$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

@primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
$CELLNUM=@primarycells;

########################################
# start create ExternalCdma20001xRttCell
########################################
#-----------------------------------------------------------------------------
# DG2 16A
# CDMA20001xRttCellRellation per cell = 30
#-----------------------------------------------------------------------------
$externalcellid=(($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1))%$TTLEXTERNALCDMA2K1xRTTCELLS;

# CXP 903 0491-110-1 : SNAD issue 5/13
if($externalcellid==1){$pnOffset=1;}

$totalexternalcellid=$EXTERNALCELLSPERNODE+$externalcellid;

while ($externalcellid < $totalexternalcellid){

  $countercdmafreqband=1;
  while ($countercdmafreqband<=$totalcdmafreqband){ # start while totalcdmafreqband

    $countercdmafreq=1;$freqcounter=1;
    while ($countercdmafreq<=$totalcdmafreq){ # start while totalcdmafreq

         $cellGlobalIdHrpd = sprintf("%x",$externalcellid);

	 # 20 here specifies the number of Access Networks that we spread our external cells across.
	 # This is a candidate for being a variable in the config file except most users won't care
	 $switchnumber = $externalcellid%20;

         # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         # START : determine  $cellIdentifiercellid + $cellIdentifiersectorNumber
         # JIRA NETSUP-804 MOM cardinality update to cellid and sectorNumber
         # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

         if(($externalcellid>$MAXcellIdentifiercellid)){
            $cellIdentifiersectorNumber=$externalcellid/$MAXcellIdentifiercellid;
            $cellIdentifiersectorNumber= int($cellIdentifiersectorNumber);
            $cellIdentifiercellid=$externalcellid%$MAXcellIdentifiercellid+1;
         }# end if

        if($externalcellid<=$MAXcellIdentifiercellid){
           $cellIdentifiersectorNumber=0;
           $cellIdentifiercellid=$externalcellid;}

        if($cellIdentifiersectorNumber>15){
          $cellIdentifiersectorNumber=1;
        }# end if

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # END : determine  $cellIdentifiercellid + $cellIdentifiersectorNumber
        # JIRA NETSUP-804 MOM cardinality update to cellid and sectorNumber
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

         @MOCmds=();
	 @MOCmds=qq^ CREATE
         (
          parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:Cdma2000Network=1,Lrat:Cdma2000FreqBand=$countercdmafreqband,Lrat:Cdma2000Freq=$countercdmafreq"
          identity "$externalcellid"
          moType Lrat:ExternalCdma20001xRttCell
          exception none
          nrOfAttributes 9
          "externalCdma20001xRttCellId" String "$externalcellid"
          "acBarring1xRttForMoDataPresent" Boolean false

          "cellIdentifier" Struct
           nrOfElements 2
           "cellId" Int32 $cellIdentifiercellid
           "sectorNumber" Int32 $cellIdentifiersectorNumber

          "mscIdentifier" Struct
            nrOfElements 2
            "marketId" Int32 0
            "switchNumber" Int32 $switchnumber

          "nid" Int32 1
          "pnOffset" Int32 $pnOffset
          "reservedBy" Array Ref 0
          "sid" Int32 1
           "userLabel" String $LTENAME
         )
         ^;# end @MO

         # check cell id
         $pnOffset++;
         if($pnOffset>$MaxpnOffset){$pnOffset=1;}

         $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

         $externalcellid++;$freqcounter++;
         $countercdmafreq++;

         if($freqcounter<=$EXTERNALCELLSPERFREQBAND){$countercdmafreq=1;}# maintain sequential extercellids per cdmafreq
         if(($freqcounter>$EXTERNALCELLSPERFREQBAND)&&($freqcounter<=($EXTERNALCELLSPERFREQBAND*2))){
                    $countercdmafreq=2;}# maintain sequential extercellids per cdmafreq

         if ($externalcellid >= $totalexternalcellid){last;}

      }# end while totalcdmafreq

  $countercdmafreqband++;
  }# end while totalcdmafreqband

} # end outer totalexternalcellid
#####################################
# end create ExternalCdma20001ixRttCell
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
