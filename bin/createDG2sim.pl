#!/usr/bin/perl
# VERSION HISTORY
######################################################################################
#
#     Author : SimNet/epatdal 
#
#     User Story : OSS-55899,OSS-55904
#
#     Description : creates a LTE DG2 simulation as specified by the reqs. in
#                   the CONFIG.env section -> LTE DG2 Network Configuration
#                   The mandatory naming convention for DG2 sims and nodes are as below :
#                   LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 -> simulation name
#                   LTE01dg2ERBS0001 -> node name
#                   Handover Support Implemented for OSS-55899,OSS-55904
#                     1. DG2toDG2 # intra/inter - implemented 
#                     2. DG2toDG1 # NOT Implemented  
#                     3. DG2toWRAN # NOT Implemented  
#                     4. DG2toGSM # NOT Implemented  
#                     5. DG2toCDMA # NOT Implemented  
#                     6. DG2toCDMARTT # NOT Implemented 
#                                  
#     Syntax : createDG2sim.pl $SIMNAME
# 
#     Date : Feb 2015
#
######################################################################################
# Version     : LTE15B
# Revision    : CXP 903 0491-TEMP_FIX_NETSIM_PATCH_DUE
# User Story  : n/a
# Purpose     : Prevent NETSim crash when starting a large number of DG2 nodes
# Description : Force first 15 nodes to start on separate 'netsim servers' (processes);
#		then start all nodes in sim in parallel.
# Date        : 21 May 2015
# Who         : SimNet/edalrey
######################################################################################
# Version     : LTE 15.17
# Revision    : CXP 903 0491-184-1
# User Story  : NSS-739 
# Purpose     : A simulation can be created with nodes of more than one MIM version
# Description : Allows multiple MIM versions to be built on a single DG2 simulation,
#		IP addresses are assigned in a continuous sequence.
# Date        : 06 Nov 2015
# Who         : edalrey
######################################################################################
# Version     : LTE 16.2
# Revision    : CXP 903 0491-192-1
# User Story  : NS-3836
# Purpose     : Mib not properly loaded for DG2 nodes
# Description : Mib not properly loaded for DG2 nodes
# Date        : Jan 2016
# Who         : xsrilek
####################################################################
####################################################################
# Version4    : LTE 19.05
# Revision    : CXP 903 0491-350-1
# Jira        : NSS-23445
# Purpose     : Setting user as netsim 
# Description : LTE Design Change: Netsim user setting is missing
#               on few Simulations while building              
# Date        : Feb 2019
# Who         : xmitsin
####################################################################
####################################################################
# Version4    : LTE 19.05
# Revision    : CXP 903 0491-351-1
# Jira        : NSS-23484
# Purpose     : LTE Design POC: PM MOs missing issue workaround for Simnet
# Description : Workaround for Missing PM MOs
# Date        : Feb 2019
# Who         : xmitsin
####################################################################
# Version5    : LTE 20.03
# Revision    : CXP 903 0491-362-1
# Jira        : NSS-30189
# Purpose     : Sets CurrentJobState active.
# Description : CurrentJobState for Predef PmJobs should be active by default
# Date        : May 2020
# Who         : xmitsin
####################################################################
# Version6    : LTE 21.10
# Revision    : CXP 903 0491-374-1
# Jira        : NSS-35802
# Purpose     : Code Base change to assign free IP
# Description : Code Base change to assign free IP
# Date        : May 2021
# Who         : xmitsin
###################################################################
#  Environment
########################

########################
use FindBin qw($Bin);
use lib "$Bin/../lib/cellconfig";
use Cwd;
use POSIX;use LTE_General;
use LTE_NodeConfigurability;
########################
# Vars
########################
$date=`date`;
$PWD=`pwd`;
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETSIMDIR="/netsim/netsimdir/";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @netsim_output=();
local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
local $SCRIPTROOTDIR="$scriptpath";
local $SCRIPTDIR="$scriptpath";
local $NETSIMDIRPATH="/netsim/netsimdir/";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local $LOGFILE=$scriptpath;
$LOGFILE=~s/bin/log/;$LOGFILE=$LOGFILE."LTE-SIMS.log";

local $DATE=localtime;
local $SIMNAME=$ARGV[0];# the simulations to be updated

