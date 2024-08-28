#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version3     : LTE21.03
# Revision     : CXP 903 0491-370-1
# Author       : Yamuna Kanchireddygari
# JIRA         : NSS-33640
# Description  : Set licensedCapacityLimit value to 32
# Date         : Dec 2020
####################################################################
####################################################################
# Version1    : LTE16.8
# Revision    : CXP 903 0491-211-1
# User Story  : NSS-2172
# Purpose     : Set ProductType attribute in LM MOs
# Description : Setting attributes on LM MOs
# Date        : May 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : LTE17.07
# Revision    : CXP 903 0491-291-1
# User Story  : NSS-10373
# Purpose     : Set attributes in HwInventory & LicenseInventory MOs
# Description : Setting attributes on FDN MOs
# Date        : April 2017
# Who         : zsxxsam
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
local $date=`date`,$LTENAME;
chomp $date;
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
print "...${0} started running at $date\t";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$DG2NUMOFRBS){

	$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

	# build mml script
	@MOCmds=();
	@MOCmds=qq^
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsLM:Lm=1,RcsLM:CapacityKey=1"
    exception none
    nrOfAttributes 4
    "productType" String "WRAN"
    "validFrom" String "$date"
    "keyId" String "RadioNode"
    "licensedCapacityLimit" Struct
        nrOfElements 2
        "value" Int32 32
        "noLimit" Boolean false
)
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsLM:Lm=1,RcsLM:FeatureKey=1"
    exception none
    nrOfAttributes 4
    "productType" String "WRAN"
    "validFrom" String "$date"
    "keyId" String "RadioNode"
    "expiration" String "$date "
)
SET
(
    mo "ComTop:ManagedElement=$LTENAME,ComTop:SystemFunctions=1,RcsLM:Lm=1,RcsLM:KeyFileManagement=1,RcsLM:KeyFileInformation=1"
    exception none
    nrOfAttributes 2
    "productType" String "WRAN"
    "installationTime" String "$date"
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

