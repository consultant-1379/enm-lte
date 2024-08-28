#!/usr/bin/perl

use Config::Tiny;

### VERSION HISTORY
######################################################################################
#
#     Author : SimNet 
#
#     Description : creates multiple LTE simulations based on simulation configuration
#                   as defined in MULTISIMS.env
#                   ../utils/build_lte_multisims.pl MULTISIMS.env
#                   starts the following processes :
# 
#                   1. creates script logfile ../utils/build_lte_multisims.log
#                   2. copies the master for eg. LTE12.2.tar to individual folders 
#                      in /var/tmp/tep dir eg. /var/tmp/tep/LTE05 where LTE05 is the sim num
#                      as declared in ../dat/MULTISIMS.env
#                   3. untar the tarball 
#                   4. starts a xterm session as below example :
#                      /var/tmp/tep/LTE05/LTE12.2/bin/createLTESimsST.sh CONFIG.env
# 
#                   Note : this script is a launch sim build utility and when launched 
#                          the sim build process should be examined in the indivdual log files 
#                          as normal  
#        
#     Syntax : ./build_lte_multisims.pl MULTISIMS.env
#
#     -------------------------------------------------------------------------------
#        *** ERBS support *** ERBS support *** ERBS support *** ERBS support *** 
#            Date : July 2012
#     -------------------------------------------------------------------------------
#     -------------------------------------------------------------------------------
#        *** PICO support *** PICO support *** PICO support *** PICO support *** 
#            Date : Aug 2014 
#     -------------------------------------------------------------------------------
######################################################################################
######################################################################################
# Modified by           : Billy Dunne
# Modified on           : 08.09.14
# Revision              : CXP 903 0491-86-1
###
### VERSION HISTORY
# Ver1.03               : Modified to not rely on /etc/hosts file
# Purpose               : List available IP addresses on a netsim server
# Description           : List available IP addresses on a netsim server without using
#			  /etc/hosts file - will now work with all servers
#			  (physical and virtual)
# Date                  : 08 September 2014
# Who                   : Billy Dunne
######################################################################################
######################################################################################
# Version2        : LTE 15B
# Revision              : CXP 903 0491-123-1
# Purpose     : LTE GIT Migration, modified directory structure, 
#		update script directory paths.
#                
# Description : Modified directory structure, update script directory paths.
#			$SCRIPTROOTDIR=~s/LTESim.*//; >> $SCRIPTROOTDIR=~s/util.*//
#			$SCRIPTROOTDIR=~s/LTE1.*//; >> $SCRIPTROOTDIR=~s/lte.*//;
# JIRA        : CIS-5416 - US CIS-5416 CXP 903 0491-123-1
# Date        : February 2015 
# Who         : ejamfur
######################################################################################
# Verrion3    : LTE 15B
# Revision    : CXP 903 0491-136-1 
# Purpose     : Add DG2 node to multisims script 
# Description : Add modifyEnvVariableType sub; refactor to remove duplicate code 
# Date        : 03 Apr 2015
# Who         : edalrey
######################################################################################
# Version3    : LTE 15
# Revision    : CXP 903 0491-140-1
# Purpose     : Improve generation of LTE2<RAN> relation files 
# Description : Create lte/bin/nodeTypesForSims.env to map a simulation to a type of
#		node, e.g. CPP/DG2/PICO.
# Date        : 14 Apr 2015
# Who         : edalrey
######################################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-141-1
# Purpose     : Generate new ext n/w files for new MULTISIMS.env configs
# Description : Generate new ext n/w files for new MULTISIMS.env configs 
# Date        : 21/04/2015
# Who         : edalrey
######################################################################################
# Version5    : LTE 15B
# Revision    : CXP 903 0491-184-1
# UserStory   : NSS-739
# Purpose     : Update the CONFIG.env with DG2 multi-mim information
# Description :	Add multiple MIM versions to CONFIG.env, and add sum total of nodes per
#		simulation to CONFIG.env for DG2 simulations.
#		Introduce a new arguement (last) to script $totalNumberOfNodeOnSimulation,
#		since each simulation must have the same total number of nodes.
# Date        : 06 Nov 2015
# Who         : edalrey
######################################################################################
# Version6    : LTE 17A
# Revision    : CXP 903 0491-234-1
# UserStory   : NSS-4704
# Purpose     : Code change in LTE to handle latest naming of PICO simulations.
# Description : Changed such that it takes "16B-V2" from simname then appends WCDMA
#               to satisfy the NeType name.
# Date        : 30 June 2016
# Who         : xkatmri
######################################################################################
# Version7    : LTE 17A
# Revision    : CXP 903 0491-243-1
# UserStory   : NSS-5331
# Purpose     : Code change in LTE to handle different NE Type of PICO simulations.
# Description : Changed such that it takes care of differrent NE Type for PICO
# Date        : 25 July 2016
# Who         : xkatmri
######################################################################################
######################################################################################
# Version8    : LTE 17A
# Revision    : CXP 903 0491-271-1
# UserStory   : NSS-7837
# Purpose     : Turn off the xterms for Jenkins Build of LTE simulations
# Description : As we are not able to complete the build with Jenkins when xterms are
#               available, turning off them to proceed for the build in Jenkins
# Date        : 02 Oct 2016
# Who         : xsrilek
######################################################################################
######################################################################################
# Version9    : LTE 17A
# Revision    : CXP 903 0491-302-1
# UserStory   : NSS-13080
# Purpose     : Change the Port/DD on the Radio nodes for simulation design
# Description : Change the Port/DD on the Radio nodes for simulation design
# Date        : 10 July 2017
# Who         : xmitsin
######################################################################################
######################################################################################
# Version10   : LTE 18.10
# Revision    : CXP 903 0491-339-1
# UserStory   : NSS-18644
# Purpose     : Changing the Port/DD on the PICO nodes for simulation design
# Description : Changing the Port/DD & MIM Version on the PICO nodes for simulation design
# Date        : 23 May 2018
# Who         : zyamkan
######################################################################################
########################
#  Environment
########################
use FindBin qw($Bin);
use lib "$Bin/../lib/cellconfig";
use Cwd;
use LTE_General;
use LTE_OSS14;
use LTE_OSS15;
use LTE_NodeConfigurability;
########################
# Vars
########################
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MMLCmds=();
local $NETSIMMMLSCRIPT;
local @netsim_output=();
local $isJenkinsBuild="NO";

