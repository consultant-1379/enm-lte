#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.8
# Revision    : CXP 903 0491-42-19
# Purpose     : sets PICO ExternalCdma20001xRttCell attributes
# Description : creates support for the creation of PICO2CDMA2K
#               and PICOCDMA2KRtt
# Jira        : NETSUP-1019
# Date        : Jan 2014
# Who         : ecasjim
####################################################################
####################################################################
# Version2    : LTE 15B.1
# Revision    : CXP 903 0491-108-1
# Purpose     : input the LTE network data for the
#               Cdma2K1xRtt external network for usage in building
#               the PICO Cdma2K1xRtt external network
# Description : use the same external data in the LTE and PICO
#               Cdma2K1xRtt external network
#               ~customdata/pico/LTE28000cell_ExternalCdma2K1xRttcellforPICO.csv
# Jira        : OSS-56816
# Date        : Dec 2014
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 16A
# Revision    : CXP 903 0491-167-1
# Purpose     : pnOffset value mismatch is seen by SNAD as they are not
#               set on Cdma2kRttCell
# Description : Setting pnOffset value for Cdma2kRttCell
# Jira        : NETSUP-3523
# Date        : 14 September 2015
# Who         : xsrilek
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
local $command1="./writeLTEforPICOExternalCdma2K1xRttNetwork.pl";
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}

# check isCdmaRtt Feature turned ON or OFF
if(&isCdma20001xRttYes=~/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $Cdmanetwork="Cdma2000Network";
local $Cdma2000FreqBand="Cdma2000FreqBand";
local $currCdma2000FreqBand=1;
local $totalCdma2000FreqBand=6;
local $Cdma2000Freq="Cdma2000Freq";
local $currCdma2000Freq=1;
local $totalCdma2000Freq=2;
local $ExternalCdma2000Cell="ExternalCdma2000Cell";

local $ExternalCdma20001xRttCell="ExternalCdma20001xRttCell";
local $MAXExternalCdma20001xRttCell=10909;
local $MAXExternalCdma2000Cell=533;
local $ExternalCdma20001xRttCellID=1;
local $NodeExternalCdma20001xRttCell=5;
local $Minus1NodeExternalCdma20001xRttCell=$NodeExternalCdma20001xRttCell-1;
local $totalexternalRttcellsperfreqband=5;

local $tempcounter;

local $cellGlobalIdHrpd="cellGlobalIdHrpd";
local $totalexternalcellsperfreqband=2;
local $ExternalCdma20001xRttCellID=1;
local $cellGlobalIdHrpdID=1;
local $sid="sid";
local $nid="nid";

local $maxcellId=4096;
local $sectorNumber=0;
local $maxSwitchNumber=20;
local $switchNumber=0;

local $ExternalCdma2000CellID;

local $totalRttCellsPerNode=($totalCdma2000FreqBand*$totalCdma2000Freq*$NodeExternalCdma20001xRttCell);
local $Minus1totalRttCellsPerNode=$totalRttCellsPerNode-1;

local $totalCdmacellsperNode=8;
local $Minus1totalCdmacellsperNode=$totalCdmacellsperNode-1;

local $maxIPV6 = 533;
local $maxSectorNumber = 16;

# Ver2 : LTE 15B.1
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pico\//;
local $rrtFilePath ="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."cell_ExternalCdma2K1xRttcellsforPICO.csv";

if(!(-e $rrtFilePath)){# external LTE Cdma2K1RttNetwork data
   print "Executing $command1 to create $rrtFilePath\n";
   $retval=system("$command1 >/dev/null 2>&1");
   if($retval!=0){
      print "FATAL ERROR : unable to create $rrtFilePath\n";
      $retval=0;
      exit;
   }# end inner if
}# end outer if

local @rrtValues=();
local $rttArraySize;

#open rtt file
open rttFILE, $rrtFilePath or die $!;
my @rrtValues=<rttFILE>;
$rttArraySize=@rrtValues;

local $totalRttCells = ($totalCdma2000FreqBand * $totalCdma2000Freq * $NodeExternalCdma20001xRttCell * $PICONUMOFRBS);
local $rttArrayposition = 0;

local $pnOffset=1,$MaxpnOffset=511;

# get current node count number
$nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);

#get starting cellId based on sim number
local $cellId = ($nodecountinteger * ($totalCdma2000FreqBand * $totalCdma2000Freq * $NodeExternalCdma20001xRttCell) - 59) % $maxcellId;

#This is due to macro LTE starting at 2 after reaching 4095 twice
if ($nodecountinteger > 1){$cellId = $cellId + int((($totalRttCells) * ($LTE - $PICOSIMSTART)) / $maxcellId) * 2;}

#sector number increases depending on the amount of times cellId has reached 4095
if($nodecountinteger > 1)
{
	$sectorNumber=int((($totalRttCells) * ($LTE - $PICOSIMSTART)) / $maxcellId);
	$sectorNumber= $sectorNumber % $maxSectorNumber;
}

#get starting sim ExternalCdma2000RttCellID
$ExternalCdma20001xRttCellID=($nodecountinteger*$totalRttCellsPerNode)-$Minus1totalRttCellsPerNode;

# get starting sim ExternalCdma2000CellID
$ExternalCdma2000CellID=($nodecountinteger*$totalCdmacellsperNode)-$Minus1totalCdmacellsperNode;

