#!/usr/bin/perl
### VERSION HISTORY
####################################################################
####################################################################
# Version1    : LTE 15.17
# Revision    : CXP 903 0491-185-1
# Jira        : NSS-501
# Purpose     : MO bulk up 
# Description : ENM requirement to add MO load
# Date        : Nov 2015
# Who         : ejamfur
#################################################################### 
####################################################################
# Version1    : LTE 16.3
# Revision    : CXP 903 0491-195-1
# Jira        : NSS-2068
# Purpose     : Resolve build Errors for 40K 
# Description : Error! Max number of children exceeded for MOs IpSec,
#               IpAccessHostEt, to resolve this removing these MOs, 
#               as these are already defined in 2030
# Date        : Feb 2016
# Who         : xsrilek
###################################################################
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
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
#----------------------------------------------------------------
local $MOBulkEnabled=&getENVfilevalue($ENV,"ENABLEMOBULKUP");
if ($MOBulkEnabled=~m/NO/) {exit;}
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $nodecountinteger,@primarycells=(),$cellsPerNode;
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS) {

 # get node name
 $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);
 $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
 @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
 $cellsPerNode=@primarycells;

 @MOCmds=();
 @MOCmds=qq^ CREATE
   (
   ^;
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
 for (my $cell=1; $cell <= $cellsPerNode; $cell++) {
      @MOCmds=();
      @MOCmds=qq^
           parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=$LTENAME-$cell,UeMeasControl=1"
              identity 1
              moType ReportConfigEUtraIntraFreqPm
          
          parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=$LTENAME-$cell,UeMeasControl=1"
              identity 1
              moType PmUeMeasControl

     ^;
     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  }

  @MOCmds=();
  @MOCmds=qq^
  )
  ^;
  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);


  # build mml script 
  @MMLCmds=(
	".open ".$SIMNAME,
	".select ".$LTENAME,
	".start ",
	"useattributecharacteristics:switch=\"off\";",
        "kertayle:file=\"$NETSIMMOSCRIPT\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.238\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.234\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.230\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.214\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.2\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.158\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.122\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.78.106\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.98\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.230\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.214\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.2\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.198\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.77.118\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.75.58\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.75.34\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.75.174\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.74.214\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.65.98\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.65.58\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.65.22\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.65.218\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.65.10\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.186.130\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.186.122\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.185.226\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.185.210\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.184.166\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.183.230\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.183.218\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.183.130\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.182.46\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.182.150\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.86\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.74\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.70\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.222\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.186\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.182\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.18\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.142\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.110\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.143.181.106\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.141.95.114\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.141.102.170\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.141.102.118\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-184.139.163.138\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.80.90\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.80.158\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.80.118\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.74.90\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.74.170\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.75.74.162\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.108.232.2\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.97.66\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.96.86\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.96.78\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.96.42\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.95.246\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.95.18\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.91.34\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.90.82\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.90.158\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.94\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.82\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.66\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.242\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.18\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.81.102\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.121.146\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.98\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.86\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.78\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.50\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.238\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36422-107.105.118.118\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.65.47\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.65.144\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.6.252\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.55.207\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.5.152\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.3.63\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.3.255\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.3.181\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-172.29.237.100\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-107.77.33.48\";",
"createmo:parentid=\"ManagedElement=1,TransportNetwork=1,Sctp=1\",type=\"SctpAssociation\",name=\"36422-184.143.78.202_36412-107.77.33.112\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"TimeInfoSIB16\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"ThreeDlCarrierAggregation\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"SUPPLEMENTARYDLONLYCELL\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"SRVCCtoGERAN\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"SRVCCtoCDMA1X\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"SgwRelocationAtX2Handover\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"ServOrPrioTriggeredIFHo\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"QuadAntDlPerfPkg4x4\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"QuadAntDlPerfPkg\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"PucchOverdimensioning\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"PshoBasedCsfbToUtran\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"PriorityPaging\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"Prescheduling\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"PHICHGroupSpreading\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"PdcchPowerBoost\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"OverlaidCellDetection\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"OtdoaPrsManagement\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"NonPlannedPCIRange\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MultiTargetRrcConnReest\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MultiSectorPerRadio\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MultiFreqBand\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MmeOverloadControl\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MIMOSleepMode\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MicroSleepTx\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MeasBasedSCellSelection\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MeasBasedCsfbTargetSelection\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"MbmsMultiCarrier\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"LTEBroadcast\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"LppaBasedOtdoaSupport\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"LoadBasedAccessBarring\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"IntraLTEInterModeHandover\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"Internal1\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"InterFrequencyOTDOA\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"InterFrequencyOffload\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"IFLBActivationThreshold\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"FeicicX2Assistance\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"EnhCsfbTo1xRtt\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"EnhancedPdcchLa\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"DynamicScellSelection\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"DynamicLoadControl\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CsfbTo1xRtt\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CrossDUCarrierAggregation\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CoverageAdaptedLm\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CellSoftLock\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CarrierAggregationAwareIFLB\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"CarrierAggregation\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"BnrIratOffload\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"BnrIntraLteLM\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"AutoRachRsAlloc\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"AutomatedMobilityOptimization\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"AutoCellCapEstFunction\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"OptionalFeatureLicense\",name=\"AntSystemMonitoring\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower80WTo100W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower60WTo80W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower40WTo60W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower20WTo40W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower140WTo160W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower120WTo140W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"OutputPower100WTo120W\";",
"createmo:parentid=\"ManagedElement=1,SystemFunctions=1,Licensing=1\",type=\"CapacityFeatureLicense\",name=\"Capacity5MHzSectorCarriers\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"SwAllocation\",name=\"WEBSERVER\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"SwAllocation\",name=\"RBS_RU\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"SwAllocation\",name=\"OTHER\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"SwAllocation\",name=\"main\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"SwAllocation\",name=\"JVM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_OAM_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_OAM_AUE1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_MGMNT_MAIN3\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_MGMNT_MAIN2\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_MGMNT_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_EM_VIEWS1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_EM_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_EM_INSTALL\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_CATOAM_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_CATOAM_AUE1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_CABV_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_CABV_L\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_APC_MAIN3\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_APC_MAIN2\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_APC_MAIN1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"RBS_APC_AUE1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"PLF_TEST_Control_sql_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_SEC\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_RU\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_PM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_OSS_MOM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_OSS_FILES\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_OAM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_MP_Main\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_MP_Extension\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_MOM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_LTESYSPAR\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_IFMODEL\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_EM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_Control_SSW_CBM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_BB_FPGA\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_BB\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_AUE\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_RBS_Add_Java_AUE\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_MTDINFO\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"LTE_CPP_DEBUG\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"EM_TOOLBOX\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"EMAS_BASIC\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_SYS_PAR\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Netw_Sync_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Netw_Sync_CBM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_MAO_Basic\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_IP_Tran_Upgrade_14\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_IP_Transport_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_IP_Transport_IPSec_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_IP_Transport_CBM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_IP_OAM_Transport_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Int_Tran_Upgrade_8\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_InterConnect_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_InterConnect_DUL_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_EM_Common\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_EMAS_Views\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Upgrade_9\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_SSW_CBM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_OAM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Debug_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Common_Redundancy_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Common_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Common_FTC_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Control_Common_CBM_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Basic_DUS41_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_Basic_DU_noSTM1_R6K\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"CPP_ATM_Tran_Upgrade_6\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"Cello_OAM_Other\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"Cello_OAM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"Repertoire\",name=\"Cello_MOM\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"target_monitor\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"sctp_host\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"sctp_adm\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"RBS_support_system_ctrl\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"pms_event_distr\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_sw_installation\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_secure_shell\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_object_support\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_jvm\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_ip_utilities\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_inet\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"osa_http_server\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"oam_pm_reporter--0--1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"nsscbm\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"nclishell\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"licenseServer\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"ipsec_adm\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"ip_bit_adm\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"ReliableProgramUniter\",name=\"iell_resman_cbm_mp--0--1\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1\",type=\"TrafficManagement\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1\",type=\"Ipv6\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1\",type=\"Ipv6Interface\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1\",type=\"Ipv6Interface\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1\",type=\"TrafficScheduler\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1,TrafficScheduler=1\",type=\"TrafficManagementQueue\",name=\"6\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1,TrafficScheduler=1\",type=\"TrafficManagementQueue\",name=\"5\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1,TrafficScheduler=1\",type=\"TrafficManagementQueue\",name=\"4\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1,TrafficScheduler=1\",type=\"TrafficManagementQueue\",name=\"3\";",
"createmo:parentid=\"ManagedElement=1,IpSystem=1,TrafficManagement=1,TrafficScheduler=1\",type=\"TrafficManagementQueue\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,IpOam=1,Ip=1\",type=\"IpHostLink\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,EquipmentSupportFunction=1\",type=\"PowerSupply\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,EquipmentSupportFunction=1\",type=\"PowerDistribution\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,EquipmentSupportFunction=1\",type=\"BatteryBackup\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"ROJ999999_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901125/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901125/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901125/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901125/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901113/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901113/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901113/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901113/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901112/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901112/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901112/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901112/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901107/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901107/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901107/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901107/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901103/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901103/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901103/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901103/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901102/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901102/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901102/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901102/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901101/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901101/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901101/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901101/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901050/4_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901050/3_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901050/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KRD901050/1_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"SubrackProdType\",name=\"KDU127189/2_*\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"RiLink\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"HwUnit\",name=\"SUP-1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"HwUnit\",name=\"SAU\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"EcBus\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1\",type=\"AuxPlugInUnit\",name=\"RRU-1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"F\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"E\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"D\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"C\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"B\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"RiPort\",name=\"A\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXP9020294/22_R51AC\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXP102066/5_R87C01\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1736725/22_R51L\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1735763_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1735251/22_R51L\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1734322/22_R51H\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1733444_R87C16\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732844_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732823/22_R51T\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732821_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732768/22_R51S\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732469_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732289/2_R87C14\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732204_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1732167_R87C09\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1731354_R87C09\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1731081_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1731080_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1729957_R87C09\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1729153/22_R25A\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1728281_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1727220_R87C11\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1727219_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1726088/22_R51X\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1725422/5_R87C31\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1725398/22_R51M\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1725191/22_R51X\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1725190/22_R51Z\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1721176_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1720483_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1329000/5_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1327705_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1326054_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1325792_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1325240/1_R87C09\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1323911_R87C10\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1323891/6_R87C22\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1323464_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1322506_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1321344_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1321341_R87C08\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1321316_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1321315_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1321314_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1320787_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1320783_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1320782_R87C12\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"Program\",name=\"CXC1320781_R87C07\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1\",type=\"DeviceGroup\",name=\"dul\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,TimingUnit=1\",type=\"GpsSyncRef\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,GeneralProcessorUnit=1\",type=\"ProcessorLoad\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIp=1\",type=\"Program\",name=\"CXC1735308_R85B01\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIp=1\",type=\"Program\",name=\"CXC1726213_R87C62\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"9\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"8\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"7\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"6\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"5\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"4\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"3\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"16\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"15\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"14\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"13\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"12\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"11\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"10\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SUP-1\",type=\"AlarmPort\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"9\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"8\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"7\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"6\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"5\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"4\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"32\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"31\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"30\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"3\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"29\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"28\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"27\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"26\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"25\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"24\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"23\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"22\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"21\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"20\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"19\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"18\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"17\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"16\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"15\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"14\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"13\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"12\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"11\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"10\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,HwUnit=SAU\",type=\"AlarmPort\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,Cabinet=1\",type=\"FanGroup\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1\",type=\"RiPort\",name=\"DATA_2\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1\",type=\"RiPort\",name=\"DATA_1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1\",type=\"DeviceGroup\",name=\"ru\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"RfPort\",name=\"R\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"RfPort\",name=\"B\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"RfPort\",name=\"A\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"8\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"7\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"6\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"5\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"4\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"3\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AuxPlugInUnit=RRU-1,DeviceGroup=ru\",type=\"AlarmPort\",name=\"1\";",
"createmo:parentid=\"ManagedElement=1,Equipment=1,AntennaUnitGroup=1,AntennaUnit=1\",type=\"AntennaSubunit\",name=\"2\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"22\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"21\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"20\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"19\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"18\";",
"createmo:parentid=\"ManagedElement=1,ENodeBFunction=1\",type=\"TermPointToMme\",name=\"17\";",
    );# end @MMLCmds
    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while NUMOFRBS
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
print "... ${0} ended running at $date\n";
exit;
################################
# END
################################
