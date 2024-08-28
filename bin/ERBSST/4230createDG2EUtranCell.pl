#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-151-1
# Jira        : OSS-77951
# Purpose     : To create cells according to required pattern on DG2
# Description : Creates DG2Eutrancells as defined in CONFIG.env 
# Date        : May 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77930
# Purpose     : Generalising methods of getting nondename & nodenum
# Description : Modifying methods getDG2SimStringNodeName & 
#		getDG2SimIntegerNodeNum to getLTESimStringNodeName &
#		getLTESimIntegerNodeNum
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version3    : LTE 15.16
# Revision    : CXP 903 0491-182-1
# Jira        : NSS-91
# Purpose     : maximumTransmissionPower attribute deprecated for
#               MIM version >= MRRBS-16A-V2 
# Description : deprecate maximumTransmissionPower attribute for
#               MIM version >= MRRBS-16A-V2
# Date        : Oct 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
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
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;

local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

# populate network grid with all cell data
local (@FULLNETWORKGRID)=&getAllNodeCells(2,1,$NETWORKCELLSIZE);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
# for node cells/adjacent cells

local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
local ($cellid,$latitutde,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup);
local @NETSIMMOSCRIPTS=();

# LTE14B.1 pci support
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pci\//;
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."innerPCInetwork.csv";
# cell channelbandwith values
local $command1="./writePCIinnerNetwork.pl";
local @bandwidthrange=qw/1400 3000 5000 10000 15000 20000/;
local $bandwidthrangesize=@bandwidthrange;
local $tempbandwidthrangesize=0;
local $CHANNELBANDWIDTH="";
local $channelbandwidthvalue;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}

# check innerPCInetwork file exits
if(!(-e $LTENetworkOutput)){
   print "Executing $command1 to create $LTENetworkOutput\n";
   
   $retval=system("$command1 >/dev/null 2>&1");
   if($retval!=0){
      print "FATAL ERROR : unable to create $LTENetworkOutput\n";
      $retval=0;
      exit;
   }# end inner if
}# end outer if
#####################
#Open file
#####################
local $filename = "$topologyDirPath/EUtranCell.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$DG2NUMOFRBS){
    #########################
    # MIM version support
    #########################
    local $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
    local $disableMaxTransPowerSupport=&isgreaterthanMIM($MIMVERSION,"16A-V2");
    local $maximumTransmissionPower;

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  $CELLCOUNT=1;

   foreach $Cell (@primarycells) {
    # check cell type
    if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      print "Creates ".$LTENAME."-".$CELLCOUNT." FDD Cell...\n";
      $TYPE="EUtranCellFDD";
      $CHANNELBANDWIDTH="dlChannelBandwidth";
    }# end if
    else{
      print "Creates ".$LTENAME."-".$CELLCOUNT." TDD Cell...\n";
      $TYPE="EUtranCellTDD";
      $CHANNELBANDWIDTH="channelBandwidth";
	# CXP 903 0491-135-1
	if($Frequency<36005){$Frequency=$Frequency+36004;}
    }# end else

    # set round robin channelbandwith range
    if($tempbandwidthrangesize>=$bandwidthrangesize){$tempbandwidthrangesize=0;}
    if($tempbandwidthrangesize<$bandwidthrangesize){
       $channelbandwidthvalue=$bandwidthrange[$tempbandwidthrangesize];
       $tempbandwidthrangesize++;
    }# end 
   
    # get node cell data
    ($gridrow,$gridcol)=&getCellRowCol($Cell,$NETWORKCELLSIZE);
    ($cellid,$latitude,$longitude,$altitude,$physicalLayerSubCellId,$physicalLayerCellIdGroup)=split(/\../,$FULLNETWORKGRID[$gridrow][$gridcol]); 
    print "Create $LTENAME Cell $LTENAME-$CELLCOUNT\n";
    
    # CXP 903 0491-182-1
    $maximumTransmissionPower=($disableMaxTransPowerSupport eq "yes") ? '' : "maximumTransmissionPower Int32 120"; 

    # build mo script
    @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=$LTENAME,ENodeBFunction=1"
       identity $LTENAME-$CELLCOUNT
         moType $TYPE
         exception none
         nrOfAttributes 9
           altitude Int32 $altitude
           $CHANNELBANDWIDTH Int32 $channelbandwidthvalue
           latitude Int32 $latitude
           longitude Int32 $longitude
           $maximumTransmissionPower
           physicalLayerCellIdGroup Int32 $physicalLayerCellIdGroup 
           physicalLayerSubCellId Int32 $physicalLayerSubCellId
           userLabel String $LTENAME-$CELLCOUNT
           administrativeState Integer 1
	       operationalState Integer 1
     );
    ^;# end @MO
print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
    $CELLCOUNT++;
  }# end inner CELL foreach

  
  # build mml script 
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
# remove mo scripts
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################