# START : DG2 network data from CONFIG.env
local $configpath=$scriptpath;
$configpath=~s/bin\//dat\//;
local $ENV="CONFIG.env";
local $DG2NETWORKCELLSIZE=&getENVfilevalue($ENV,"DG2NETWORKCELLSIZE");
local $DG2CELLNUM=&getENVfilevalue($ENV,"DG2CELLNUM");
local $DG2SIMBASE=&getENVfilevalue($ENV,"DG2SIMBASE");
local $DG2NODETYPE1=&getENVfilevalue($ENV,"DG2NODETYPE1");
local $DG2NODETYPE2=&getENVfilevalue($ENV,"DG2NODETYPE2");
local $DG2NODETYPE3=&getENVfilevalue($ENV,"DG2NODETYPE3");
local $DG2PORT=&getENVfilevalue($ENV,"DG2PORT");
local $DG2DESTPORT=&getENVfilevalue($ENV,"DG2DESTPORT");
local $DG2SIMSTART=&getENVfilevalue($ENV,"DG2SIMSTART");
local $DG2SIMEND=&getENVfilevalue($ENV,"DG2SIMEND");
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $DG2NODENAME=$SIMNAME;$DG2NODENAME=~s/.*-//;$DG2NODENAME=$DG2NODENAME."dg2ERBS";
local $LTE=$SIMNAME;$LTE=~s/.*-//;
######------------To get LTE node names ###############
local $LTENum=$SIMNAME;$LTENum=~s/.*-LTE//;
$LTENum=($LTENum+0);
# get nodes in last DG2 sim.+ last sim num
local $numberofpicosimsrequired=ceil($DG2NETWORKCELLSIZE/$DG2NUMOFRBS);
local $remainderofpiconodesinlastsim=($DG2NETWORKCELLSIZE%$DG2NUMOFRBS);
local $lastDG2simnum=($numberofpicosimsrequired+$DG2SIMSTART)-1;
if($lastDG2simnum<10){$lastDG2simnum="0$lastDG2simnum"};
local $lastDG2simname="LTE$lastDG2simnum";
local $NODECOUNT=1,$TYPE;
# END : DG2 network data from CONFIG.env

local $counter=0;
local @helpinfo=qq(
ERROR : need to pass 1 parameter to ${0}

Usage : ${0} <simulation name>

Example 1: ${0} <SIMNAME>

Example 2: ${0} LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01

Info : ${0} creates and node populates a DG2 sim.
       Sim. name creation example : 
       /netsim/netsimdir/LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01
       Sim. node name creation example :
       /netsim/netsimdir/LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01/LTE01dg2ERBS0001
); # end helpinfo         

open LOG, ">>$LOGFILE" or die $!;
print "... ${0} started running at $date\n";
print LOG "... ${0} started running at $date\n";

$SCRIPTROOTDIR=~s/LTESim.*//;
$SCRIPTROOTDIR=~s/LTE1.*//;# eg. /var/tmp/tep/MASTER

$SCRIPTDIR=~s/LTESim.*//;
$SCRIPTDIR2=~s/bin.*/dat\//;

#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
    print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
    print LOG "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure netsim inst in place
#-----------------------------------------
if (!(-e "$NETSIM_INSTALL_PIPE")){# ensure netsim installed
       print "FATAL ERROR : $NETSIM_INSTALL_PIPE does not exist on $netsimserver\n";exit(1);
       print LOG "FATAL ERROR : $NETSIM_INSTALL_PIPE does not exist on $netsimserver\n";exit(1);
}# end if
#############################
# verify script params
#############################
if (!( @ARGV==1)){
      print "@helpinfo\n";exit(1);
      print LOG "@helpinfo\n";exit(1);
}# end if


## DEPRICATING THIS CHECK AS THERE CAN BE ADDITIONAL hyphens FOR EACH MIM VERSION
## remove this before final commit
=pod
# check 3 dashs appears in simname
if (!($SIMNAME=~m/\w+\-\w+\-\w+\-/)){
    print "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01\n";
    print LOG "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01\n";
    exit(1);
}# end if
=cut

# check DG2 appears in simname
if (!($SIMNAME=~m/DG2/)){
        print "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01. 'DG2' is missing.\n";
        print LOG "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01. 'DG2' is missing.\n";
    exit(1);
}# end if
#############################
# verify if sim exists
#############################
print " check if sim already exists";
if (-d "$NETSIMDIR$SIMNAME"){$counter++;}
if (-e "$NETSIMDIR$SIMNAME.zip"){$counter++;}

