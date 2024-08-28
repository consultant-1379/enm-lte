#!/usr/bin/perl
### VERSION HISTORY
####################################################################
####################################################################
# Version1    : NSS 18.02
# Revision    : CXP 903 0491-318-1
# Jira        : NSS-13559
# Purpose     : MO bulk up 
# Description : ENM requirement to add MO load
# Date        : Nov 2017
# Who         : xkatmri
#################################################################### 
####################################################################
# Version2    : LTE 20.14
# Revision    : CXP 903 0491-364-1
# Purpose     : Delete the System Created MOs
# Description : Deleting System created Mos
# Jira        : NSS-32040
# Date        : Aug 2020
# Who         : zanavee
#####################################################################
####################################################################
# Version3     : LTE21.03
# Revision     : CXP 903 0491-370-1
# Author       : Yamuna Kanchireddygari
# JIRA         : NSS-33640
# Description  : Set licensedCapacityLimit value to 32
# Date         : Dec 2020
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
# check if SIMNAME is of type DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $MOBulkEnabled=&getENVfilevalue($ENV,"ENABLEMOBULKUPDG2");
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
  
  # build mml script 
@MMLCmds=(".open ".$SIMNAME,
	".select ".$LTENAME,
	".start ",
	"useattributecharacteristics:switch=\"off\";",
"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,Lm=1\",type=\"FeatureState\",name=\"MO12\", quantity=1400;",
"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,Lm=1\",type=\"FeatureKey\",name=\"MO12\", quantity=1000;",
"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,Lm=1\",type=\"CapacityState\",name=\"MO12\", quantity=500;",
"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,Lm=1\",type=\"CapacityKey\",name=\"MO12\",attributes=\"licensedCapacityLimit (struct, LmCapacityValue)=[32,false]\", quantity=250;",
"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,HwInventory=1\",type=\"HwItem\",name=\"MO12\", quantity=500;",
"createmo:parentid=\"ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=1\",type=\"SfpModule\",name=\"MO12\", quantity=200;",
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
