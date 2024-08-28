#!/usr/bin/perl
####################
# Version History
####################
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
# Version3    : LTE 18.05
# Revision    : CXP 903 0491-325-1
# Jira        : NSS-16236
# Purpose     : Removing RfPort=1 Mo
# Description : Removing RfPort=1 Mo for DG2ERBS nodes
# Date        : Feb 2018
# Who         : zyamkan
###############################################################################
###############################################################################
# Version4    : LTE 18.05
# Revision    : CXP 903 0491-329-1
# Jira        : NSS-16236
# Purpose     : Adding  RfPort=C & RfPort=D Mos for new MOM
# Description : Adding RfPort IDs for MOM > 18-Q1-V4
# Date        : Feb 2018
# Who         : zyamkan
###############################################################################
###############################################################################
# Version5    : LTE 19.04
# Revision    : CXP 903 0491-348-1
# Jira        : NSS-22789
# Purpose     : Creating the mos for TDD cell nodes for CBSD support
# Description : To create the fieldreplaceableUnit Mos
#               12cell DOTS and 6cell mRRUs
# Date        : January 2019
# Who         : xharidu
###############################################################################
####################################################################
# Version6    : LTE 19.07
# Revision    : CXP 903 0491-351-1
# Jira        : NSS-22790
# Purpose     : Modifying DOT cellconfiguration
# Description : To increase FRUS to 48 for 12cell TDD DOTS
# Date        : April 2019
# Who         : xharidu
####################################################################
####################################################################
# Version7    : LTE 19.11
# Revision    : CXP 903 0491-352-1
# Jira        : NSS-23889
# Purpose     : Populating latitude-longitude values to FRUs
# Description : To provide unique latitude-longitude coordinates in
#               6cell and 12cell FRUs
# Date        : June 2019
# Who         : xharidu
####################################################################
####################################################################
# Version8    : LTE 20.08
# Revision    : CXP 903 0491-361-1
# Jira        : NSS-30062
# Purpose     : Modify CBSD support for only DOTS and 4408
# Description : To modify the attributes for mrrUs
# Date        : April 2020
# Who         : xharidu
####################################################################
####################################################################
# Version9    : LTE 20.16
# Revision    : CXP 903 0491-368-1
# Jira        : NSS-28950
# Purpose     : Modify CBSD support for DOT, 4408 and 6448
# Description : Bypass this script for the nodes assigned for CBSD
# Date        : September 2020
# Who         : xharidu
####################################################################
####################################################################
# Version10   : LTE 21.16
# Revision    : CXP 903 0491-375-1
# Jira        : NSS-36517
# Purpose     : Correcting Rfport code for CBRS devices
# Date        : 21st Sept 2021
# Who         : zyamkan
####################################################################

###################
# Env
###################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS13;
use LTE_OSS14;
use LTE_OSS15;
use LTE_coordinates;
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
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $FTPDIR=&getENVfilevalue($ENV,"FTPDIR");
local $TOTALNETWORKNODES=$LTE*$NUMOFRBS;
local $NODEOFFSET=$NUMOFRBS-1;
local $ENBID=$TOTALNETWORKNODES-$NODEOFFSET;
local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $nodecountinteger,$tempcellnum,$cellNum;
local $NODESIM,$nodecountinteger;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
#$PRIMARY_NODECELLS
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
if (($MIMVERSION eq "16A-V18") || ($MIMVERSION eq "16B-V13")) {
   print "The Feature is not supported in the mim $MIMVERSION\n";
   exit;}
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

# get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # set cell configuration ex: 6,3,3,1 etc.....
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
  $CELLNUM=@primarycells;
  # check cell type
  if(($NODECOUNT<=$NUMOFRBS) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))){
      $TYPE="Lrat:EUtranCellFDD";
      $cbrsType="SKIP";
  }# end if
  else{
     $TYPE="Lrat:EUtranCellTDD";
     $cbrsType=&getCbrsType($nodecountinteger,$CELLNUM);
  }# end else

  # check for CBRS nodes
  if($cbrsType ne "SKIP") {
     $NODECOUNT++;
     next;
  }

	@MOCmds=();
	@MOCmds=qq^

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,RmeSupport:NodeSupport=1"
    identity "1"
    moType RmeUlSpectrumAnalyzer:UlSpectrumAnalyzer
    exception none
    nrOfAttributes 1
    "ulSpectrumAnalyzerId" String "1"
    )
^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $fieldreplaceableUnitNum=1;
    $fieldreplaceableUnitCount=1;
    while(($fieldreplaceableUnitCount<=$fieldreplaceableUnitNum)){
       @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1"
    identity $fieldreplaceableUnitCount
    moType ReqFieldReplaceableUnit:FieldReplaceableUnit
    exception none
    nrOfAttributes 3
    "fieldReplaceableUnitId" String $fieldreplaceableUnitCount
    "administrativeState" Integer 1
    "operationalState" Integer 1
    )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "A"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "A"
    )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "B"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "B"
    )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "RXA_IO"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "RXA_IO"
    )

        ^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        if($MIMVERSION gt "18-Q1-V4")
        {
           @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "C"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "C"
    )

    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "D"
    moType ReqRfPort:RfPort
    exception none
    nrOfAttributes 1
    "rfPortId" String "D"
    ) ^;# end @MO

           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
        }
        @MOCmds=qq^
    CREATE
    (
    parent "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldreplaceableUnitCount"
    identity "1"
    moType ReqRcvdPowerScanner:RcvdPowerScanner
    exception none
    nrOfAttributes 1
    "rcvdPowerScannerId" String	"1"
    )^;# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $fieldreplaceableUnitCount++;
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
