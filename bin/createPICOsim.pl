#!/usr/bin/perl
# VERSION HISTORY
######################################################################################
#
#     Author : SimNet/epatdal
#
#     Description : creates a LTE PICO simulation as specified by the reqs. in
#                   the CONFIG.env section -> LTE PICO Network Configuration
#                   The mandatory naming convention for PICO sims and nodes are :
#                   LTEMSRBSV1x160-RVPICO-FDD-LTE01 -> simulation name
#                   LTE01pERBS00001 -> node name
#
#     Syntax : createPICOsim.pl $SIMNAME
#
#     Date : Nov 2013
#
######################################################################################
######################################################################################
# Ver2        : LTE 15B
# Revision    : CXP 903 0491-123-1
# Purpose     : LTE GIT Migration, modified directory structure,update script
#		directory paths.
#
# Description : Modified directory structure, update script directory paths.
#			$SCRIPTROOTDIR=~s/LTESim.*//; >> $SCRIPTROOTDIR=~s/util.*//
#			$SCRIPTROOTDIR=~s/LTE1.*//; >> $SCRIPTROOTDIR=~s/lte.*//;
#			$SCRIPTDIR=~s/LTESim.*//; >> $SCRIPTROOTDIR=~s/bin.*//;
#
# JIRA        : CIS-5416 - US CIS-5416 CXP 903 0491-123-1
# Date        : February 2015
# Who         : ejamfur
######################################################################################
######################################################################################
# Version3    : LTE 17A
# Revision    : CXP 903 0491-229-1
# Jira        : NSS-4526
# Purpose     : Pico Network design as per the 17A SNID layout
# Description : Modify the codebase to build pico sims at any simulation number and
#               resolve an error of not building the simulation when only one simulation
#               is available in the PICO network
# Date        : 20-June-2015
# Who         : xsrilek
######################################################################################
######################################################################################
# Version4    : ENM 16.11
# Revision    : CXP 903 0491-232-1
# JIRA        : NSS-4707
# Purpose     : Mib not properly loaded for PICO nodes
# Description : While starting the nodes all the MOs in the mib are not getting
#               loaded correctly. To solve this starting single node after that
#               starting remaining all nodes.
# Date        : June 2016
# Who         : xkatrmi
######################################################################################
########################
#  Environment
########################
use Cwd;
use POSIX;
########################
# Vars
########################
$date=`date`;
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
local $LOGFILE=${0};
$LOGFILE=~s/\.pl//;$LOGFILE=~s/\.\///;
$LOGFILE="$scriptpath/$LOGFILE.log";
local $DATE=localtime;
local $SIMNAME=$ARGV[0];# the simulations to be updated

# START : PICO network data from CONFIG.env
local $configpath=$scriptpath;
$configpath=~s/bin\//dat\//;
local $ENV="CONFIG.env";
local $PICONETWORKCELLSIZE=&getENVfilevalue($ENV,"PICONETWORKCELLSIZE");
local $PICOCELLNUM=&getENVfilevalue($ENV,"PICOCELLNUM");
local $PICOSIMBASE=&getENVfilevalue($ENV,"PICOSIMBASE");
local $PICONODETYPE1=&getENVfilevalue($ENV,"PICONODETYPE1");
local $PICONODETYPE2=&getENVfilevalue($ENV,"PICONODETYPE2");
local $PICONODETYPE3=&getENVfilevalue($ENV,"PICONODETYPE3");
local $PICOPORT=&getENVfilevalue($ENV,"PICOPORT");
local $PICODESTPORT=&getENVfilevalue($ENV,"PICODESTPORT");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
local $PICOSIMEND=&getENVfilevalue($ENV,"PICOSIMEND");
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICONODENAME=$SIMNAME;$PICONODENAME=~s/.*-//;$PICONODENAME=$PICONODENAME."pERBS";
local $LTE=$SIMNAME;$LTE=~s/.*-//;
# get nodes in last PICO sim.+ last sim num
local $numberofpicosimsrequired=ceil($PICONETWORKCELLSIZE/$PICONUMOFRBS);
#local $remainderofpiconodesinlastsim=($PICONETWORKCELLSIZE%$PICONUMOFRBS);
local $remainderofpiconodesinlastsim;
local $lastPICOsimnum=($numberofpicosimsrequired+$PICOSIMSTART)-1;
if($lastPICOsimnum<10){$lastPICOsimnum="0$lastPICOsimnum"};
local $lastPICOsimname="LTE$lastPICOsimnum";

if ($PICONETWORKCELLSIZE==$PICONUMOFRBS*$numberofpicosimsrequired) {$remainderofpiconodesinlastsim=$PICONUMOFRBS;}
else {$remainderofpiconodesinlastsim=($PICONETWORKCELLSIZE%$PICONUMOFRBS);}
# END : PICO network data from CONFIG.env

local $counter=0;
local @helpinfo=qq(
ERROR : need to pass 1 parameter to ${0}

Usage : ${0} <simulation name>

Example 1: ${0} <SIMNAME>

Example 2: ${0} LTEMSRBSV1x160-RVPICO-FDD-LTE01

Info : ${0} creates and node populates a PICO sim.
       Sim. name creation example :
       /netsim/netsimdir/LTEMSRBSV1x160-RVPICO-FDD-LTE01
       Sim. node name creation example :
       /netsim/netsimdir/LTEMSRBSV1x160-RVPICO-FDD-LTE01/LTE01pERBS00001
); # end helpinfo

