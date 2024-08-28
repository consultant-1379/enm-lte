#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16.6
# Revision    : CXP 903 0491-207-1
# JIRA        : NSS-2951
# Purpose     : To set Product Data on DG2 nodes
# Description : Setting Product Data on DG2 nodes
# Date        : April 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : LTE16.15
# Revision    : CXP 903 0491-258-1
# JIRA        : NSS-5756
# Purpose     : Print an error if Product data is not loading on node
# Description : Adding a check for Product Data informatiom
# Date        : Sep 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE17.17
# Revision    : CXP 903 0491-315-1
# JIRA        : NSS-15557
# Purpose     : To set Administrative Data in UpgradePackage MO on
#               DG2 nodes
# Description : Setting Administrative Data on DG2 nodes
# Date        : Nov 2017
# Who         : zyamkan
####################################################################
####################################################################
# Version3    : LTE18.03
# Revision    : CXP 903 0491-323-1
# JIRA        : NSS-16261
# Purpose     : Set Software Inventory data for Com/Ecim nodes
# Description : Software Inventory data for Com/Ecim based nodes
# Date        : Jan 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version4    : LTE22.12
# Revision    : CXP 903 0491-385-1
# JIRA        : NSS-39752
# Purpose     : To set value for upgradePackageType in UpgradePackage 
#               MO on DG2 nodes
# Description : Setting upgradeRestartType value to 0 on DG2 nodes
# Date        : July 2022
# Who         : znrvbia
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
use LTE_OSS15;
####################
# Vars
####################
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# end verify params
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$pdkdate=`date '+%FT%T'`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}
# check if SIMNAME is of type DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$DG2NUMOFRBS){

    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
    $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
    $ProductDatafile="ProductData.env";
    $ProductData=&getENVfilevalue($ProductDatafile,"$MIMVERSION");
    @productData = split( /:/, $ProductData );
    $productNumber=$productData[0];
    $productRevision=$productData[1];
    chomp $pdkdate;

    #Check for Product Data information
    if (($productNumber eq "ERROR")||($productRevision eq "")) {#start if
       print "ERROR : Product data information missing, the script will exit\n\n";
       exit;
       }#end if

	# build mml script
	@MOCmds=();
	@MOCmds=qq^ SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsSwIM:SwInventory=1,RcsSwIM:SwItem=1"
    exception none
    nrOfAttributes 1
    "administrativeData" Struct
        nrOfElements 6
        "productName" String "$productNumber\_$productRevision"
        "productNumber" String "$productNumber"
        "productRevision" String "$productRevision"
        "productionDate" String "2017-11-29T09:32:56"
        "description" String "RadioNode"
        "type" String "RadioNode"

)

SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsSwIM:SwInventory=1,RcsSwIM:SwVersion=1"
    exception none
    nrOfAttributes 1
    "administrativeData" Struct
        nrOfElements 6
        "productName" String "$productNumber\_$productRevision"
        "productNumber" String "$productNumber"
        "productRevision" String "$productRevision"
        "productionDate" String "2017-11-29T09:32:56"
        "description" String "RadioNode"
        "type" String "RadioNode"

)
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsSwM:SwM=1,RcsSwM:UpgradePackage=1"
    exception none
    nrOfAttributes 2
    "administrativeData" Array Struct 1
        nrOfElements 6
        "productName" String "$productNumber\_$productRevision"
        "productNumber" String "$productNumber"
        "productRevision" String "$productRevision"
        "productionDate" String "2017-11-29T09:32:56"
        "description" String "RadioNode"
        "type" String "RadioNode"
    "upgradeRestartType" Integer 0

)   ^;# end @MO
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
}# end outer while DG2NUMOFRBS

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
################################
# END
################################
