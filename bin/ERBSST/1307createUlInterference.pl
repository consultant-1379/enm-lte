#!/usr/bin/perl
### VERSION HISTORY
###############################################################################
###############################################################################
# Version1    : LTE 16.14
# Revision    : CXP 903 0491-251-1
# Jira        : NSS-3791
# Purpose     : Support for UL Interference measurement sample collection
# Description : Create UlSpectrumAnalyzer under NodeManagementFunction
#               and  AuxPlugInunit -> DeviceGroup -> RfPort under
#               Equipment
# Date        : Aug 2016
# Who         : xkatmri
###############################################################################
###############################################################################
# Version2    : LTE 16.15
# Revision    : CXP 903 0491-257-1
# Jira        : NSS-6244
# Purpose     : Handle LTE code such that UL Spectrum MOs are not created for
#               all mims
# Description : Adding checks for mim that do not support UL Spectrum
# Date        : Sep 2016
# Who         : xkatmri
###############################################################################
###############################################################################
# Version3    : LTE 17.5
# Revision    : CXP 903 0491-286-1
# Jira        : NSS-9565
# Purpose     : Setting fullDistingushedName on ExternalNode MOs
# Description : To populate fullDistingushedName with nodename
# Date        : Feb 2017
# Who         : xkatmri
###############################################################################
###############################################################################
# Version4    : LTE 18.05
# Revision    : CXP 903 0491-325-1
# Jira        : NSS-16237
# Purpose     : Removing RfPort=1 Mo
# Description : Removing RfPort=1 Mo for ERBS nodes
# Date        : Feb 2018
# Who         : zyamkan
###############################################################################
###############################################################################
# Version5    : LTE 18.05
# Revision    : CXP 903 0491-329-1
# Jira        : NSS-16236
# Purpose     : Adding  RfPort=C & RfPort=D Mos for new MOM
# Description : Adding RfPort IDs for MOM > J1200
# Date        : Feb 2018
# Who         : zyamkan
###############################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
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
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
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
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
local $MIMVERSION=&queryMIM($SIMNAME);

####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
if ($MIMVERSION eq "F1108") {
   print "The Feature is not supported in the mim $MIMVERSION\n";
   exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){# start outer while

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);
  local $managedElement=&getManagedElement($LTENAME);

	 @MOCmds=();
         @MOCmds=qq^

     CREATE
    (
    parent "ManagedElement=1,NodeManagementFunction=1"
    identity "1"
    moType UlSpectrumAnalyzer
    exception none
    nrOfAttributes 1
    "UlSpectrumAnalyzerId" String "1"
    )

    CREATE
    (
    parent "ManagedElement=1,Equipment=1"
    identity "1"
    moType AuxPlugInUnit
    exception none
    nrOfAttributes 1
    "AuxPlugInUnitId" String "1"
    )

    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1"
    identity "1"
    moType DeviceGroup
    exception none
    nrOfAttributes 1
    "DeviceGroupId" String "1"
    )


    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1,DeviceGroup=1"
    identity "A"
    moType RfPort
    exception none
    nrOfAttributes 1
    "RfPortId" String "A"
    )

    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1,DeviceGroup=1"
    identity "B"
    moType RfPort
    exception none
    nrOfAttributes 1
    "RfPortId" String "B"
    )

    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1,DeviceGroup=1"
    identity "RXA_IO"
    moType RfPort
    exception none
    nrOfAttributes 1
    "RfPortId" String "RXA_IO"
    )

    SET
    (
    mo "ManagedElement=1,Equipment=1,ExternalNode=1"
    exception none
    nrOfAttributes 1
    "fullDistinguishedName" String "MeContext=$LTENAME"
    )

    SET
    (
    mo "ManagedElement=1,Equipment=1,ExternalNode=2"
    exception none
    nrOfAttributes 1
    "fullDistinguishedName" String "MeContext=$LTENAME"
    )

     ^;# end @MO
     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   if($MIMVERSION gt "J1200")
   {
         @MOCmds=qq^

    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1,DeviceGroup=1"
    identity "C"
    moType RfPort
    exception none
    nrOfAttributes 1
    "RfPortId" String "C"
    )

    CREATE
    (
    parent "ManagedElement=1,Equipment=1,AuxPlugInUnit=1,DeviceGroup=1"
    identity "D"
    moType RfPort
    exception none
    nrOfAttributes 1
    "RfPortId" String "D"
    )
    ^;# end @MO

     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    }


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
