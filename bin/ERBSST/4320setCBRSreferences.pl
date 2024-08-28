#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version3    : LTE 20.16
# Revision    : CXP 903 0491-368-1
# Jira        : NSS-28950
# Purpose     : Set CBRS support for DG2 TDD
# Description : To set DOT devices
# Date        : September 2020
# Who         : xharidu
####################################################################
# Version4    : LTE 21.18
# # Revision    : CXP 903 0491-369-1
# # Jira        : NSS-35689
# # Purpose     : Add CBRS support 4x4 DOT devices for DG2 TDD
# # Description : To set DOT devices
# # Date        : November 2021
# # Who         : znamjag
# ####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use POSIX;
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTE15B-v6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# check if SIMNAME is of type PICO or DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $cbrsFlag=&getENVfilevalue($ENV,"SET_CBRS");
local $nodecountinteger,$tempcellnum;
local $NODESIM;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
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
# MAIN
################################
################################
# Make MO & MML Scripts
################################
if (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE))) {
    print "\nThe cbrs configuration is not applicable ..\n";
    exit 0;
}

while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  # get node primary cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # set cell configuration ex: 6,3,3,1 etc.....
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
  $CELLNUM=@primarycells;

  $cbrsType=&getCbrsType($nodecountinteger,$CELLNUM);
  if ($cbrsType ne "4442_2x2" and $cbrsType ne "4442_4x4") {
        $NODECOUNT++;
        next;
  }
  @MOCmds=();
if ($cbrsType eq "4442_4x4") {

   #################################
   #  DOTS
   #################################
   #Setting references for multicastBranch ##
     $antennaGroupNum=1;
     $totalAntennas=int($CELLNUM);
     while($antennaGroupNum<$totalAntennas){
            ## Antenna Pairing ######
         $multicastCount = 1;
         while ($multicastCount <= 2) {

            $antenna1=$antennaGroupNum;
            $antenna2=$antennaGroupNum + 1;
            @MOCmds=qq^ SET
 (
  mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antenna1,ReqAntennaSystem:MulticastAntennaBranch=$multicastCount"
  exception none
  nrOfAttributes 1
  "transceiverRef" Array Ref 8
^;
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           my $frucount = (($antenna2 * 4) - 7);
           while ($frucount <= ($antenna2 * 4 )) {
              my $fieldReplaceableId="RD" . "-" . $frucount . "-1";
              @MOCmds=qq^          "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId,Transceiver=1"
^;
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $frucount++;
           }#end while
                @MOCmds=qq^)
^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           @MOCmds=qq^ SET
 (
  mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antenna2,ReqAntennaSystem:MulticastAntennaBranch=$multicastCount"
  exception none
  nrOfAttributes 1
  "transceiverRef" Array Ref 8
^;
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           $frucount = (($antenna2 * 4) - 7);
           while ($frucount <= ($antenna2 * 4 )) {
              my $fieldReplaceableId="RD" . "-" . $frucount . "-2" ;
              @MOCmds=qq^          "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId,Transceiver=1"
^;
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $frucount++;
           }#end while
                @MOCmds=qq^)
^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           
           $multicastCount++;
         }#end multicast while
            $antennaGroupNum+=2;
     }#end antennaGroup while
######################################################################################

         $antennaGroupNum=1;
         my  $frusuffix = 1;
         $antennaGroups=int($CELLNUM*4);
         while($antennaGroupNum<=$antennaGroups){

               my $fieldReplaceableId1="RD" . "-" . $antennaGroupNum . "-1" ;
               my $fieldReplaceableId2="RD" . "-" . $antennaGroupNum . "-2" ;
               my $fieldReplaceableIruId1="IRU" . "-" . $frusuffix ;
               my $fieldReplaceableIruId2="IRU" . "-" .($frusuffix + 1) ;
               if (($antennaGroupNum % 8) == 0) {
                  $rdiPort=8;
               } else  {
                  $rdiPort=($antennaGroupNum % 8); 
               }
               $rdiPort2=(8 - $rdiPort + 1);
               @MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldReplaceableId1,ReqRdiPort:RdiPort=1"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableIruId1,RdiPort=$rdiPort"
 )
SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldReplaceableId2,ReqRdiPort:RdiPort=1"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableIruId2,RdiPort=$rdiPort2"
 )
        
^;#end @MO
               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

               if (($antennaGroupNum%8) == 0) {
                    $frusuffix+=2;
               }
               $antennaGroupNum++;
         }#end antennaGroup while
         #Setting references for IRUs and RDs
         my $iruCount=1;
         while ($iruCount <= $totalAntennas) {

             my $iru1="IRU" . "-" . $iruCount;
             my $iru2="IRU" . "-" . ($iruCount + 1);
             my $rdiCount=1;
             my $frucount = ((($iruCount + 1) * 4) - 7);
             while ($frucount <= (($iruCount + 1) * 4)) {
                 $fieldReplaceableId1="RD" . "-" . $frucount . "-1" ;
@MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$iru1,ReqRdiPort:RdiPort=$rdiCount"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId1,RdiPort=1"
 )
^;
                 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                 $rdiCount++;
                 $frucount++;
              }# end rdiPort while
             my $rdiCount=8;
             my $frucount = ((($iruCount + 1) * 4) - 7);
             while ($frucount <= (($iruCount + 1) * 4)) {
                 $fieldReplaceableId2="RD" . "-" . $frucount . "-2";
@MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$iru2,ReqRdiPort:RdiPort=$rdiCount"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId2,RdiPort=1"
 )
