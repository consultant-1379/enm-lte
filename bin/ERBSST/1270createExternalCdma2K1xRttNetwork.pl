#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 13B
# Revision    : 9
# Purpose     : Sprint/Feature 1.1 Cdma2k1Rtt proxy and relation support
# Description : support for Cdma2k1xRtt external cells and cell relations
# Date        : Feb 2013
# Who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 13B
# Purpose     : Bugfix: too many Access Networks
# Description : nid, sid and mscIdentifier identify the AN of a cell
#		were setting nid and sid =externalcellid so we had one
#		AN per cell, altering to have 20 ANs network wide
# Date        : May 2013
# Who         : lmieody
####################################################################
####################################################################
# Version3    : LTE 13B
# Purpose     : Bugfix: cellId should be equal to $externalcellid
# Date        : Jun 2013
# Who         : lmieody
####################################################################
####################################################################
# Version4    : LTE 13B
# Purpose     : putting back changes that seem to have disappeared
# Date        : Aug 2013
# Who         : lmieody
####################################################################
####################################################################
# Version5    : LTE 13B
# Revision    : CXP 903 0491-30
# Purpose     : Setting ExternalCdma20001xRttCell.cellId and
#               ExternalCdma20001xRttCell.sectorNumber where
#               "cellId" Integer <= 4095 and "sectorNumber" Integer <= 15
#               as per MOM update
# Jira        : NETSUP-804
# Date        : Oct 2013
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 14A
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
# Version7    : LTE 14B.1
# Revision    : CXP 903 0491-110-1
# Purpose     : Correct SNAD issue 5 (& partly 13) seen in LTE network
# Description : Reset pnOffset count when externalcellid returns to 1
# Date        : Nov 2014
# Who         : edalrey
####################################################################
####################################################################
# Version8    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 17A
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
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $TTLEXTERNALCDMA2K1xRTTCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2K1xRTTCELLS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $element,$secequipnum;
local $nodenum,$freqgroup,$fregroup2,fregroup3;
local $EXTERNALCDMA2000CELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3;
local $totalexternalcellid;
local $EXTERNALCELLSPERNODE=30,$EXTERNALCELLSPERFREQBAND=8;
local $TTLEXTCELLS=1;
local $TTLEXTERNALCDMACELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
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
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMCdma2K1xRttSupport="D1120";
local $mimsupport=&isgreaterthanMIM($MIMVERSION,$MIMCdma2K1xRttSupport);
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
####################
# Vars
####################
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1);
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
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
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $TTLEXTERNALCDMA2K1xRTTCELLS=&getENVfilevalue($ENV,"TTLEXTERNALCDMA2K1xRTTCELLS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $element,$secequipnum;
local $nodenum,$freqgroup,$fregroup2,fregroup3;
local $EXTERNALCDMA2000CELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
local $externalcellid,$loopcounter,$loopcounter2,$loopcounter3;
local $totalexternalcellid;
local $EXTERNALCELLSPERNODE=30,$EXTERNALCELLSPERFREQBAND=8;
local $TTLEXTCELLS=1;
local $TTLEXTERNALCDMACELLS=$TTLEXTERNALCDMA2K1xRTTCELLS;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $cellGlobalIdHrpd;
local $switchnumber;
local $pnOffset=1,$MaxpnOffset=511;
local $totacdmfreqbandrelation=2,$countercdmfreqbandrelation=1;
local $totalcdmafreqband=2,$countercdmafreqband=1;
local $totalcdmafreq=2,$countercdmafreq=1;
local $exceed=0; # is 1 if total CDMA2K1Rtt cells has been exceeded, 0 is not exceeded
local $freqcounter;
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMCdma2K1xRttSupport="D1120";
local $mimsupport=&isgreaterthanMIM($MIMVERSION,$MIMCdma2K1xRttSupport);
####################
# Integrity Check
####################
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
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

# check that externalcellid does not exceed TTLEXTERNALCDMA2K1xRTTCELLS
$externalcellid=($nodecountfornodestringname*$EXTERNALCELLSPERNODE)-($EXTERNALCELLSPERNODE-1);

#---------------------------------------------------------------------------------
# start spread external cells throughout the entire network
#---------------------------------------------------------------------------------
# ensure $TTLEXTERNALCDMA2K1xRTTCELLS are spread throughout the entire LTE network
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

# check if Cdma2K1xRtt is supported in MIM
if( $mimsupport eq "yes"){}
   else { print "INFO : CDMA2K1xRtt cells are not supported in $MIMVERSION only $MIMCdma2K1xRttSupport onwards\n";
          $exceed=1;}

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
# LTE 13B
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
          parent "ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=$countercdmafreqband,Cdma2000Freq=$countercdmafreq"
          identity "$externalcellid"
          moType ExternalCdma20001xRttCell
          exception none
          nrOfAttributes 9
          "ExternalCdma20001xRttCellId" String "$externalcellid"
          "acBarring1xRttForMoDataPresent" Boolean false

          "cellIdentifier" Struct
           nrOfElements 2
           "cellId" Integer $cellIdentifiercellid
           "sectorNumber" Integer $cellIdentifiersectorNumber

          "mscIdentifier" Struct
            nrOfElements 2
            "marketId" Integer 0
            "switchNumber" Integer $switchnumber

          "nid" Integer 1
          "pnOffset" Integer $pnOffset
          "reservedBy" Array Ref 0
          "sid" Integer 1
           "userLabel" String ""
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