if($counter==1){# sim exists
    print "INFO : $NETSIMDIR$SIMNAME already exists and is being deleted\n";
    print LOG "INFO : $NETSIMDIR$SIMNAME already exists and is being deleted\n";
    # build mml script
    @MMLCmds=(
                ".open ".$SIMNAME,
                ".selectnocallback network",
                ".stop -parallel",
                ".deletesimulation ".$SIMNAME
        );# end @MMLCmds
}

if($counter==2){# sim and zip exists
    print "INFO $NETSIMDIR$SIMNAME already exists and is being deleted\n";
    print LOG "INFO $NETSIMDIR$SIMNAME already exists and is being deleted\n";
    print "INFO $NETSIMDIR$SIMNAME.zip already exists and is being deleted\n";
    print LOG "INFO $NETSIMDIR$SIMNAME.zip already exists and is being deleted\n";
    # build mml script
    @MMLCmds=(
                ".open ".$SIMNAME,
                ".selectnocallback network",
                ".stop -parallel",
                ".deletesimulation $SIMNAME",
                ".deletesimulation $SIMNAME.zip"
        );# end @MMLCmds
}
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
#############################
# NETSim call
#############################
# execute mml script
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
# output mml script execution
 print "@netsim_output\n";
 print LOG "@netsim_output\n";
# remove mml script
unlink "$NETSIMMMLSCRIPT";
print "DLETE Script ended";
############################
@netsim_output=();
# main
#############################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DG2 nodes NETSim communcation and destination ports configuration
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Netconf Communications Port 
# NETCONF/SNMP = SNMP,SSH, and Netconf over SSH oe TLS for IS,... and COM/ECIM based NEs
# Agent UDP port:161
# Agent SNMP version9s):
# SNMPv3 ??
# Netconf Destination Port
# NETCONF/SNMP = SNMP,SSH, and Netconf over SSH oe TLS for IS,... and COM/ECIM based NEs
# Manager IP 0.0.0.0
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check for last sim and populate with remaining DG2 nodes

if($LTE=~m/$lastDG2simname/){$DG2NUMOFRBS=$remainderofpiconodesinlastsim;}

$SIMNAME=~ s/^\s+|\s+$//g;


#########################################################################################
#   Revision:0491-TEMP_FIX_NETSIM_PATCH_DUE
#########################################################################################
    local $numberOfNewServers;
    if($DG2NUMOFRBS<5){$numberOfNewServers=$DG2NUMOFRBS}
    else{$numberOfNewServers=5}
    @newServers=();
    for(my $counter=1; $counter <= $numberOfNewServers; $counter++) {
        push @newServers, &getLTESimStringNodeName($DG2SIMSTART,$counter);
    }
    my $serverSims = join " ", @newServers;


    @allNodes=();
    for(my $counter=1; $counter <= $DG2NUMOFRBS; $counter++) {
        push @allNodes, &getLTESimStringNodeName($DG2SIMSTART,$counter);
    }
    my $remainingSims = join " ", @allNodes;
##################################
##################################
my $cwd = cwd();
###system ("sh  $cwd/getNodeFromFtp.sh $SIMNAME");
print "INFO : Downloading the basic node template from netsim ftp\n";
print LOG "INFO : Downloading the basic node template from netsim ftp\n";
system ("sh /$cwd/getNodeFromFtp.sh $SIMNAME");
print "INFO : Basic node template downloaded \n";
print LOG "INFO :  Basic node template downloaded \n";


#########################Creating sim and port##############################
# build mml script
@MMLCmds=();
@MMLCmds=(
            ".open ".$SIMNAME,
            ".firstactivity",
            ".setactivity START",
            ".initialguistatus",
            ".createne checkport ".$DG2PORT,
            ".set preference positions 5",
    );# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

#my $arrayIndex=0;
my ($mimsRef, $countsRef) = &splitMimVersionsAndNodeCountsIntoTwoArrays($SIMNAME);
my @mims=@$mimsRef;
my @counts=@$countsRef;
my $nodeStartNumber=1;


