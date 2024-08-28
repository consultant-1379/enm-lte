#!/usr/bin/perl
### VERSION HISTORY
######################################################################################
# Description : writes a file to ~/customdata/pci/pcicoordinatesforinnernetwork.csv
#               which contains the 4 cellpoints that define an inner network for PCI  
# Jira        : NETSUP-1670
# SNID        : LMI-14:000993   
# Syntax      : ./writePCIInnerNetwork.pl
# Example     : ./writePCIInnerNetwork.pl
# Date        : May 2014
# who         : epatdal
######################################################################################
######################################################################################
# Version2    : LTE 14B.1
# Revision    : CXP 903 0491-90-1
# Purpose     : check cellnum increment does not become 0 valued
# Date        : September 2014
# Who         : edalrey
######################################################################################
######################################################################################
# Version3    : LTE 16A
# Revision    : CXP 903 0491-156-1
# Jira 	      : NETSUP-3078
# Purpose     : Rectify inifinite loop error
# Description : Exit while loop when $CELLNUM == 0
# Date        : June 2015
# Who         : ejamfur
######################################################################################
########################
#  Environment
########################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use POSIX;
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS12;
use LTE_OSS13;
use LTE_OSS14;
########################
# Vars
########################
local @helpinfo=qq(

Usage : ${0} 
Example: $0 

Description  : this script creates a LTE inner network for PCI
               listing the 4 boundary points as boundarypoint1,2,3 and 4 of the inner network
               listed in for ex: ~/customdata/pci/LTE28KinnerPCInetwork.csv 
               for a 28K LTE network);

local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
#------------------------
# verify CONFIG.env file
#------------------------
local $CONFIG="CONFIG.env"; # script base CONFIG.env
$ENV=$CONFIG;
local $MINCELLSIZE; 
$MINCELLSIZE=$ARGV[0];
local $linepattern= "#" x 100;
local $inputfilesize,$arrelement,$element;
local $tempcounter,$inputfileposition=0;
local $startdate=`date`;
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pci\//;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");

local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");

local $SIMSTART=&getENVfilevalue($ENV,"SIMSTART");
local $SIMEND=&getENVfilevalue($ENV,"SIMEND");

# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $NODECOUNT=1,$LTE,$PICOLTE;
local $match=0;
local ($cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype);
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."innerPCInetwork.csv";
local $nodecounter=1;
local @LTEnetworknodes=();
local $LTEnetworkcounter=0;
local $PCIINNERNETWORKENABLED=&getENVfilevalue($ENV,"PCIINNERNETWORKENABLED");
local $PCIINNERNETWORKPERCENT=&getENVfilevalue($ENV,"PCIINNERNETWORKPERCENT");
#########################
# verification
#########################
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
   print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure params are as expected
#-----------------------------------------
if (!( @ARGV==0)){
print "@helpinfo\n";exit(1);}

if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#-----------------------------------------
# ensure innerPCInetwork file created
#-----------------------------------------
open FH1, "> $LTENetworkOutput" or die $!;
#########################
# main
##########################
local $csvinputfileline;

