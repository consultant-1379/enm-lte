#!/usr/bin/perl 
### VERSION HISTORY
########################################################################
# Version1    : LTE 16.1
# Revision    : CXP
# Jira        : NSS-330
# Purpose     : Sets the attribute syncReference 
# Description : Sets the following attribute syncReference under 
#		ManagedElement=1,TransportNetwork=1,Synchronization=1
# Date        : Dec 2015
# Who         : ejamfur
########################################################################
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
if (!( @ARGV==3)){ print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/ || &isSimDG2($SIMNAME)=~m/YES/){exit;}
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
while ($NODECOUNT <= $NUMOFRBS) { 

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);
  local $managedElement=&getManagedElement($LTENAME);
  
  @MOCmds=();
  @MOCmds=qq^ SET
  (
    mo "ManagedElement=$managedElement,TransportNetwork=1,Synchronization=1"
    exception none
    nrOfAttributes 1
    "syncReference" Array Ref 8
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=1"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=2"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=3"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=4"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=5"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=6"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=7"
        "ManagedElement=$managedElement,IpSystem=1,IpAccessHostEt=1,IpSyncRef=8"
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