# CONFIG.env values
local $SIMDIR,$SIMBASE,$PORT,$DYNAMICPORT,$FTPDIR,$SIMSTART,$SIMEND,$LTENUM;
local $NODETYPE3,$NUMOFRBS,$NUMOF_FDDNODES,$TDDSIMNUM;
local $DESTPORT,$NODETYPE1,$NODETYPE2;

local @helpinfo=qq(
ERROR : need to pass 2 parameters to ${0}

Usage : ${0} <multisims configation file> <number of node per simulation>

Example1 : ${0} MULTISIMS.env 160
Example2 : ${0} RVMULTISIMS.env 160
Example3 : ${0} FTMULTISIMS.env 10

NOTE1 : ensure the $netsimserver DISPLAY is set
        and the host server access control program for
        X Windows is enabled (xhost +)

NOTE2 : the build tar eg. LTE12.2.tar must
        be created in $netsimserver $TEPDIR directory
        and manually extracted to for e.g.
        /var/tmp/tep/MASTER/lte

Info : ${0} creates multiple sims based on
direction in config file ../dat/RVMULTISIMS.env, FTMULTISIMS.env, MULTISIMS.env 
); # end helpinfo       

local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";

if(!($scriptpath=~/$TEPDIR/)){
    print "@helpinfo\n";exit(1);}# end if

local $SCRIPTROOTDIR="$scriptpath";
local $SCRIPTDIR="$scriptpath";

local $NETSIMDIRPATH="/netsim/netsimdir";
local $MULTISIMS="$scriptpath";
local $FTMULTISIMS="$scriptpath";
local $RVMULTISIMS="$scriptpath";

local $LOGFILE=${0};
$LOGFILE=~s/\.pl//;$LOGFILE=~s/\.\///;
$LOGFILE="log_".$LOGFILE;
$LOGFILE="$scriptpath/$LOGFILE.log";

$MULTISIMS=~s/util.*//;
$MULTISIMS=$MULTISIMS."dat/MULTISIMS.env";

$FTMULTISIMS=~s/util.*//;
$FTMULTISIMS=$FTMULTISIMS."dat/FTMULTISIMS.env";

$RVMULTISIMS=~s/util.*//;
$RVMULTISIMS=$RVMULTISIMS."dat/RVMULTISIMS.env";

local @filelines,@filelines2;
local $element,$element2,$tempelement;
local $DATE=localtime;
local $NETSIM_INSTALL_SHELL="/netsim/inst/netsim_shell";
local $SIMSCONFIG=$ARGV[0];# the simulations to be updated
local $totalNumberOfNodeOnSimulation=$ARGV[1];

local $CONFIG="CONFIG.env"; # script base CONFIG.env
$SIMSCONFIG=~s/^\s+//;$SIMSCONFIG=~s/\s+$//;
local $networkblockflag=0,$createsimflag=0,$timedelayflag=0;
local $NETWORKBLOCK,$SIMACTION,$TIMEDELAYPERNETWORKBLOCK,$SIMNAME,$SIMNUM,$MIM,$NODENUM;
local $MINTIMEDELAYPERNETWORKBLOCK,$TEMPSIMNAME;
local @configfiledata=();
local $counter=0;
local $DATE=`date`;
local $lscommand=`ls |grep -v .tar|grep -v .pl`;
local @showrunningsims=`echo .show simulations|/netsim/inst/netsim_pipe`;
local $tarcommand,$command1,$command2,$command3,$command4,$command5,$command6;
local $retval=0,$tarball,$networkflag=0;
local $simnumconfigfile="";
local $SIMNAMEZIP;
local @tempvirtualips,@virtualips,@sortedvirtualips;
local ($ip1,$ip2,$ip3,$tempip3,$ip4);
local $templine,$createLTEcommsport=0;
local @ipadd=(),$counter2=0;
local $offlinesims=0,$xtermcommand;
local $xtermscriptlaunchdir;
local $launchflag=0;
local $zzcounter=0;

local $PICONODETYPE3;
local $PICONODETYPE1="LTE";
local $PICONODETYPE2="PRBS";

# US CIS-5416 CXP 903 0491-123-1
$SCRIPTROOTDIR=~s/utils.*//;
$SCRIPTROOTDIR=~s/enm-lte.*//;# eg. /var/tmp/tep/MASTER

$SCRIPTDIR=~s/utils.*//;
$SCRIPTDIR=~s/$SCRIPTROOTDIR//;# eg.lte 
$SCRIPTDIR=~s/\///g;

# Revision : CXP 903 0491-86-1
### ebildun - modified ###
local $keyword="secondary";
local $local_ips="^127\\\.0\\\.0";

# Build a list of invalid ips to use in ip query string
local $invalid_ips='\.0$\|\.251$\|\.252$\|\.253$\|\.254$\|\.255$';
### ebildun - modified ###

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
if (!( @ARGV==2)){
      print "@helpinfo\n";exit(1);}# end if

if (!(-e "$NETSIM_INSTALL_SHELL")){# ensure netsim installed
       print "FATAL ERROR : $NETSIM_INSTALL_SHELL does not exist on $netsimserver\n";exit(1);
}# end if

if (!(-e "$MULTISIMS")){# ensure MUTISIMS.env exists
       print "FATAL ERROR : file $MULTISIMS does not exist\n";exit(1);
}# end if