print FH1 "$linepattern\n";
print FH1 "... ${0} started running at $startdate";
print FH1 "$linepattern\n";
print FH1 "# LTE14B.1 innerPCInetwork - see SNID LMI-14:000993 for details\n";
print FH1 "# Note : innerPCInetwork boundary points are listed as cell 1 of node ex: LTE01ERBS00068..3..boundarypoint1\n";
print FH1 "         tags cell 1 of LTE01ERBS00068 as innerPCInetwork boundarypoint1\n";           
print FH1 "         The relevant innerPCInetwork boundaries are listed as : -\n";
print FH1 "         boundarypoint1,boundarypoint2,boundarypoint3 and boundarypoint4 in file :-\n"; 
print FH1 "         $LTENetworkOutput\n";
print FH1 " Columns = Nodename..cellsize..optional tag for boundarypoint\n";
print FH1 "$linepattern\n\n";
#-----------------------------------
# start build PICO2LTE associations
#-----------------------------------
$ttlcellcounter=0;$LTE=0;
################################
# start get LTE network by cell 
################################
while($ttlcellcounter<=$NETWORKCELLSIZE){ # start outer while NETWORKCELLSIZE

 $NODECOUNT=1;$LTE++;

 while ($NODECOUNT<=$NUMOFRBS){ # start while NUMOFRBS
   # get node name
   $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
    
   # get the node eutran frequency id
   $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
   $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);

   # nasty workaround for error in &getLTESimStringNodeName
   if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
   }# end if
   else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

   # get node flexible primary cells
   @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
   $CELLNUM=@primarycells;

   # check node cell size does not exceed NETWORKCELLSIZE
   # CXP 903 0491-157-1
   # Exits outer while loop CELLNUM == 0
   if(($ttlcellcounter>=$NETWORKCELLSIZE)||($CELLNUM==0)){
	$ttlcellcounter=$NETWORKCELLSIZE;
	last;
    }

   ######################
   # start go thru cells
   ######################
   $CID=1;$TACID=1;$CELLCOUNT=1;
   foreach $Cell (@primarycells) {
    $Frequency = getCellFrequency($Cell, $ref_to_Cell_to_Freq);
    # check cell type
    if (&isCellFDD($ref_to_Cell_to_Freq, $Cell)) {
      $TYPE="EUtranCellFDD";
      $UL_Frequency = $Frequency + 18000;
    }# end if
    else{
      $TYPE="EUtranCellTDD";
    }# end else
   $CELLCOUNT++;$CID++;
   last;
   }# end foreach
   ####################
   # end go thru cells
   ####################

   # cycle thru the LTE network and get LTE nodes and cells
    $LTEnetworknodes[$LTEnetworkcounter]="$LTENAME..$CELLNUM";
    $LTEnetworkcounter++;

  $CELLCOUNT=1;
  $NODECOUNT++;
  $ttlcellcounter=$CELLNUM+$ttlcellcounter;

 }# end while NUMOFRBS

  # check node cell size does not exceed NETWORKCELLSIZE
  if($ttlcellcounter>=$NETWORKCELLSIZE){last;}

}# end outer while NETWORKCELLSIZE
################################
# end get LTE network by cell 
################################
################################
# start calculate inner network
################################
local $poscellborder1;
local $poscellborder2;
local $poscellborder3;
local $poscellborder4;
local $tempposcellborder;
local $splitltename;
local $splitcellnum;
local $tempcellnum=0;

local $innernetworkcellsize=ceil(($NETWORKCELLSIZE*$PCIINNERNETWORKPERCENT)/100);
# ex: 10000 innerPCInetwork has 100 borders square ie. (100*100)=10000 cells

local $innernetworkbordersize=ceil(sqrt($innernetworkcellsize));
# convert cells to nodes in order to query innerPCInetwork.csv
$innernetworkbordersize=ceil($innernetworkbordersize/$CELLNUM28K);

local $networksize=@LTEnetworknodes;

if($networksize<1){
   print "FATAL ERROR : networksize for array LTEnetworknodes incorrect at $networksize\n";
   exit;
}# end if

# check network nodes are correct
local $networknodes=floor($NETWORKCELLSIZE/$CELLNUM28K);
if($networknodes<1){
   print "FATAL ERROR : expected nodes of $networknodes is incorrect\n";
   exit;
}# end if

# find starting poscellborder1
$poscellborder1=ceil($networksize/3);
$poscellborder2=$poscellborder1+$innernetworkbordersize;

# find ending poscellborder4
$tempposcellborder=$poscellborder1;

while($tempcellnum<=$innernetworkcellsize){
      ($splitltename,$splitcellnum)=split(/\.\./,$LTEnetworknodes[$tempposcellborder]);
       $tempcellnum=$splitcellnum+$tempcellnum;
       if($tempcellnum>=$innernetworkcellsize){last;}
       $tempposcellborder++;     
}# end while

$poscellborder4=$tempposcellborder++;
$poscellborder3=$poscellborder4-$innernetworkbordersize;

################################
# end calculate inner network
################################
################################
# write out network with 
# innerPCIborders tagged
################################
local $tempcounter=0;

while($tempcounter<=$networksize){
      if($tempcounter==$poscellborder1){
         print FH1 "$LTEnetworknodes[$tempcounter]..boundarypoint1\n";
         $tempcounter++;
         next;
      }# end if

      if($tempcounter==$poscellborder2){
         print FH1 "$LTEnetworknodes[$tempcounter]..boundarypoint2\n";
         $tempcounter++;
         next;
      }# end if

      if($tempcounter==$poscellborder3){
         print FH1 "$LTEnetworknodes[$tempcounter]..boundarypoint3\n";
         $tempcounter++;
         next;
      }# end if 

      if($tempcounter==$poscellborder4){
         print FH1 "$LTEnetworknodes[$tempcounter]..boundarypoint4\n";
         $tempcounter++;
         next;
      }# end if
     
      print FH1 "$LTEnetworknodes[$tempcounter]\n";
      $tempcounter++;
}# end while
#########################
# cleanup
#########################
$date=`date`;
print FH1 "$linepattern\n";
print FH1 "... ${0} ended running at $date";
print FH1 "$linepattern\n";
close(FH1);
#########################
# EOS
#########################
