#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE16.6
# Revision    : CXP 903 0491-207-1
# JIRA        : NSS-2951
# Purpose     : To set Product Data on ERBS nodes
# Description : Setting Product Data on ERBS nodes
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
# Version3    : LTE18.03
# Revision    : CXP 903 0491-323-1
# JIRA        : NSS-16261
# Purpose     : Set Software Inventory data for CPP based nodes
# Description : Software Inventory data for CPP based nodes as per
#               real node data
# Date        : Jan 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version4    : LTE18.04
# Revision    : CXP 903 0491-324-1
# JIRA        : NSS-16577
# Purpose     : Set upgradePackageDocumentId attribute value
# Description : Update upgradePackageDocumentId attribute with proper
#               value
# Date        : Jan 2018
# Who         : zyamkan
####################################################################
###############################################################################
# Version5   : LTE 20.06
# Revision    : CXP 903 0491-360-1
# User Story  : NSS-28822
# Purpose     : To update UpgradePackage Production Date (PART-2)
# Description : Sets productionDate attribute to 8digit format
# Date        : Mar 2020
# Who         : xharidu
###############################################################################

####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_General;
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
if (&isSimPICO($SIMNAME)=~m/YES/ || &isSimDG2($SIMNAME)=~m/YES/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$pdkdate=`date +'%Y%m%d'`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
local $FTPDIR=&getENVfilevalue($ENV,"FTPDIR");
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

while ($NODECOUNT<=$NUMOFRBS){# start outer while

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

	@MOCmds=();
	@MOCmds=qq^ SET
(
    mo "ManagedElement=1,SwManagement=1,UpgradePackage=1"
    exception none
    nrOfAttributes 2
    "upgradePackageDocumentId" String "$productNumber\_$productRevision"
    "administrativeData" Struct
        nrOfElements 5
        "productNumber" String "$productNumber"
        "productRevision" String "$productRevision"
        "productName" String "$productNumber\_$productRevision"
        "productInfo" String "ERBS"
        "productionDate" String "$pdkdate"

)	^;# end @MO
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
