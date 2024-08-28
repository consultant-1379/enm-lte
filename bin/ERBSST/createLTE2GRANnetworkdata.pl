#!/usr/bin/perl
### VERSION HISTORY
######################################################################################
#
#     Author : SimNet (epatdal)
#
#     Description : Irathom enabled functionality (OSS 14A.1.7) to create 
#                   LTE to GRAN relations based on live simulated GSM data as supplied
#                   by the simulated GSM namely : thejaswini.ms21@wipro.com from the network 
#                   design team.
#                   builds and outputs files :
#
#                     ~/customdata/irathom/PublicIrathomGRAN2LTE.csv
#                     - this file is transferred from the GRAN to the LTE
#                       team and is used by LTE to build LTE to GRAN network
#                       to enable IRATHOM
#
#                    ~/customdata/irathom/PublicIrathomLTE2GRAN.csv
#                     - this file is transferred from the LTE to the GRAN
#                       team and is used by GRAN to build GRAN to LTE network
#                       to enable IRATHOM
# 
#                    ~/customdata/irathom/PrivateIrathomLTE2GRAN.csv
#                     - this file is used to build the LTE gsm network from
#                       the PublicIrathomGRAN2LTE.csv 
#                       and is used as input to the LTE scriptbase gsm scripts
#                       1279createExternalGeraNetwork.pl
#                       2133structsetEUtranGeranUtranRelations.pl
# 
#                    The data items below are read from the below CONFIG.env
#                    ~/dat/CONFIG.env
#                      IRATHOMGSMENABLED=YES
#                      IRATHOMGSMTTLCELLS=20000
#                      IRATHOMGSMLTEFILENAME=PublicIrathomGRAN2LTE.csv
#
#     Dependencies : GRAN to LTE input file as supplied by the GRAN network deployment team
#                    eg.PublicIrathomGRAN2LTE.csv
#
#     Syntax : ./createLTE2GRANnetworkdata.pl
#
#     Date : Nov 2013 
######################################################################################
####################################################################
# Version2    : LTE 14B
# Purpose     : add FreqGroup support to PrivateIrathomLTE2GRAN.csv 
# Comment     : needed to ensure even spread of frequency groups
# Jira        : NETSUP-1674/NETSUP-1673
# SNID        : LMI-14:001028
# Date        : June 2014
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 14B
# Purpose     : Workaround for 100% Irathom enabled GSM network
#               where GeranFrequencyGroup is used for unique GSM
#               frequencies/externalCells across the network to ensure
#               SNAD compliance where a GSM frequency can only
#               live in 1 GSM group
# Comment     : workaround1 - flag for script workaround location
# Jira        : NETSUP-1674/NETSUP-1673
# SNID        : LMI-14:001028
# Date        : 18 June 2014
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-135-1
# Purpose     : resolves an issue where TDD cells are represented 
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Jira        : NETSUP-2748 
# Description : ensure TDD and FDD cells are not represented 
#               incorrectly 
# Date        : Mar 2015
# Who         : epatdal
####################################################################
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
########################
# Vars
########################
local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
#------------------------
# verify CONFIG.env file
#------------------------
local $CONFIG="CONFIG.env"; # script base CONFIG.env
$ENV=$CONFIG;
local $linepattern= "#" x 100;
local $inputfilesize,$arrelement,$element;
local $tempcounter,$inputfileposition=0;
local $startdate=`date`;
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $IRATHOMDIR=$scriptpath;
$IRATHOMDIR=~s/bin.*/customdata\/irathom\//;

local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
local $NUMOF_FDDNODES=&getENVfilevalue($env,"NUMOF_FDDNODES");
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $NODECOUNT=1,$LTE;
local $match=0;
#-------------------------------------------
# Irathom Vars
# $IrathomInputFile : csv file as supplied
# 
# $IrathomOutputFile : csv file as supplied
#  
# $IrathomRelationFile : used in building
# Irathom GSM data in LTE network 
#------------------------------------------
local ($cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype);
local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMGSMLTEFILENAME");
$IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";
local $IrathomOutputFile="$IRATHOMDIR/PublicIrathomLTE2GRAN.csv";
local $IrathomRelationFile="$IRATHOMDIR/PrivateIrathomLTE2GRAN.csv";
local $IRATHOMGSMTTLCELLS=&getENVfilevalue($ENV,"IRATHOMGSMTTLCELLS");
local $IRATHOMGSMENABLED=&getENVfilevalue($ENV,"IRATHOMGSMENABLED");
local $NINTYFIVEPERCENTOFNETWORKNODES=(($NETWORKCELLSIZE/$CELLNUM28K)/100)*95; # 95% ofnetwork
$NINTYFIVEPERCENTOFNETWORKNODES=floor($NINTYFIVEPERCENTOFNETWORKNODES);
local $nodecounter=1;
# LTE14B
local $MAXGSMFREQGROUPS=10;# maximum number of frequency groups
#local $cellfreqgroupbreakdown=ceil($IRATHOMGSMTTLCELLS/$MAXGSMFREQGROUPS);
# GSM 20K attributes file has 32 frequencies * 4 groups = 128 unique frequencies
# to ensure spread across 9 GSM freqgroups (128/9=~14 frequencies per group)
# and ttlnodegerancellproxiespernode then frequencies per group = 12
local $cellfreqgroupbreakdown=12;
local $groupspernode=3; 
local $tempfreqgroup=1;
local $tempfreqgroup2;
local @freqandfreqgroup=();# takes note of assigned freq and freqgroup
local $tempfreqandfreqgroupcounter=0;
local $tempcellfreqgroupcounter=1;
local $elementinfreqandfreqgroup;
local ($arrayfreqgroup,$arraygroup);
local $arraygroupmatch=0;
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
# ensure $IrathomInputFile in place
#-----------------------------------------
if (!(-e "$IrathomInputFile")){
     print "FATAL ERROR : $IrathomInputFile does not exist\n";exit;
}# end if