if (!(-e "$RVMULTISIMS")){# ensure RVMUTISIMS.env exists
       print "FATAL ERROR : file $RVMULTISIMS does not exist\n";exit(1);
}# end if

if (!(-e "$FTMULTISIMS")){# ensure FTMUTISIMS.env exists
       print "FATAL ERROR : file $FTMULTISIMS does not exist\n";exit(1);
}# end if

if (!(($SIMSCONFIG eq "MULTISIMS.env")||($SIMSCONFIG eq "FTMULTISIMS.env")||($SIMSCONFIG eq "RVMULTISIMS.env"))){
     print "@helpinfo\n";exit(1);}# end if

if(length($SCRIPTROOTDIR)==0){
   print "$SCRIPTROOTDIR is not a valid script root dir - should be eg. /var/tmp/tep/MASTER\n";
   exit(1);
}# end if

if(length($SCRIPTDIR)==0){
   print "$SCRIPTDIR is not a valid script dir - should be eg. LTE12.2\n";
   exit(1);
}# end if

#---------------------------
# read config file
#---------------------------
# start  ensure the correct MULTISIMS is used
if($SIMSCONFIG eq "MULTISIMS.env"){
   print "MATCH\n";
   $MULTISIMS;
}
elsif($SIMSCONFIG eq "FTMULTISIMS.env"){
      $MULTISIMS=$FTMULTISIMS;
}
elsif($SIMSCONFIG eq "RVMULTISIMS.env"){
      $MULTISIMS=$RVMULTISIMS;
}
# end ensure the correct MULTISIMS is used

open FH, "<", "$MULTISIMS" or die $!;
 @filelines=<FH>;
close(FH);

