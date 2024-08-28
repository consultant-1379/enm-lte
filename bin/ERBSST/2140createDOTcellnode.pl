#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14B
# Revision    : CXP 903 0491-49-1
# Jira        : NETSUP-1594
# purpose     : support for DOT Cells in the LTE14B 28K network
# Description : supports 1000 nodes with DOT cells
# date        : May 2014
# who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-102-1
# purpose     : suppress DOT cells creation in LTE15B network
# Description : outside scope for LTE15B - LMI-14:003150 PA15
# Jira        : EriDoc LMI-14:003150 PA15
# date        : Nov 2014
# who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : NETSUP-1019
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 16B
# Revision    : CXP 903 0491-189-1
# Jira        : NSS-472
# Purpose     : ENM:Request LTE Radio Dot simulation with support
#               for all FCAPs
# Description : Adds RDS to 12cell and 6cell nodes
# Date        : 10 Dec 2015
# Who         : edalrey
####################################################################
####################################################################
# Version5    : LTE 16B
# Revision    : CXP 903 0491-203-1
# Jira        : NSS-2424
# Purpose     : To resolve build errors for 10 nodes in dot cell script
# Description : Modified such that if no dot cells are created the
#               script should exit
# Date        : March 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : LTE 17A
# Revision    : CXP 903 0491-247-1
# Jira        : NSS-5368
# Purpose     : DOT cells not creating in simulations though build
#               is error free
# Description : Change the equality check condition so that skipping
#               of the scripts is done properly.
# Date        : Aug 2016
# Who         : xkatmri
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
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
    print "@helpinfo\n";exit(1);
}
# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){
    exit;
}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $nodecountinteger,@primaryCells;
local $nodecountfornodestringname;
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";
}
################################
# MAIN
################################
print "... ${0} started running at $date\n";
#   12 Cell Node breakdown
local $DOT12CELLRATIO=&getENVfilevalue($ENV,"DOT12CELLRATIO");
local @dot12CellNodeRatio=split(":",$DOT12CELLRATIO);
local $distributionInterval12Cell=$dot12CellNodeRatio[1];
local $distributedNodes12Cell=$dot12CellNodeRatio[0];
local $dotIntervalCounter12Cell=0;
local $distributedNodesCounter12Cell=0;
#   6 Cell Node breakdown
local $DOT6CELLRATIO=&getENVfilevalue($ENV,"DOT6CELLRATIO");
local @dot6CellNodeRatio=split(":",$DOT6CELLRATIO);
local $distributionInterval6Cell=$dot6CellNodeRatio[1];
local $distributedNodes6Cell=$dot6CellNodeRatio[0];
local $dotIntervalCounter6Cell=0;
local $distributedNodesCounter6Cell=0;
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){
    my $createAuxPlugInUnit=0;
    # get node name
    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

    $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
    # nasty workaround for error in &getLTESimStringNodeName
    if($nodecountinteger>$NUMOFRBS){
        $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
    }# end if
    else{
        $nodecountfornodestringname=$nodecountinteger;
    }# end workaround

    @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
    $cellNum=@primarycells;

    if ($cellNum == 12) {
        $dotIntervalCounter12Cell++;
        #######################################################################
        # determine if AuxPlugInUnit needs to be created for 'IRU'
        # i.e. ManagedElement>Equipment>AuxPlugInUnit:productData(productName)="IRU"
        #######################################################################
        if ($dotIntervalCounter12Cell > $distributionInterval12Cell) {
            $createAuxPlugInUnit=1;
            $distributedNodesCounter12Cell++;
        }
        if ($distributedNodesCounter12Cell >= $distributedNodes12Cell) {
            $dotIntervalCounter12Cell=0;
            $distributedNodesCounter12Cell=0;
        }
    }
    if ($cellNum == 6) {
        $dotIntervalCounter6Cell++;
        #######################################################################
        # determine if AuxPlugInUnit needs to be created for 'IRU'
        # i.e. ManagedElement>Equipment>AuxPlugInUnit:productData(productName)="IRU"
        #######################################################################
        if ($dotIntervalCounter6Cell > $distributionInterval6Cell) {
            $createAuxPlugInUnit=1;
            $distributedNodesCounter6Cell++;
        }
        if ($distributedNodesCounter6Cell >= $distributedNodes6Cell) {
            $dotIntervalCounter6Cell=0;
            $distributedNodesCounter6Cell=0;
        }
    }
    if (!$createAuxPlugInUnit) {
        $NODECOUNT++;
        next;
    }
    #################################
    # Start create AuxPlugInUnit
    #################################
    @MOCmds=();
    @MOCmds=qq^ CREATE
    (
        parent "ManagedElement=1,Equipment=1"
        identity "1"
        moType AuxPlugInUnit
        exception none
        nrOfAttributes 17
            "AuxPlugInUnitId" String "IRU"
            "administrativeState" Integer 1
            "availabilityStatus" Integer 0
            "faultIndicator" Integer 2
            "maintenanceIndicator" Integer 2
            "operationalIndicator" Integer 3
            "operationalState" Integer 1
            "piuType" Ref "null"
            "position" Integer 0
            "productData" Struct
                nrOfElements 5
                "productionDate" String ""
                "productName" String "IRU"
                "productNumber" String ""
                "productRevision" String ""
                "serialNumber" String ""
            "unitType" String "RU"
    )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    #################################
    # End create AuxPlugInUnit
    #################################

    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

    ################################
    # build MML script
    ################################
    @MMLCmds=(
        ".open ".$SIMNAME,
        ".select ".$LTENAME,
        ".start ",
        "useattributecharacteristics:switch=\"off\"; ",
        "kertayle:file=\"$NETSIMMOSCRIPT\";"
    );# end @MMLCmds

    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
    $NODECOUNT++;
}# end outer NODECOUNT while

#CXP 903 0491-203-1
if ( $NETSIMMMLSCRIPT eq "") {
    print "... ${0} ended running as no Dot cell were created at $date\n";
    exit;
    }

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