for $key (@mims) {
    local $tempdg2nodetype="$DG2NODETYPE2 $key";
    $tempdg2nodetype==~ s/^\s+|\s+$//g;
    my $node=&getLTESimStringNodeName($DG2SIMSTART,$nodeStartNumber);
    $nodePrefix = substr($node,0,-5);
    print "node is $node\n";
    print "NodePrefix is $nodePrefix\n";
   # system (`nodePrefix=`${node:0:${#node}-5}``);
    
    @MMLCmds=();
    @MMLCmds=( 
            ".select NE01",
            ".set port ".$DG2PORT,
            ".createne subaddr ".$nodeStartNumber." subaddr no_value",
            ".set taggedaddr subaddr ".$nodeStartNumber." 1",
            ".createne dosetext external ".$DG2DESTPORT,
            ".set external ".$DG2DESTPORT,
            ".set ssliop no no_value",
            ".set save",
            ".modifyne newnames $nodePrefix 1",
            ".set save",
            ".select ".$node,
            ".start -force_new_server",
            ".setuser netsim netsim",
            "e MOIds = csmo:get_mo_ids_by_type(null,\"RcsPm:PmJob\"). \n e: lists:map(fun(MOId) -> Sid=cs_session_factory:create_internal_session(\"set_attr\",300),csmo:set_attributes_action(Sid,MOId,[{cs_namevalue,currentJobState,1,{enum,\"RcsPm:JobState\"}}]),cs_session:commit_chk(Sid),cs_session_factory:end_session(Sid) end, MOIds).",
            ".stop"
        );# end @MMLCmds
    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
    #$nodeStartNumber += $count;
    #$arrayIndex++;
}

 @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
  print "@netsim_output\n";
  print LOG "@netsim_output\n";
 
#######################################CLONING NODES#####################################
my $node=&getLTESimStringNodeName($DG2SIMSTART,$nodeStartNumber);
$nodeBase=substr($node, 0, -5);
$NodeNum=($DG2NUMOFRBS-1);


###############################   Check Pm Group On 1st Node          #################################
#<code to check pm count on first node>
    @MMLCmds=();
    @MMLCmds=(
            ".open ".$SIMNAME,
            ".select ".$node,
            ".start",
            "e installation:get_neinfo(pm_mib) .",
            "e length(csmo:get_mo_ids_by_type(null, \"RcsPm:PmGroup\")).",
            "e length(csmo:get_mo_ids_by_type(null, \"RcsPMEventM:EventGroup\")).",
            "e length(csmo:get_mo_ids_by_type(null, \"RcsPm:MeasurementType\")).",
            "e length(csmo:get_mo_ids_by_type(null, \"RcsPMEventM:EventType\")).",
            ".stop"
        );
$NETSIMMMLSCRIPT=&makeMMLscript("write",$MMLSCRIPT,@MMLCmds);
# execute mml script
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
print "@netsim_output\n";
print LOG "@netsim_output\n";
$netsim_output[7] =~ s/"|{|}|ok|,//g;
chomp ($netsim_output[7]);
my $MibFile= "/netsim/inst/zzzuserinstallation/ecim_pm_mibs/$netsim_output[7]";
open FILE, $MibFile or die "can't open $file: $!\n";
while(<FILE>)
{
    next unless /slot name=\"pmGroupId\"/;

    $NumOfPmGroup++;
}
close FILE;

open FILE1, $MibFile or die "can't open $file: $!\n";
while(<FILE1>)
{
    next unless /hasClass name=\"EventGroup\"/;

    $NumOfEventGroup++;
}
close FILE1;
open FILE2, $MibFile or die "can't open $file: $!\n";
while(<FILE2>)
{
    next unless /hasClass name=\"MeasurementType\"/;

    $NumOfMeasurementType++;
}
close FILE2;
open FILE3, $MibFile or die "can't open $file: $!\n";
while(<FILE3>)
{
    next unless /hasClass name=\"EventType\"/;

    $NumOfEventType++;
}
close FILE3;

chomp ($NumOfEventGroup);
unlink "$NETSIMMMLSCRIPT";
#####*****************************************COMPARE****###################################
#my $filename = '$PWD/Result.txt';
#open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
if (int($netsim_output[9]) >= $NumOfPmGroup) {
        print  "\nINFO :PASSED on $node PMGroup MO count is $netsim_output[9]\n";
        print LOG "\nINFO :PASSED on $node PMGroup MO count is $netsim_output[9]\n";
        }
     else {
        print  "\nINFO :ERROR on $node, Check if all the PMGroups are loaded or not, MO count is $netsim_output[9], It should be $NumOfPmGroup,the script will exit";
        print LOG "\nINFO :ERROR on $node, Check if all the PMGroups are loaded or not, MO count is $netsim_output[9], It should be $NumOfPmGroup,the script will exit"; #exit(1);
        }