# ensure MaxExternalCdma2000CellFDD not exceeded
if($ExternalCdma2000CellID>$MAXExternalCdma2000Cell){$ExternalCdma2000CellID=$ExternalCdma2000CellID%$MAXExternalCdma2000Cell;}

# ensure MaxExternalRttCellFDD not exceeded
if($ExternalCdma20001xRttCellID>$MAXExternalCdma20001xRttCell)
{
	$ExternalCdma20001xRttCellID=$ExternalCdma20001xRttCellID % $MAXExternalCdma20001xRttCell;
        $cellId = ($ExternalCdma20001xRttCellID % $maxcellId) + 2;
        $sectorNumber = int($ExternalCdma20001xRttCellID / $maxcellId);
        $switchNumber=$ExternalCdma20001xRttCellID % $maxSwitchNumber;
}

while($rttArrayposition<$rttArraySize)
{
        # Ver2 : LTE 15B.1
        # LTE external Cdma2K1xRttnetwork
        # ~customdata/pico/LTE28000cell_ExternalCdma2K1xRttcellforPICO.csv
        # Data columns layout = LTENODENAME...tempcounter..Cdma2K1xRttcellIdNumber..Cdma2KxRttcellIdsectorNumber

	($ltenodename,$overallRttID,$usedRttID,$sectorNum)=split(/\.../,$rrtValues[$rttArrayposition]);

	if($ExternalCdma20001xRttCellID == $overallRttID)
	{
		$cellId=$usedRttID;
		last;
	}
	$rttArrayposition++;
}

while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    #####################################
    # start create PICO external network
    #####################################
    $currCdma2000FreqBand=1;

    while ($currCdma2000FreqBand<=$totalCdma2000FreqBand){# while Cdma2000FreqBand

     $currCdma2000Freq=1;
     #$ExternalCdma20001xRttCellID=1;
     while($currCdma2000Freq<=$totalCdma2000Freq){# while Cdma2000Freq

	$tempcounter=1;
      	while($tempcounter<=$totalexternalRttcellsperfreqband)
        {

	$switchNumber=($ExternalCdma20001xRttCellID % $maxSwitchNumber);

	# ensure MaxExternalUtranCellFDD not exceeded, reset all traffical id counters
	if ($ExternalCdma20001xRttCellID>$MAXExternalCdma20001xRttCell)
	{
		$ExternalCdma20001xRttCellID=1;
		$cellId = 1;
		$sectorNumber = 0;
		$switchNumber=0;
	}

	if ($cellId > 4095 && $sectorNumber==0)
	{
		$cellId = 2;
		$sectorNumber++;

		if ($sectorNumber == $maxSectorNumber)
		{
			$sectorNumber = 0;
		}
	}

	if ($cellId > 4095 && $sectorNumber > 0)
	{
		$cellId = 1;
		$sectorNumber++;

		if ($sectorNumber == $maxSectorNumber)
		{
			$sectorNumber = 0;
		}
	}

	if($switchNumber == 0 && $sectorNumber == 0)
	{
		$switchNumber=1;
	}


        # build mml script
       @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"$sid (long)=1\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"$nid (long)=1\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"cellIdentifier (struct, Cdma1xRttCellId)=[$cellId,$sectorNumber]\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"mscIdentifier (struct, MSCid)=[0,$switchNumber]\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"csfbRegParams1xRttMoData (struct, CsfbRegParams1xRtt)=[false,false,true,true,true,true,true,80,0,0,1,true]\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"mobilityParams1xRttMoData (struct, MobilityParams1xRtt)=[0,3,false,0,3,0,0,false,56,64,56,64,64,4,0,false,3,5]\";"
,
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma20001xRttCell=$ExternalCdma20001xRttCellID\",attributes=\"pnOffset (String)=$pnOffset\";"
        );#end @MMLCmds
        $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

	$pnOffset++;
        if($pnOffset>$MaxpnOffset){$pnOffset=1;}

	if($tempcounter < 3 && $currCdma2000FreqBand < 3)
	{

	if ($ExternalCdma2000CellID > $MAXExternalCdma2000Cell){$ExternalCdma2000CellID=1;}

	#increment and loop IPv6 address
	if ($cellGlobalIdHrpdID > $maxIPV6){$cellGlobalIdHrpdID=1;}
        $ipv6Add = sprintf("%x",$cellGlobalIdHrpdID);

	@MMLCmds=(".open ".$SIMNAME,
        	".select ".$LTENAME,
          	".start ",
          	"useattributecharacteristics:switch=\"off\";",

"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,$Cdmanetwork=1,$Cdma2000FreqBand=$currCdma2000FreqBand,$Cdma2000Freq=$currCdma2000Freq,$ExternalCdma2000Cell=$ExternalCdma2000CellID\",attributes=\"$cellGlobalIdHrpd (string)=0000:0000:0000:0000:0000:0000:0000:$ipv6Add\";"
        );#end @MMLCmds
        	$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
		$cellGlobalIdHrpdID++;
		$ExternalCdma2000CellID++;

 	}
	$ExternalCdma20001xRttCellID++;
	$cellId++;
   	$tempcounter++;

       }# end while Cdma2000Freq
       $currCdma2000Freq++;

    }# end while Cdma2000Freq

       $currCdma2000FreqBand++;
     }# end while Cdma2000FreqBand

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