# quick verification of mandatory config file values 
foreach $element(@filelines){
        if($element=~/\#/){next;}
        if($element=~/NETWORKBLOCK/){$networkblockflag=1;}
        if($element=~/CREATE/){$createsimflag=1;}
        if($element=~/DONOTCREATE/){$donotcreatesimflag=1;}
        if($element=~/TIMEDELAYPERNETWORKBLOCK/){$timedelayflag=1;}
}# end foreach

if($networkblockflag<1){
   print "FATAL ERROR : value NETWORKBLOCK does not exist in $MULTISIMS\n";exit(1);}
if($createsimflag<1){
   print "FATAL ERROR : value CREATE does not exist in $MULTISIMS\n";exit(1);}
if($timedelayflag<1){
   print "FATAL ERROR : value TIMEDELAYPERNETWORKBLOCK does not exist in $MULTISIMS\n";exit(1);}

# get MULTISIMS.env config file values
$element="";
foreach $element(@filelines){
        $element=~s/^\s+//;$element=~s/\s+$//;
        $tempelement=$element;
        $tempelement=~s/-.*//;

        if($element =~/\#/){next;}
        if($tempelement=~m/DONOTCREATE/){next;}
 
        if($element=~/NETWORKBLOCK/){
           $NETWORKBLOCK=$element;
           $configfiledata[$counter]=$NETWORKBLOCK;
           $counter++;  
        }# end if

        if($element=~/CREATE/){
           $SIMACTION=$element;
           $SIMACTION=~s/-.*//;
        }# end if

       if($element=~/CREATE/){
          $SIMNAME=$element;
          $SIMNAME=~s/.*REATE-//;
          $configfiledata[$counter]=$SIMNAME;
          $counter++;
       }# end if

       if($element=~/TIMEDELAYPERNETWORKBLOCK/){
          $TIMEDELAYPERNETWORKBLOCK=$element;
          $TIMEDELAYPERNETWORKBLOCK=~s/.*IMEDELAYPERNETWORKBLOCK=//;
          $MINTIMEDELAYPERNETWORKBLOCK=$TIMEDELAYPERNETWORKBLOCK;
       }# end if

}# end foreach

#-----------------------------------------
# setup logile file
#-----------------------------------------
open OUT,"> $LOGFILE" or die "Can't open $LOGFILE : $!";
print OUT '*' x 50 . "\n";
print OUT "Netsim Server : $netsimserver\n";
print OUT "Date : $DATE";
print  OUT '*' x 50 . "\n";

#---------------------------------------------------------------------
# CXP 903 0491-140-1 :	Improve generation of LTE2<RAN> relation files 
# 			create lte/bin/nodeTypesForSims.env  
#---------------------------------------------------------------------
local $nodeTypes=&createNodeTypesForSims($MULTISIMS);
print "Creating $nodeTypes for MULTISIM\n";
print OUT "Creating $nodeTypes\n";
#---------------------------------------------------------------------
local $externalNetworkDir=$scriptpath;
$externalNetworkDir=~s/.utils*/\/bin\/ERBSST/;
print "Creating EUtran Cell data\n";
$retval=system("cd $externalNetworkDir; ./archiveEUtranCelldata.pl;");
print "Creating LTE2WRAN utran relations\n";
$retval=system("cd $externalNetworkDir; ./createLTE2WRANutranrelations.pl; ");
print "Creating LTE2GRAN network data\n";
$retval=system("cd $externalNetworkDir; ./createnewconfigLTE2GRANnetworkdata.pl");

#-----------------------------------------------
# tar build scripts
#-----------------------------------------------
print "taring network build scripts -> $SCRIPTROOTDIR$SCRIPTDIR to $SCRIPTDIR.tar\n";
print OUT "taring network buildscripts -> $SCRIPTROOTDIR$SCRIPTDIR to $SCRIPTDIR.tar\n";

$command1="cd $SCRIPTROOTDIR";
$command1=~s/\n//;
$command1=~s/^\s+//;$command1=~s/\s+$//;

$tarcommand="tar -cvf $SCRIPTDIR.tar $SCRIPTDIR";
$tarcommand=~s/\n//;
$tarcommand=~s/^\s+//;$tarcommand=~s/\s+$//;

$retval=system("$command1/;$tarcommand >/dev/null 2>&1");

if($retval!=0){
   print "FATAL ERROR : unable to complete $command1..$tarcommand\n";
   print OUT "FATAL ERROR : unable to complete $command1..$tarcommand\n";
   exit(1);
}# end if

if (!(-e "$SCRIPTROOTDIR$SCRIPTDIR.tar")){# ensure tarball exists
       print "FATAL ERROR : file $SCRIPTROOTDIR$SCRIPTDIR.tar has not been created as expected\n";
       print OUT "FATAL ERROR : file $SCRIPTROOTDIR$SCRIPTDIR.tar has not been created as expected\n";
       exit(1);
}# end if

#-------------------------------------------------
# create and populate sim/node dirs as per config file
#-------------------------------------------------
$element="";
$TIMEDELAYPERNETWORKBLOCK=$TIMEDELAYPERNETWORKBLOCK*60;# changed to seconds

# run thru the simulations in either the MULTISIMS.env,FTMULTISIMS.env,RVMULTISIMS.env
# NETWORK BLOCKs

foreach $element(@configfiledata){ # start foreach @configfiledata

        if($element=~/TIMEDELAYPERNETWORKBLOCK/){next;}

        if($element=~/NETWORKBLOCK/){
          $networkflag++;
          if($networkflag>1){sleep($TIMEDELAYPERNETWORKBLOCK);}
          print "building sims in network block : $element\n";
          print OUT '*' x 50 . "\n";
          print OUT "building sims in network block : $element\n";
          print OUT '*' x 50 . "\n";
          print OUT "execution delay between NETWORKBLOCKS is $MINTIMEDELAYPERNETWORKBLOCK minutes\n";
          next;   
        }# end if

	local $generalSIMBASE	= &modifyEnvVariableType("SIMBASE",$element);
	local $generalSIMSTART	= &modifyEnvVariableType("SIMSTART",$element);
	local $generalSIMEND	= &modifyEnvVariableType("SIMEND",$element);
	local $generalPORT	= &modifyEnvVariableType("PORT",$element);
	local $generalDESTPORT	= &modifyEnvVariableType("DESTPORT",$element);
	local $generalNODETYPE1 = &modifyEnvVariableType("NODETYPE1",$element);
	local $generalNODETYPE2	= &modifyEnvVariableType("NODETYPE2",$element);
	local $generalNODETYPE3 = &modifyEnvVariableType("NODETYPE3",$element);
	local $generalNUMOFRBS	= &modifyEnvVariableType("NUMOFRBS",$element);

      if ( $element =~ /PICO/ ) { #For PICO simulation
             $MIM=$element;$MIM=~s/LTE//;$MIM=~s/x.*//;
             if ($MIM =~ /15B/) {
             @mim=split(/-/, $MIM);
             $MIM="${mim[0]}-LTE-ECIM-REF-${mim[1]}";
             }
             elsif ($MIM =~ /16A/) {
             @mim=split(/-/, $MIM);
             $MIM="${mim[0]}-LTE-ECIM-MSRBS-${mim[1]}";
             }
             elsif ($MIM =~ /16B/) {
             @mim=split(/-/, $MIM);
             $MIM="${mim[0]}-WCDMA-${mim[1]}";
             }
             else {
             @mim=split(/-/, $MIM);
             $MIM="${mim[0]}-${mim[1]}-LTE-WCDMA-${mim[2]}";
             }
       	     $NODENUM=$element;$NODENUM=~s/^.*x//;$NODENUM=~s/-.*//;
      } #end if
      elsif( $element =~ /DG2/) { #For DG2 simulation
             if( !(&verifyMimVersionSumToTotalNumberOfNodes($element,$totalNumberOfNodeOnSimulation)) ) {
            print "ERROR: The total number of nodes did not match the expected value: $totalNumberOfNodeOnSimulation.\nERROR: $element will NOT be build. Skipping to next simulations.\n";
            print OUT "ERROR: The total number of nodes did not match the expected value: $totalNumberOfNodeOnSimulation.\nERROR: $element will NOT be build. Skipping to next simulations.\n";
            next;
        }
        my ($mimVersionsRef, $nodeCountsRef) = &splitMimVersionsAndNodeCountsIntoTwoArrays($element);
        my @mimVersions = @$mimVersionsRef;
        $MIM = join ", ", @mimVersions;
        my @nodeCounts = @$nodeCountsRef;
        $NODENUM=0;
        for $count (@nodeCounts) {
            $NODENUM += $count;
        }
      } #end elsif
      else { #For ERBS simulation
		$MIM=$element;$MIM=~s/LTE//;$MIM=~s/x.*//;
		$NODENUM=$element;$NODENUM=~s/^.*x//;$NODENUM=~s/-.*//;
      } #end else

	$SIMNUM=$element;$SIMNUM=~s/.*-//;
        $SIMNAME=$element;$SIMNAMEZIP="$SIMNAME.zip";
        $LTENUM=$SIMNUM;$LTENUM=~s/LTE//;
        if($LTENUM<10){$LTENUM=~s/0//;}
        $SIMSTART="$SIMSTART$LTENUM";$SIMEND="$SIMSTART$LTENUM";
        $zzcounter++;

        print "creating script build folder $TEPDIR$SIMNAME\n";
        print OUT "creating script build folder $TEPDIR$SIMNAME\n";

        $command1="mkdir $TEPDIR$SIMNAME";
        $command2="cp -p $SCRIPTROOTDIR$SCRIPTDIR.tar $TEPDIR$SIMNAME/$SCRIPTDIR.tar";
        $command3="rm -rf $TEPDIR$SIMNAME";
        $command4="tar -xvf $SCRIPTDIR.tar";
        $command5="cd $TEPDIR$SIMNAME";
        $xtermscriptlaunchdir="$TEPDIR$SIMNAME/$SCRIPTDIR/bin/";

        if (-d "$TEPDIR$SIMNAME"){# ensure script build folder does not exists
           print "WARN : old folder $TEPDIR$SIMNAME exists and is being deleted\n";
           print OUT "WARN : old folder $TEPDIR$SIMNAME exists and is being deleted\n";
           
           $retval=system("$command3 >/dev/null 2>&1");
           if($retval!=0){
               print "WARN : unable to delete build script folder $TEPDIR$SIMNAME\n";
               print OUT "WARN : unable to delete build script folder $TEPDIR$SIMNAME\n";
               $retval=0;
           }# end inner if
 
        }# end outer if

        $retval=system("$command1/;$command2 >/dev/null 2>&1");# create build script folder
        if($retval!=0){
          print "WARN : unable to complete build script folder $TEPDIR$SIMNAME\n";
          print OUT "WARN : unable to complete build script folder $TEPDIR$SIMNAME\n";
          $retval=0;
        }# end if

        $retval=system("$command5;$command4 >/dev/null 2>&1");# extract script build tarball
        if($retval!=0){
           print "WARN : unable to extract build script tarball $TEPDIR$SIMNAME/$SCRIPTDIR.tar\n";
           print OUT "WARN : unable to extract build script tarball $TEPDIR$SIMNAME/$SCRIPTDIR.tar\n";
           $retval=0;
        }# end inner if

        if (-e "$NETSIMDIRPATH/$SIMNAMEZIP"){# ensure sim zip does not exist
           print "WARN : old zip $NETSIMDIRPATH$SIMNAMEZIP exists and is being deleted\n";
           print OUT "WARN : old zip $NETSIMDIRPATH$SIMNAMEZIP exists and is being deleted\n";
           $retval=unlink("$NETSIMDIRPATH/$SIMNAMEZIP");
           if($retval!=1){
               print "WARN : unable to delete $NETSIMDIRPATH/$SIMNAMEZIP\n";
               $retval=1;
           }# end inner if
        }# end outer if

        if(-d "$NETSIMDIRPATH/$SIMNAME"){# ensure sim does not already exist
           print "WARN : old sim $NETSIMDIRPATH/$SIMNAME exists and is being deleted\n";
           print OUT "WARN : old sim $NETSIMDIRPATH/$SIMNAME exists and is being deleted\n";

           @MMLCmds=(".open ".$SIMNAME,
                     ".select network",
                     ".stop",
                     ".delete"
           );# end @MMLCmds
         
           $NETSIMMMLSCRIPT=&makeMMLscript("write",$MMLSCRIPT,@MMLCmds);
           
           # execute mml script
           @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
          
           print OUT "@netsim_output\n";
         
           # remove mo script
           unlink "$NETSIMMMLSCRIPT"; 
        }# end outer if
        
        #------------------------------------------------------
        # offline all netsim server sims
        #------------------------------------------------------
        $element="";$offlinesims++;
        if($offlinesims==1){# if offlinesims
          foreach $element(@showrunningsims){
               if($element=~m/default/){next;}
               if($element=~/\.zip/){next;}
               if($element=~/>>/){next;}
               if(length($element)==1){next;}# blank simname
               $templine="INFO : $element is being offlined";
               $templine=~s/\n//; 
               print OUT "$templine\n";

               @MMLCmds=(".open ".$element,
                    ".select network",
                    ".stop"
               );# end @MMLCmds

               $NETSIMMMLSCRIPT=&makeMMLscript("write",$MMLSCRIPT,@MMLCmds);

               # execute mml script
               @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

               print OUT "@netsim_output\n";

               # remove mo script
               unlink "$NETSIMMMLSCRIPT";
          }# end foreach
        }# end outer if

        #------------------------------------------------------
        # update the newly created script build CONFIG.env
        # for the sim build execution
        #------------------------------------------------------
        $element="";$retval=0;
        $simnumconfigfile="$TEPDIR$SIMNAME/$SCRIPTDIR/dat/$CONFIG";
        $simnumconfigfile=~s/^\s+//;$simnumconfigfile=~s/\s+$//;
    
        if (!(-e "$simnumconfigfile")){# ensure script build CONFIG.env exists
             print "WARN : $simnumconfigfile does not exist\n";
             print OUT "WARN : $simnumconfigfile does not exist\n";
             next;
        }# end if

        # reading CONFIG.env 
        $retval=open (FH2,"$simnumconfigfile");
        if($retval!=1){
           print "WARN : unable to open $simnumconfigfile\n";
           print OUT "WARN : unable to open $simnumconfigfile\n";
           $retval=0;
           next; 
        }# end inner if
         
        @filelines2=<FH2>;
        close(FH2);

        #--------------------------------------------------
        # delete old CONFIG.env and rewrite with new values
        #--------------------------------------------------
        $element=""; 
        $retval=unlink("$simnumconfigfile");
        if($retval!=1){
           print "WARN : unable to open existing $simnumconfigfile\n";
           print OUT "WARN : unable to open existing $simnumconfigfile\n";
           $retval=0;
           next;
        }# end inner if

        $retval=open (FH3,"> $simnumconfigfile"); # create new node CONFIG.env
        if($retval!=1){
           print "WARN : unable to open newly created $simnumconfigfile\n";
           print OUT "WARN : unable to open newly created $simnumconfigfile\n";
           $retval=0;
           next;
        }# end inner if

        print OUT "updating newly created $simnumconfigfile\n"; 
        print "updating newly created $simnumconfigfile\n"; 

        foreach $element(@filelines2){ # start @filelines2

                ##################################
                # START CONFIG.env values
                ##################################  
                if($element=~/^SIMDIR=/){
                   foreach $tempelement(@filelines){
                           if($tempelement=~/^SIMDIR=/){
                              $SIMDIR=$tempelement;
                              last;
                           }# end inner if 
                   }# end inner foreach 
                   $SIMDIR=~s/VALUE1/$SIMNAME/;
                   $SIMDIR=~s/VALUE2/$SCRIPTDIR/;
                   print FH3 "$SIMDIR\n";
                   next; 
                }# end if

                if($element=~/^FTPDIR=/){
                   foreach $tempelement(@filelines){
                          if($tempelement=~/^FTPDIR=/){
                             $FTPDIR=$tempelement;
                             last;
                          }# end inner if
                   }# end inner foreach
                   print FH3 "$FTPDIR\n";
                   next;
                }# end if
		
		# Set all boundaries on LTE type networks
                if($element=~/^SIMSTART=/){
                        foreach $tempelement(@filelines){
                                if($tempelement=~/^SIMSTART=/){
                                        $SIMSTART=$tempelement;
                                        last;
                                }# end inner if
                        }# end inner foreach
			if(&isSimDG2($SIMNAME)=~m/YES/)
				{$SIMSTART=~s/VALUE1/0/;} 
			elsif(&isSimPICO($SIMNAME)=~m/YES/)
				{$SIMSTART=~s/VALUE1/0/;} 
			else	{$SIMSTART=~s/VALUE1/$LTENUM/;}
                        print FH3 "$SIMSTART\n";
                        next;
                }# end if    
                if($element=~/^SIMEND=/){
                        foreach $tempelement(@filelines){
                                if($tempelement=~/^SIMEND=/){
                                        $SIMEND=$tempelement;
                                        last;
                                }# end inner if
                        }# end inner foreach
			if(&isSimDG2($SIMNAME)=~m/YES/)
				{$SIMEND=~s/VALUE1/0/;} 
			elsif(&isSimPICO($SIMNAME)=~m/YES/)
				{$SIMEND=~s/VALUE1/0/;} 
			else	{$SIMEND=~s/VALUE1/$LTENUM/;}
                        print FH3 "$SIMEND\n";
                        next;
                }# end if    
		if($element=~/^PICOSIMSTART=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^PICOSIMSTART=/){
					$PICOSIMSTART=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
                        if(&isSimDG2($SIMNAME)=~m/YES/)
                                {$PICOSIMSTART=~s/VALUE1/0/;}
                        elsif(&isSimPICO($SIMNAME)=~m/YES/)
                                {$PICOSIMSTART=~s/VALUE1/$LTENUM/;}
                        else    {$PICOSIMSTART=~s/VALUE1/0/;}
			print FH3 "$PICOSIMSTART\n";
			next;
		}# end if
		if($element=~/^PICOSIMEND=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^PICOSIMEND=/){
					$PICOSIMEND=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
                        if(&isSimDG2($SIMNAME)=~m/YES/)
                                {$PICOSIMEND=~s/VALUE1/0/;}
                        elsif(&isSimPICO($SIMNAME)=~m/YES/)
                                {$PICOSIMEND=~s/VALUE1/$LTENUM/;}
                        else    {$PICOSIMEND=~s/VALUE1/0/;}
			print FH3 "$PICOSIMEND\n";
			next;
		}# end if
		if($element=~/^DG2SIMSTART=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^DG2SIMSTART=/){
					$DG2SIMSTART=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
                        if(&isSimDG2($SIMNAME)=~m/YES/)
                                {$DG2SIMSTART=~s/VALUE1/$LTENUM/;}
                        elsif(&isSimPICO($SIMNAME)=~m/YES/)
                                {$DG2SIMSTART=~s/VALUE1/0/;}
                        else    {$DG2SIMSTART=~s/VALUE1/0/;}
			print FH3 "$DG2SIMSTART\n";
			next;
		}# end if
		if($element=~/^DG2SIMEND=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^DG2SIMEND=/){
					$DG2SIMEND=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
                        if(&isSimDG2($SIMNAME)=~m/YES/)
                                {$DG2SIMEND=~s/VALUE1/$LTENUM/;}
                        elsif(&isSimPICO($SIMNAME)=~m/YES/)
                                {$DG2SIMEND=~s/VALUE1/0/;}
                        else    {$DG2SIMEND=~s/VALUE1/0/;}
			print FH3 "$DG2SIMEND\n";
			next;
		}# end if

		if($element=~/^$generalSIMBASE=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^$generalSIMBASE=/){
					$SIMBASE=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$TEMPSIMNAME=$SIMNAME;
			$TEMPSIMNAME=~s/\-$SIMNUM//; 
			$SIMBASE=~s/VALUE1/$TEMPSIMNAME/;
			print FH3 "$SIMBASE\n";
			next;
		}# end if

		if($element=~/^$generalPORT=/){
			local $tempPORT=$element;
			foreach $tempelement(@filelines){
				if($tempelement=~/^$generalPORT=/){
					$PORT=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$tempPORT=~s/^$generalPORT=//;
			# CXP 903 0491-82-1, 29/08/2014
			$tempPORT=~s/^\s+|\s+$//g;
			$PORT=~s/VALUE1/$tempPORT$zzcounter/;
			$PORT=~s/^\s+|\s+$//g;
			print FH3 "$PORT\n";
			next;
		}# end if

		if($element=~/^$generalDESTPORT=/){
			$tempDESTPORT=$element;
			foreach $tempelement(@filelines){
				if($tempelement=~/^$generalDESTPORT=/){
					$DESTPORT=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$tempDESTPORT=~s/^$generalDESTPORT=//;
			$tempDESTPORT=~s/^\s+|\s+$//g;
			$DESTPORT=~s/VALUE1/$tempDESTPORT$zzcounter/;
			$DESTPORT=~s/^\s+|\s+$//g;
			print FH3 "$DESTPORT\n";
			next;
		}# end if        

		if($element=~/^$generalNODETYPE3=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^$generalNODETYPE3=/){
					$NODETYPE3=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$NODETYPE3=~s/VALUE1/$MIM/;
			print FH3 "$NODETYPE3\n";
			next;
		}# end if

		if($element=~/^$generalNUMOFRBS=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^$generalNUMOFRBS=/){
					$NUMOFRBS=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$NUMOFRBS=~s/VALUE1/$NODENUM/;
			print FH3 "$NUMOFRBS\n";
			next;
		}# end if

		if($element=~/^NUMOF_FDDNODES=/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^NUMOF_FDDNODES=/){
					$NUMOF_FDDNODES=$tempelement;
					last;
				}# end inner if
			}# end inner foreach
			$NUMOF_FDDNODES=~s/VALUE1/$NODENUM/;
			print FH3 "$NUMOF_FDDNODES\n";
			next;
		}# end if

		if($element=~/^TDDSIMNUM/){
			foreach $tempelement(@filelines){
				if($tempelement=~/^TDDSIMNUM=/){
					$TDDSIMNUM=$tempelement;
					last;
				}# end inner if
			}# end inner foreach 
			print FH3 "$TDDSIMNUM\n";
			next;
		}# end if

                ##################################
                # END generic CONFIG.env values
                ##################################
              ##################################
              # END set LTE config data
              ##################################
               
              print FH3 "$element";

              ########################################      
              # START check if SIMNAME is of type LTE
              ########################################
              #------------------------------
              # start create LTE comms port
              #------------------------------
              $element2="",$counter=0;
              	
		# Legacy code
		#@tempvirtualips=`cat /etc/hosts`;
              # Revision : CXP 903 0491-86-1
	      ### ebildun - modified ###
   	      # Build the ip command query to list available IP addresses
	      local $ip_query_01="ip -4 addr show | grep -i \"$keyword\" | awk '{ print \$2}' | awk -F \"/\" '{ print \$1 }' | grep -v \"$local_ips\\\|$invalid_ips\" | grep -v \"\$\(hostname -i \)\" | sort -t \"\.\" -k 1n,1 -k 2n,2 -k 3n,3 -k 4n,4 -u";
	      # Assign the list of valid available ips to an array by running the created ip command query
	      @tempvirtualips=qx($ip_query_01);
	      ### ebildun - modified ###
              
	      foreach $element2 (@tempvirtualips){
                   if ($element2 !~ /([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)/) {
                       next;
                   }# end if
                   $element2=~s/\s.*//;
                   $element2=~ s/^\s+//;$element2=~s/\s+$//;
                   $virtualips[$counter]=$element2;
                   $counter++;
              }# end for each
              $element2="";
              @sortedvirtualips =sort{$a <=> $b} @virtualips;
              $createLTEcommsport++;

              # get free IPs
              if($createLTEcommsport==1){
                foreach $element2(@sortedvirtualips ){
                      ($ip1,$ip2,$ip3,$ip4)=$element2=~m/(\d+)\.(\d+)\.(\d+)\.(\d+)/;
                      if(($ip4>1)||($ip2==0)||($ip3==0)){next;}# end next if
                      if($ip4==1){
                         $ipadd[$counter2]="$ip1.$ip2.$ip3.0";
                      }# end inner if
                $counter2++;
                }# end foreach
              }# end if get free IPs
              #------------------------------
              # end create LTE comms port
              #------------------------------
              ########################################
              # END check if SIMNAME is of type LTE
              ########################################
        }# end foreach @filelines2
       close(FH3);
   #------------------------------
   # start build LTE comms port
   #------------------------------
   if(&isSimPICO($SIMNAME)=~m/NO/ && &isSimDG2($SIMNAME)=~m/NO/){# start if LTE sim.

	   if($ipadd[$pointer]==" "){# check for ip addresses
	      $pointer=0;# reset ipaddpointer 
	      print "WARN : no more IP addresses available on $netsimserver\n";
	      print OUT "WARN : no more IP addresses available on $netsimserver\n";
	      #exit(1); 
	   }# end if check for ip addresses
	   $DYNAMICPORT=$PORT;
	   $DYNAMICPORT=~s/^.*=//;

	   @MMLCmds=();
	   @MMLCmds=(".select configuration",
		     ".config add port ".$DYNAMICPORT." iiop_prot ".$netsimserver,
		     ".config port address ".$DYNAMICPORT." nehttpd ".$ipadd[$pointer]." 56834 56836 no_value", 
		     ".config save"
		 );# end @MMLCmds

	   $NETSIMMMLSCRIPT=&makeMMLscript("write",$MMLSCRIPT,@MMLCmds);

	   # execute mml script DEBUG
	   @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

	   print OUT "@netsim_output\n";

	   # remove mo script
	   unlink "$NETSIMMMLSCRIPT";
	   $pointer++;

   }# end if LTE sim.
   #------------------------------
   # end build LTE comms port
   #------------------------------

   #------------------------------------
   # start build DG2 comms/dest port
   #------------------------------------
   if(&isSimDG2($SIMNAME)=~m/YES/){# start if DG2 sim.
      $DYNAMICPORT=$PORT;
      $DYNAMICPORT=~s/^.*=//;
      $DYNAMICPORT=~s/\n//;

       #~~~~~~~~~~~~~~~~~~~~~~
       # NETCONF Comms Port
       #~~~~~~~~~~~~~~~~~~~~~~
       @MMLCmds=();
       @MMLCmds=(
		".select configuration",
             	".config add port ".$DYNAMICPORT." netconf_https_http_prot ".$netsimserver,
             	".config port address ".$DYNAMICPORT." ".$ipadd[$pointer]." 161 public 2 %unique 2 %simname_%nename authpass privpass 2 2",
        	".config save"
	);# end @MMLCmds
       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

      #~~~~~~~~~~~~~~~~~~~~~~~~~~
      # NETCONF Destination Port
      #~~~~~~~~~~~~~~~~~~~~~~~~~~
      $DESTPORT=~s/^.*=//;
      $DESTPORT=~s/\n//;

      @MMLCmds=();
      @MMLCmds=(
             ".config add external ".$DESTPORT." netconf_https_http_prot",
             ".config external servers ".$DESTPORT." ".$netsimserver,
             ".config external address ".$DESTPORT." 0.0.0.0 162 1",  
             ".config save"
            );# end @MMLCmds
      $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

     # execute mml script DEBUG
     @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

     print OUT "@netsim_output\n";

     # remove mo script
     unlink "$NETSIMMMLSCRIPT";
     $pointer++;

   }# end if DG2 sim.
   #----------------------------------
   # end build DG2 comms/dest port
   #----------------------------------

   #------------------------------------
   # start build PICO comms/dest port
   #------------------------------------
   if(&isSimPICO($SIMNAME)=~m/YES/){# start if PICO sim.
      $DYNAMICPORT=$PORT;
      $DYNAMICPORT=~s/^.*=//;
      $DYNAMICPORT=~s/\n//;

       #~~~~~~~~~~~~~~~~~~~~~~
       # NETCONF Comms Port
       #~~~~~~~~~~~~~~~~~~~~~~
       @MMLCmds=();
       @MMLCmds=(
                ".select configuration",
                ".config add port ".$DYNAMICPORT." netconf_prot ".$netsimserver,
                ".config port address ".$DYNAMICPORT." ".$ipadd[$pointer]." 161 public 2 %unique 2 %simname_%nename authpass privpass 2 2",
                ".config save"
        );# end @MMLCmds
       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

      #~~~~~~~~~~~~~~~~~~~~~~~~~~
       # NETCONF Comms Port
       #~~~~~~~~~~~~~~~~~~~~~~
       @MMLCmds=();
       @MMLCmds=(
                ".select configuration",
                ".config add port ".$DYNAMICPORT." netconf_prot ".$netsimserver,
                ".config port address ".$DYNAMICPORT." ".$ipadd[$pointer]." 161 public 2 %unique 2 %simname_%nename authpass privpass 2 2",
                ".config save"
        );# end @MMLCmds
       $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

      #~~~~~~~~~~~~~~~~~~~~~~~~~~
      # NETCONF Destination Port
      #~~~~~~~~~~~~~~~~~~~~~~~~~~
      $DESTPORT=~s/^.*=//;
      $DESTPORT=~s/\n//;

      @MMLCmds=();
      @MMLCmds=(
             ".config add external ".$DESTPORT." netconf_prot",
             ".config external servers ".$DESTPORT." ".$netsimserver,
             ".config external address ".$DESTPORT." 0.0.0.0 162 1",
             ".config save"
            );# end @MMLCmds
      $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

     # execute mml script DEBUG
     @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

     print OUT "@netsim_output\n";

     # remove mo script
     unlink "$NETSIMMMLSCRIPT";
     $pointer++;

   }# end if PICO sim.
   #----------------------------------
   # end build PICO comms/dest port
   #----------------------------------


   #check whether Jenkins build or not
   foreach $element(@filelines2){
     if($element=~/^JENKINSBUILD=YES/){
       $isJenkinsBuild="YES";
       last;
     }
     if($element=~/^JENKINSBUILD=NO/){
     $isJenkinsBuild="NO";
     last;
     }
   }
   #------------------------------
   # start launch script execution 
   #------------------------------
   $retval=0;

   #Turning off the xterms for Jenkins build
   if ($isJenkinsBuild eq "YES"){
     $xtermcommand="cd $xtermscriptlaunchdir;./createLTESimsST.sh CONFIG.env &";
   }
   else {
     $xtermcommand="xterm -e 2>/dev/null /bin/sh -c \"cd $xtermscriptlaunchdir;./createLTESimsST.sh CONFIG.env\" &";
   }
   
   print "starting Sim Build for $TEPDIR$SIMNAME\n";
   print OUT "starting Sim Build for $TEPDIR$SIMNAME\n";
   $launchflag++;
   $retval=system("$xtermcommand");
   if($retval!=0){
      print OUT "FATAL ERROR : encountered with Sim Build $TEPDIR$SIMNAME\n";
   }# end if 
   
   #------------------------------
   # end launch script execution
   #------------------------------
}# end foreach @configfiledata

print OUT "INFO : there are $launchflag sim builds launches\n"; 
$DATE=localtime;
print OUT '*' x 50 . "\n";
print OUT "${0} completed at $DATE\n";
print OUT '*' x 50 . "\n";
close (OUT);
print "${0} completed and logged to $LOGFILE\n";
#-----------------------------------------
#  END
#-----------------------------------------
# modiefies the Environment variable by prefixing it with "<empty string>"/"PICO"/"DG2" based on node type
sub modifyEnvVariableType {
	local ($env_file_constant,$simName)=@_;
	if($simName=~/PICO/){$env_file_constant="PICO".$env_file_constant;}
	elsif($simName=~/DG2/){$env_file_constant="DG2".$env_file_constant;}
	else{
		if($env_file_constant eq  "DESTPORT"){$env_file_constant="UNFINDABLE_".$env_file_constant;}
	}
	return $env_file_constant;
}
####################################################################################
#UPDATING IPS COUNT 
########################################################################
#
chdir "../dat";

my $Config = Config::Tiny->new;

$Config = Config::Tiny->read('CONFIG.env');
my $RV = $Config->{_}->{SWITCHTORV};
my $switchRV;

if($RV eq "NO"){
    $switchRV = "no";
}
else{
    $switchRV = "yes";
}
print "Switch To RV is given as $switchRV \n";

chdir "../utils";

########################################
#This will update IPs count in sims

print "Calling a shell script Script_to_UpdateIp.sh from this script :\n ";

my $sudo = `echo \"shroot\" | sudo -S su root`;

system("sh", "Script_to_UpdateIp.sh","$SIMNAME","$switchRV");

print "Completed...IP Details are updated in the Simulation folder....\n";

#-------------------------------------------------
#COMPLETED
#------------------------------------------------