^;
                 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                 $rdiCount--;
                 $frucount++;
              }#end rdi while
             $iruCount+=2;  
         }# end iru while
      }# end while for DOT
               

 elsif ($cbrsType eq "4442_2x2") {

   #################################
   #  DOTS
   #################################
   #Setting references for multicastBranch ##
     $antennaGroupNum=1;
     $totalAntennas=int($CELLNUM/2);
     while($antennaGroupNum<$totalAntennas){
            ## Antenna Pairing ######
         $multicastCount = 1;
         while ($multicastCount <= 2) {

            $antenna1=$antennaGroupNum;
            $antenna2=$antennaGroupNum + 1;
            @MOCmds=qq^ SET
 (
  mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antenna1,ReqAntennaSystem:MulticastAntennaBranch=$multicastCount"
  exception none
  nrOfAttributes 1
  "transceiverRef" Array Ref 8
^;
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           my $frucount = (($antenna2 * 4) - 7);
           while ($frucount <= ($antenna2 * 4 )) {
              my $fieldReplaceableId="RD" . "-" . $frucount . "-1";
              @MOCmds=qq^          "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId,Transceiver=1"
^;
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $frucount++;
           }#end while
                @MOCmds=qq^)
^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           @MOCmds=qq^ SET
 (
  mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqAntennaSystem:AntennaUnitGroup=$antenna2,ReqAntennaSystem:MulticastAntennaBranch=$multicastCount"
  exception none
  nrOfAttributes 1
  "transceiverRef" Array Ref 8
^;
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

           $frucount = (($antenna2 * 4) - 7);
           while ($frucount <= ($antenna2 * 4 )) {
              my $fieldReplaceableId="RD" . "-" . $frucount . "-2" ;
              @MOCmds=qq^          "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId,Transceiver=1"
^;
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              $frucount++;
           }#end while
                @MOCmds=qq^)
^;#end @MO
           $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
           
           $multicastCount++;
         }#end multicast while
            $antennaGroupNum+=2;
     }#end antennaGroup while
######################################################################################

         $antennaGroupNum=1;
         my  $frusuffix = 1;
         $antennaGroups=int($CELLNUM*2);
         while($antennaGroupNum<=$antennaGroups){

               my $fieldReplaceableId1="RD" . "-" . $antennaGroupNum . "-1" ;
               my $fieldReplaceableId2="RD" . "-" . $antennaGroupNum . "-2" ;
               my $fieldReplaceableIruId1="IRU" . "-" . $frusuffix ;
               my $fieldReplaceableIruId2="IRU" . "-" .($frusuffix + 1) ;
               if (($antennaGroupNum % 8) == 0) {
                  $rdiPort=8;
               } else  {
                  $rdiPort=($antennaGroupNum % 8); 
               }
               $rdiPort2=(8 - $rdiPort + 1);
               @MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldReplaceableId1,ReqRdiPort:RdiPort=1"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableIruId1,RdiPort=$rdiPort"
 )
SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$fieldReplaceableId2,ReqRdiPort:RdiPort=1"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableIruId2,RdiPort=$rdiPort2"
 )
        
^;#end @MO
               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

               if (($antennaGroupNum%8) == 0) {
                    $frusuffix+=2;
               }
               $antennaGroupNum++;
         }#end antennaGroup while
         #Setting references for IRUs and RDs
         my $iruCount=1;
         while ($iruCount <= $totalAntennas) {

             my $iru1="IRU" . "-" . $iruCount;
             my $iru2="IRU" . "-" . ($iruCount + 1);
             my $rdiCount=1;
             my $frucount = ((($iruCount + 1) * 4) - 7);
             while ($frucount <= (($iruCount + 1) * 4)) {
                 $fieldReplaceableId1="RD" . "-" . $frucount . "-1" ;
@MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$iru1,ReqRdiPort:RdiPort=$rdiCount"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId1,RdiPort=1"
 )
^;
                 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                 $rdiCount++;
                 $frucount++;
              }# end rdiPort while
             my $rdiCount=8;
             my $frucount = ((($iruCount + 1) * 4) - 7);
             while ($frucount <= (($iruCount + 1) * 4)) {
                 $fieldReplaceableId2="RD" . "-" . $frucount . "-2";
@MOCmds=qq^SET
 (
 mo "ComTop:ManagedElement=$LTENAME,ReqEquipment:Equipment=1,ReqFieldReplaceableUnit:FieldReplaceableUnit=$iru2,ReqRdiPort:RdiPort=$rdiCount"
 exception none
 nrOfAttributes 1
 "remoteRdiPortRef" Ref "ManagedElement=$LTENAME,Equipment=1,FieldReplaceableUnit=$fieldReplaceableId2,RdiPort=1"
 )
^;
                 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                 $rdiCount--;
                 $frucount++;
              }#end rdi while
             $iruCount+=2;  
         }# end iru while
      }# end while for DOT
               
      
   ################################
   ################################

      push(@NETSIMMOSCRIPTS,$NETSIMMOSCRIPT);

      # build mml script
      @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
      );# end @MMLCmds
 
      $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
      $NODECOUNT++;
}# end outer NODECOUNT while

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