print "... ${0} started running at $date\n";

# US CIS-5416 CXP 903 0491-123-1
$SCRIPTROOTDIR=~s/util.*//;
$SCRIPTROOTDIR=~s/lte.*//;# eg. /var/tmp/tep/MASTER

$SCRIPTDIR=~s/bin.*//;
$SCRIPTDIR2=~s/bin.*/dat\//;
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
   print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure netsim inst in place
#-----------------------------------------
if (!(-e "$NETSIM_INSTALL_PIPE")){# ensure netsim installed
       print "FATAL ERROR : $NETSIM_INSTALL_PIPE does not exist on $netsimserver\n";exit(1);
}# end if
#############################
# verify script params
#############################
if (!( @ARGV==1)){
      print "@helpinfo\n";exit(1);}# end if

# check 3 dashs appears in simname
if (!($SIMNAME=~m/\w+\-\w+\-\w+\-/)){
    print "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBSV1x160-RVPICO-FDD-LTE01 \n";
    exit(1);
}# end if

# check PICO appears in simname
if (!($SIMNAME=~m/PICO/)){
    print "FATAL ERROR : $SIMNAME should have naming format eg. LTEMSRBSV1x160-FTPICO-FDD-LTE01 \n";
    exit(1);
}# end if
#############################
# verify if sim exists
#############################
# check if sim already exists
if (-d "$NETSIMDIR$SIMNAME"){$counter++;}
if (-e "$NETSIMDIR$SIMNAME.zip"){$counter++;}

if($counter==1){# sim exists
  print "INFO : $NETSIMDIR$SIMNAME already exists and is being deleted\n";
   # build mml script
   @MMLCmds=(".open ".$SIMNAME,
          ".selectnocallback network",
          ".stop -parallel",
          ".deletesimulation ".$SIMNAME
  );# end @MMLCmds
}

if($counter==2){# sim and zip exists
  print "INFO $NETSIMDIR$SIMNAME already exists and is being deleted\n";
  print "INFO $NETSIMDIR$SIMNAME.zip already exists and is being deleted\n";
   # build mml script
   @MMLCmds=(".open ".$SIMNAME,
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
# remove mml script
unlink "$NETSIMMMLSCRIPT";
############################
# main
#############################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PICO nodes NETSim communcation and destination ports configuration
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
# check for last sim and populate with remaining PICO nodes
if($LTE=~m/$lastPICOsimname/){$PICONUMOFRBS=$remainderofpiconodesinlastsim;}
#local $temppiconodetype="$PICONODETYPE1 $PICONODETYPE2 $PICONODETYPE3";
local $temppiconodetype="$PICONODETYPE2 $PICONODETYPE3";

# build mml script
@MMLCmds=();
@MMLCmds=(".new simulation ".$SIMNAME,
           ".firstactivity",
           ".setactivity START",
           ".initialguistatus",
           ".createne checkport ".$PICOPORT,
           ".set preference positions 5",
           ".new simne -auto ".$PICONUMOFRBS." ".$PICONODENAME." 00001",
           ".set netype ".$temppiconodetype,
           ".set port ".$PICOPORT,
           ".createne subaddr 1 subaddr no_value",
           ".set taggedaddr subaddr 1 1",
           ".createne dosetext external ".$PICODESTPORT,
           ".set external ".$PICODESTPORT,
           ".set ssliop no no_value",
           ".set save",
           ".select ".$PICONODENAME."00001",
           ".start -force_new_server",
           ".stop",
           ".select network",
           ".start"
  );# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
#############################
# NETSim call
#############################
# execute mml script
 @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
# output mml script execution
 print "@netsim_output\n";
################################
# CLEANUP
################################
$date=`date`;
# remove mml script
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
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
    foreach $_(@cmds){print FH "$_\n";}
    close(FH);
    system("chmod 744 $mmlscriptname");
    return($mmlscriptname);
}# end makeMMLscript
sub getENVfilevalue{
    local ($env_file_name,$env_file_constant)=@_;
    local @envfiledata=();
    local $env_file_value="ERROR";
    local $dir=cwd,$currentdir=$dir."/";
    local $scriptpath="$currentdir",$envdir;
    # navigate to dat directory
    $scriptpath=~s/lib.*//;$scriptpath=~s/bin.*//;
    $envdir=$scriptpath."dat/$env_file_name";
    if (!-e "$envdir")
       {print "ERROR : $envdir does not exist\n";return($env_file_value);}
    open FH, "$envdir" or die $!;
    @envfiledata=<FH>;close(FH);
    foreach $_(@envfiledata){
      if ($_=~/\#/){next;} # end if
      if ($_=~/$env_file_constant/)
          {$env_file_value=$_;$env_file_value=~s/^\s+//;
           $env_file_value=~s/^.*=//;
           $env_file_value=~s/\s+$//;} # end if
    }# end foreach
    return($env_file_value);
}# end getENVfilevalue
#-----------------------------------------
#  END
#-----------------------------------------
