#!/usr/bin/perl
# VERSION HISTORY
##########################################################################
# Version1    : LTE 18.10
# Revision    : CXP 903 0491-338-1
# User Story  : NSS-18705
# Purpose     : Adding HcRule MO attributes
# Description : Creating multiple HcRules
# Date        : May 2018
# Who         : zpassra
##########################################################################
# Version2    : LTE 19.03
# Revision    : CXP 903 0491-347-1
# User Story  : NSS-22469
# Purpose     : Adding HcRule MO attributes
# Description : Creating CheckHardwarestatus HcRules
# Date        : jan 2019
# Who         : zhainic
##########################################################################
##########################################################################
# Version3    : LTE 20.03
# Revision    : CXP 903 0491-356-1
# User Story  : NSS-28444
# Purpose     : Updating HC Rule MO as per new mim and supporting older mims.
# Description : Update HC Rules for LTE DG2 simulations
# Date        : Dec 2019
# Who         : xmitsin
##########################################################################
# Version4    : LTE 21.13
# Revision    : CXP 903 0491-375-1
# User Story  : NSS-36574
# Purpose     : Updating HC Rules
# Description : Update HC Rules for LTE DG2 simulations
# Date        : July 2021
# Who         : xmitsin
##########################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
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

# check if SIMNAME is of type PICO
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
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
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS",$SIMNAME);
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

while ($NODECOUNT<=$DG2NUMOFRBS){# start outer while

# get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);

	@MOCmds=();
	@MOCmds=qq^


CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1"
    identity "1"
    moType RcsHcm:HealthCheckM
    exception none
    nrOfAttributes 5
    "healthCheckMId" String "1"
    "lastExecutedJob" Ref "null"
    "lastStatus" Integer 0
    "lastUpdateTime" String "null"
    "maxNoOfReportFiles" Uint16 10
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "1"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 0
    "description" String ""
    "hcRuleId" String "1"
    "inputParameters" Array Struct 0
    "name" String ""
    "recommendedAction" String ""
    "severity" Integer 0
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "BtsFunction_CheckAbisLinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String "Check for the L2TP tunnels status"
    "hcRuleId" String "BtsFunction_CheckAbisLinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check Abis link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "BtsFunction_CheckTrxStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String "Check for the GSM TRX status"
    "hcRuleId" String "BtsFunction_CheckTrxStatus"
    "inputParameters" Array Struct 0
    "name" String "Check TRX status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)


CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckFruStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String "Check for the Field Replaceable Unit status"
    "hcRuleId" String "CommonFunction_CheckFruStatus"
    "inputParameters" Array Struct 0
    "name" String "Check FRU status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckHardwareStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String "Check for the hardware status and boards installed"
    "hcRuleId" String "CommonFunction_CheckHardwareStatus"
    "inputParameters" Array Struct 0
    "name" String "Check hardware status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)


CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckSynchronizationClock"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
   		
    "description" String "Check for the synchronization clock state"
    "hcRuleId" String "CommonFunction_CheckSynchronizationClock"
    "inputParameters" Array Struct 0
    "name" String "Check synchronization clock"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckSynchronizationReference"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4	
    "description" String "Check for the synchronization reference status"
    "hcRuleId" String "CommonFunction_CheckSynchronizationReference"
    "inputParameters" Array Struct 0
    "name" String "Check synchronization reference"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)



CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "NodeBFunction_CheckNbapCommonLinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String " Check for the common channel Iub link status"
    "hcRuleId" String "NodeBFunction_CheckNbapCommonLinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check NBAP common link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "NodeBFunction_CheckNbapDedicatedLinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    
    "description" String "Check for the dedicated channel Iub link status"
    "hcRuleId" String "NodeBFunction_CheckNbapDedicatedLinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check NBAP dedicated link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "NodeBFunction_CheckNodeBLocalCllStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4	
    "description" String "Check for the Node B Local cell status"
    "hcRuleId" String "NodeBFunction_CheckNodeBLocalCllStatus"
    "inputParameters" Array Struct 0
    "name" String "Check Node B Local cell status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "NodeBFunction_CheckWcdmaTraffic"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 3
         5
         7
         4
    "description" String "Check for the number of active radio links in a cell"
    "hcRuleId" String "NodeBFunction_CheckWcdmaTraffic"
    "inputParameters" Array Struct 0
    "name" String "Check WCDMA traffic"
    "recommendedAction" String "Observe cell performance, no radio links may indicate a sleeping cell."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "SystemFunction_CheckDiskSpace"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 1
         5	
    "description" String "Check for the available space on the archive disk"
    "hcRuleId" String "SystemFunction_CheckDiskSpace"
    "inputParameters" Array Struct 0
    "name" String "Check disk space"
    "recommendedAction" String "Check the number of Upgrade Packages and Backups on disk as well as the Log size. Remove unused packages. Export and remove backups. Export logs to before they are truncated by the system. Follow the instructions for the'Archive Disk Almost Full'alarm 0."
    "severity" Integer 0
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "SystemFunction_CheckFileServerConnection"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 1
         5
    "description" String "Check for the configured URL and credentials for the current Upgrade Package"
    "hcRuleId" String "SystemFunction_CheckFileServerConnection"
    "inputParameters" Array Struct 0
    "name" String "Check file server connection"
    "recommendedAction" String "Check the configured'url'and'password'attributes on the current Upgrade Package MO and connectivity between the system and the file server."
    "severity" Integer 0
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckRetStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
         9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckRetStatus"
    "inputParameters" Array Struct 0
    "name" String "Check Ret Status"
    "recommendedAction" String "Check the availabilityStatus attribute for more details, observe alarms for failure indication and troubleshoot alarms accordingly."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckBERForElectricalLink"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
         9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckBERForElectricalLink"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckBERForElectricalLink"
    "recommendedAction" String "1) Check to ensure that the electrical cable is fully seated or plugged into the connector on both ends. Try re-seating the connector. 2) Replace the electrical cable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckCPRILinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
         9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckCPRILinkStatus"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckCPRILinkStatus"
    "recommendedAction" String " If Multiple Units are causing health check to fail: 1) Address any site level HVAC Issue(s). 2) Address any Baseband, XMU or GPS / Timing Unit Issues. 3) Check for Fiber/Cable issues that can impact multiple links. (i.e. damage, theft, wildlife, etc.) 4) Address any site power dimensioning issues. (i.e. Power Plant Capacity and Excessive DC feeder Voltage Drop). If Single Units are raising the alarms: 1) Check RRU Power Supply. 2) Breakers and Surge Protectors and Cabling Checked. 3) Site has the correct / sufficient power plant. 4) Power Cycle the RRU at breaker. 5) Check for Ericsson Supported SFPs? 6) Check for correct Fiber/Cable type, it's not damaged and has the correct bend radius? 7) Check Fiber/Cable end faces have all been Scoped and if necessary Cleaned? 8) Replace Fiber/Cable or SFP if necessary. 9) Replace Radio if necessary. Note: Always check for any AlmID information and troubleshoot alarm(s) accordingly."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "GNBCUCPFunction_CheckXnLinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
         4
		 7
		 5
         10
    "description" String "Check for the Xn link status"
    "hcRuleId" String "GNBCUCPFunction_CheckXnLinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the Xn link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckEutranFCllStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
         4
		 7
		 5
         10
    "description" String "Check for the Eutran FCll Status"
    "hcRuleId" String "ENodeBFunction_CheckEutranFCllStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the Eutran FCll Status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckVswrStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
          9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckVswrStatus"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckVswrStatus"
    "recommendedAction" String "Check if there are any short circuit problems, open circuit problems, or problems on Antenna System Devices. Check that the feeder is connected properly to the antenna. Resolve the problem that caused DC resistance on the branch dramatically increased or decreased."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckTxAndRxPowerForSfpModule"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
          9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckTxAndRxPowerForSfpModule"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckTxAndRxPowerForSfpModule"
    "recommendedAction" String "For Tx power value outside defined range, troubleshoot if SFP is correct. For Rx power value outside defined range, refer to and follow Ericsson CPI 'SFP Module Selector Guide' and 'Handling SFP Modules and Optical Cables'."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "GNBCUCPFunction_CheckNrTraffic"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the nR traffic"
    "hcRuleId" String "GNBCUCPFunction_CheckNrTraffic"
    "inputParameters" Array Struct 0
    "name" String "Check for the nR traffic"
    "recommendedAction" String "Observe cell performance, no connected users may indicate a sleeping cell."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "GNBDUFunction_CheckNRCllDUStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the NRCllDU Status"
    "hcRuleId" String "GNBDUFunction_CheckNRCllDUStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the NRCllDU Status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable"
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckTmaStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
          9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckTmaStatus"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckTmaStatus"
    "recommendedAction" String "Check the availabilityStatus attribute for more details, observe alarms for failure indication and troubleshoot alarms accordingly. Remote actions: 1. Check the configuration of the AntennaNearUnit and TmaSubUnit MO instances. See Manage Hardware Equipment for information on configuration. 2. Check if the configured frequency band is compatible with the TMA specification. 3. Lock and unlock the AntennaNearUnit MO instance. On-site actions: 1. Validate port connectivity, and the cabling between the Radio and TMA. 2. Power restart Radio."
    "severity" Integer 1
)
CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckNbiotCllStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the Nbiot cell status"
    "hcRuleId" String "ENodeBFunction_CheckNbiotCllStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the Nbiot cell status"
    "recommendedAction" String " Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)


CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "GNBCUCPFunction_CheckNRCllCUStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the	NR cell CU status"
    "hcRuleId" String "GNBCUCPFunction_CheckNRCllCUStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the NR cell CU status"
    "recommendedAction" String " Check availabilityStatus attribute of corresponding NRCellDU for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)


CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckSctrStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the sector status"
    "hcRuleId" String "CommonFunction_CheckSctrStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the sector status"
    "recommendedAction" String "Check the availabilityStatus attribute for more details, observe alarms for failure indication and troubleshoot alarms accordingly. Remote actions: 1. Check the configuration of the SectorEquipmentFunction MO instance. See Manage Hardware Equipment for information on configuration. 2. Lock and unlock the SectorEqipmentFunction MO instance. 3. Lock and unlock the related FieldReplaceableUnit MO instance. On-site actions: 1. Validate Radio cabling and port connectivity. 2. Power restart Radio."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckS1LinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the S1 link status"
    "hcRuleId" String "ENodeBFunction_CheckS1LinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the S1 link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckX2LinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the X2 link status"
    "hcRuleId" String "ENodeBFunction_CheckX2LinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the X2 link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckEutranTCllStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the Eutran TCll Status"
    "hcRuleId" String "ENodeBFunction_CheckEutranTCllStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the Eutran TCll Status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)



CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckBERandPowerLossForOpticalLink"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
         9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckBERandPowerLossForOpticalLink"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckBERandPowerLossForOpticalLink"
    "recommendedAction" String "1) Troubleshoot to determine where optical power is being lost or Bit Errors are detected. Start at the port fiber connection reporting the loss and work back to the transmitter on the other end. (i.e. dirty, damaged or bent fiber, improperly mated connection). 2) Refer to and follow Ericsson CPI 'Handling SFP Modules and Optical Cables' for proper handling, cleaning, inspection and testing of fiber and optical interfaces."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "CommonFunction_CheckRaeStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 2
         9
         10
    "description" String ""
    "hcRuleId" String "CommonFunction_CheckRaeStatus"
    "inputParameters" Array Struct 0
    "name" String "CommonFunction_CheckRaeStatus"
    "recommendedAction" String "Check the availabilityStatus attribute for more details, observe alarms for failure indication and troubleshoot alarms accordingly. Remote actions: 1. Check the configuration of the AntennaNearUnit and RaeSubUnit MO instances. See Manage Hardware Equipment for information on configuration. 2. Check if the RAE Weighting Factor File is installed correctly. 3. Lock and unlock the AntennaNearUnit MO instance. On-site actions: 1. Validate port connectivity, and the cabling between the Radio and RAE. 2. Disconnect RAE from the Radio and reconnect."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "GNBCUCPFunction_CheckNgLinkStatus"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the Ng link status"
    "hcRuleId" String "GNBCUCPFunction_CheckNgLinkStatus"
    "inputParameters" Array Struct 0
    "name" String "Check for the Ng link status"
    "recommendedAction" String "Check availabilityStatus attribute for more details and observe Alarms for failure indication. Resolve the problem that caused the resource being inoperable."
    "severity" Integer 1
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsHcm:HealthCheckM=1"
    identity "ENodeBFunction_CheckLteTraffic"
    moType RcsHcm:HcRule
    exception none
    nrOfAttributes 9
    "administrativeState" Integer 1
    "categories" Array Integer 4
          4
		  5
		  7
         10
    "description" String "Check for the LTE traffic"
    "hcRuleId" String "ENodeBFunction_CheckLteTraffic"
    "inputParameters" Array Struct 0
    "name" String "Check for the LTE traffic"
    "recommendedAction" String "Observe cell performance, no connected users may indicate a sleeping cell."
    "severity" Integer 1
)


       ^;# end @MO
       $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

  ################################################
  # build mml script
  ################################################
  @MMLCmds=(".open ".$SIMNAME,
            ".select ".$LTENAME,
            ".start ",
            "useattributecharacteristics:switch=\"off\"; ",
            "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds

  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while

  # execute mml script
  # @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

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
################################
# END
################################