# open csv GRAN to LTE input file for reading
local @IRATHOMGRAN2LTEFILENAME=();
open FH, "$IrathomInputFile" or die $!;
     @IRATHOMGRANLTEFILENAME=<FH>;
close(FH);

$inputfilesize=@IRATHOMGRANLTEFILENAME;

if($inputfilesize<$IRATHOMGSMTTLCELLS-1){
    print "FATAL ERROR : in file $IrathomInputFile\n";
    print "FATAL ERROR : file row size $inputfilesize is less than the required total GSM size of $IRATHOMGSMTTLCELLS\n";exit;
}# end if

# open private csv output LTE to GRAN file for writing
open FH2, "> $IrathomRelationFile" or die $!;

# open public csv output LTE to GRAN file for writing
# this file is transferred to GRAN for their network build
open FH3, "> $IrathomOutputFile" or die $!;

#########################
# main
##########################
local $csvinputfileline;

# write to file ~/customdata/irathom/PrivateIrathomLTE2GRAN.csv
print FH2 "$linepattern\n";
print FH2 "... ${0} started running at $startdate";
print FH2 "$linepattern\n";
print FH2 "# This file is generated from the GRAN to LTE Input File\n";
print FH2 "# Location is $IrathomInputFile\n";
print FH2 "$linepattern\n\n";
$date=`date`;

# write to file ~/customdata/irathom/PublicIrathomLTE2GRAN.csv
print FH3 "$linepattern\n";
print FH3 "... ${0} started running at $date";
print FH3 "$linepattern\n";
print FH3 "# This file is generated from the LTE Input File\n";
print FH3 "# Location is $IrathomRelationFile\n";
print FH3 "$linepattern\n\n";
#--------------------------------
# start build ttl gsm cell data
#--------------------------------
$ttlcellcounter=0;$LTE=0;
 
while($ttlcellcounter<=$IRATHOMGSMTTLCELLS){ # start outer while

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

   # start go thru cells
   $CID=1;$TACID=1;$CELLCOUNT=1;
   foreach $Cell (@primarycells) {
    $Frequency = getCellFrequency($Cell, $ref_to_Cell_to_Freq);
    # check cell type
    # SJ NETSUP-2748 - CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="EUtranCellFDD";
      $UL_Frequency = $Frequency + 18000;
    }# end if
    else{
      $TYPE="EUtranCellTDD";
    }# end else
   $CELLCOUNT++;$CID++;
   last;
   }# end foreach
   # end go thru cells

  # check network threshhold for ttl geran cell proxies per node
  if ($nodecountfornodestringname<=$NINTYFIVEPERCENTOFNETWORKNODES){
   $ttlnodegerancellproxiespernode=12; # per node 4 per cell * 3 groups
  }# end if
  else
  {$ttlnodegerancellproxiespernode=30;
  }# end else

  # read the input file cellname value
  $tempcounter=0;
  $tempfreqgroup2=$tempfreqgroup;

  while($tempcounter<$ttlnodegerancellproxiespernode){
    ($cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype)=split(/;/,&getIRATHOMcsvfilerawvalue($IRATHOMGRANLTEFILENAME[$inputfileposition]));
        if($cellname=~/FATAL ERROR/){last;}

        ################################
        # LTE14B start assign freqgroup
        ################################

        # increment freqgroup
        if($tempcellfreqgroupcounter>$cellfreqgroupbreakdown){
             $tempfreqgroup++;
             $tempcellfreqgroupcounter=1;
             if($tempfreqgroup>$MAXGSMFREQGROUPS){$tempfreqgroup=1;}
        }# end if

        # check for already existing freqgroup + freq
        foreach $elementinfreqandfreqgroup(@freqandfreqgroup){

            ($arrayfreqgroup,$arraygroup)=split(/\../,$elementinfreqandfreqgroup);
            
             if($arraygroup eq $bccno){
               $tempfreqgroup2=$arrayfreqgroup;
               $arraygroupmatch=1;
               last; 
             }# end if
             else {$tempfreqgroup2=$tempfreqgroup;$arraygroupmatch=0;}            

         }# end foreach

         # note freqgroup and freq
        if($arraygroupmatch==0){
          $freqandfreqgroup[$tempfreqandfreqgroupcounter]="$tempfreqgroup2..$bccno";
          $tempfreqandfreqgroupcounter++;
        }# end if

        ##############################
        # LTE14B end assign freqgroup
        ##############################

        print FH2 "$LTENAME;$cellname;$mcc;$mnc;$bscmncdigithand;$lac;$ci;$ncc;$bcc;$bccno;$csystype;$tempfreqgroup2\n";
        print FH3 "LTENodeName=$LTENAME;earfcn=$Frequency;BSCCellNum=$cellname\n";
        $tempcounter++;$inputfileposition++;
        $nodecounter++;
        $tempcellfreqgroupcounter++; 
  }# end while

  $NODECOUNT++;
 }# end while NUMOFRBS
 $ttlcellcounter=$ttlcellcounter+$ttlnodegerancellproxiespernode;
}# end outer while
#--------------------------------
# end build ttl utan cell data
#--------------------------------
#########################
# cleanup
#########################
$date=`date`;
print FH2 "$linepattern\n";
print FH2 "... ${0} ended running at $date";
print FH2 "$linepattern\n";
close(FH2);

print FH3 "$linepattern\n";
print FH3 "... ${0} ended running at $date";
print FH3 "$linepattern\n";
close(FH3);
#########################
# EOS
#########################
