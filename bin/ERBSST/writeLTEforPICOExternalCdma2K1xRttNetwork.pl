#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : LTE 15B.1
# Purpose     : archive the LTE network data for the
#               Cdma2K1xRtt external network for usage in building
#               the PICO Cdma2K1xRtt external network  
# Description : use the same external data in the LTE and PICO
#               Cdma2K1xRtt external network
# 
# Output : ~customdata/pico/LTE28000cell_ExternalCdma2K1xRttcellforPICO.csv 
# 
# User Story  : OSS-56816 
# Date        : December 2014
# Who         : epatdal
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
####################
# Vars
####################
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1);
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
$ENV="CONFIG.env";
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
local $linepattern= "#" x 100;
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pico\//;
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."cell_ExternalCdma2K1xRttcellsforPICO.csv";
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JIRA NETSUP-804 MOM cardinality update to cellid and sectorNumber
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local $MAXcellIdentifiercellid=4095;
local $MAXcellIdentifiersectorNumber=15;
local $cellIdentifiercellid=1;
local $cellIdentifiersectorNumber=0;
####################
# Integrity Check
###################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}

open FH1 , "> $LTENetworkOutput" or die $!;
print FH1 "$linepattern\n";
print FH1 "... ${0} started running at $date";
print FH1 "$linepattern\n";
print FH1 "# LTE15B.1 LTE Cdma2K1xRtt external network data to be used when creating the PICO Cdma2K1xRtt external network\n";
print FH1 "# LTE15B.1 LTE User Story : OSS-56816\n";
print FH1 "# Data columns layout = LTENODENAME...tempcounter..Cdma2K1xRttcellIdNumber..Cdma2KxRttcellIdsectorNumber\n";
print FH1 "$linepattern\n\n";
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
$runCounter=0;$LTE=0;

while($runCounter<=$NETWORKCELLSIZE){ # start outer while NETWORKCELLSIZE

     $NODECOUNT=1;$LTE++;

while (($NODECOUNT<=$NUMOFRBS)&&($exceed==0)){

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

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

         print FH1 "$LTENAME...$runCounter...$cellIdentifiercellid...$cellIdentifiersectorNumber\n";
         $runCounter++;

         # check cell id 
         $pnOffset++;
         if($pnOffset>$MaxpnOffset){$pnOffset=1;}
  
         $externalcellid++;$freqcounter++; 
         $countercdmafreq++;

         if($freqcounter<=$EXTERNALCELLSPERFREQBAND){$countercdmafreq=1;}# maintain sequential extercellids per cdmafreq
         if(($freqcounter>$EXTERNALCELLSPERFREQBAND)&&($freqcounter<=($EXTERNALCELLSPERFREQBAND*2))){
                    $countercdmafreq=2;}# maintain sequential extercellids per cdmafreq
     
         if ($externalcellid >= $totalexternalcellid){last;}
         
      }# end while totalcdmafreq

  $countercdmafreqband++;
  }# end while totalcdmafreqband

  if($runCounter>=$TTLEXTERNALCDMA2K1xRTTCELLS){last;}

} # end outer totalexternalcellid
#####################################
# end create ExternalCdma20001ixRttCell
#####################################

   $NODECOUNT++;
   #$runCounter=$CELLNUM+$runCounter;
   if($runCounter>=$TTLEXTERNALCDMA2K1xRTTCELLS){last;}
 }# end outer NODECOUNT while


  # check node cell size does not exceed NETWORKCELLSIZE
  if($runCounter>$NETWORKCELLSIZE){last;}
  if($runCounter>=$TTLEXTERNALCDMA2K1xRTTCELLS){last;}

}# end outer while NETWORKCELLSIZE
#------------------------------------------
# start determine External CDMA cell number
#------------------------------------------
if($exceed==0){# start if exceed
   # execute mml script
################################
# CLEANUP
################################
  $date=`date`;
  unlink @NETSIMMOSCRIPTS;
  unlink "$NETSIMMMLSCRIPT";
}# end if exceed
print FH1 "$linepattern\n";
print FH1 "... ${0} ended running at $date";
print FH1 "$linepattern\n";
close(FH1);
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------

print "... ${0} ended running at $date\n";

################################
# END
################################