if (int($netsim_output[11]) >= $NumOfEventGroup ) {
        print "\nINFO: PASSED, $node EventGroup MO count is $netsim_output[11]\n";
        print LOG "\nINFO: PASSED, $node EventGroup MO count is $netsim_output[11]\n";
}
else {
        print "\nERROR: Check if all the EventGroups are loaded or not on $node, Count is $netsim_output[11], It should be $NumOfEventGroup,the script will exit  \n";
        print LOG "\nERROR: Check if all the EventGroups are loaded or not on $node, Count is $netsim_output[11], It should be $NumOfEventGroup, the script will exit  \n"; #exit(1);
}


if (int($netsim_output[13]) >= $NumOfMeasurementType ) {
        print "\nINFO: PASSED, $node Measurement type MO count is $netsim_output[13]\n";
        print LOG "\nINFO: PASSED, $node Measurement type MO count is $netsim_output[13]\n";
}
else {
        print "\nERROR: Check if all the Measurement type are loaded or not on $node, Count is $netsim_output[13] , it should be $NumOfMeasurementType, the script will exit\n";
        print LOG "\nERROR: Check if all the Measurement type are loaded or not on $node, Count is $netsim_output[13] , it should be $NumOfMeasurementType, the script will exit\n"; #exit(1);
}

if (int($netsim_output[15]) >= $NumOfEventType ) {
        print LOG "\nINFO: PASSED, $node EventType MO count is $netsim_output[15]\n";
}
else {
        print "\nERROR: Check if all the EventTYpe are loaded or not on $node, Count is $netsim_output[15], it should be $NumOfEventType, the script will exit\n";
        print LOG "\nERROR: Check if all the EventTYpe are loaded or not on $node, Count is $netsim_output[15], it should be $NumOfEventType, the script will exit\n"; #exit(1);
}

####################################    CLONING NODES    ###############################################

@MMLCmds=(
        ".open ".$SIMNAME,
        ".select ".$node,
        ".clone $NodeNum $nodeBase 02",
        ".set save"
        
    );# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
###@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
@MMLCmds=();


################################
# Make MO & MML Scripts
################################
##my $nodeStartNumber=1;
##my $node=&getLTESimStringNodeName($DG2SIMSTART,$nodeStartNumber);
##while ($NODECOUNT<=$DG2NUMOFRBS){
##    $LTENAME=&getLTESimStringNodeName($LTENum,$NODECOUNT);
################################################
# build mml script
#script to set ManagedElement=nodename
################################################
##  @MMLCmds=(".open ".$SIMNAME,
##           ".select ".$LTENAME,
###          ".start ",
##            "setmoattribute:mo=\"ManagedElement=NE01\", attributes =\"managedElementId\(string\)=$LTENAME\"\;",
##            ".stop",
##            ".set save"
##  	   );# end @MMLCmds
##    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
##	$NODECOUNT++;
##}# end outer while DG2NUMOFRBS

#############################
# NETSim call
#############################
# execute mml script
 @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
# output mml script execution
 print "@netsim_output\n";
 print LOG "@netsim_output\n";

print " \n Assigning Free Ip addresses to the nodes \n ";
system (" sh /$cwd/assignFreeIps.sh $SIMNAME ");

################################
# CLEANUP
################################
$date=`date`;
# remove mml script
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
print LOG "... ${0} ended running at $date\n";
close(LOG);
################################
# Subs
################################
sub makeMMLscript{
    local ($fileaction,$mmlscriptname,@cmds)=@_;

        $mmlscriptname=~s/\.\///;
        if($fileaction eq "write"){
            if(-e "$mmlscriptname"){
                unlink "$mmlscriptname";
            }#end if
            open FH, ">$mmlscriptname" or die $!;
        }# end write

        if($fileaction eq "append"){
            open FH, ">>$mmlscriptname" or die $!;
        }# end append

        print FH "#!/bin/sh\n";
        foreach $_(@cmds){
        print FH "$_\n";
	    }
        close(FH);
        system("chmod 744 $mmlscriptname");

        return($mmlscriptname);
}# end makeMMLscript
#-----------------------------------------
#  END
#-----------------------------------------
