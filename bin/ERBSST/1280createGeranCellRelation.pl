#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# version1    : LTE 12.0 ST Simulations 
# purpose     : creates GSM external network 
# description : as per reqs. in OSS 12.0 LTE16K TERE 
# cdm         : 1/152 74-AOM 901 075 PA13  
# date        : June 2011
# who         : epatdal
# Updated     : Nov 2011 - included 12.0 patches
####################################################################
####################################################################
# Version2    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version4    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version5    : LTE 13B
# Revision    : 4
# Purpose     : Sprint 0.5 - Cell Reselection Priority
# Description : reset freq band cellReselectionPriority attribute
#               in accordance with below assignment ruleset :
#               GSM = 1
#               CDMA2000 = 2
#               UMTS = 3
#               CDMA2001 x rtt = 4
#               LTE = 5
# Date        : Jan 2013
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 14.1.7
# Revision    : CXP 903 0491-36
# Jira        : NETSUP-992
# Purpose     : Support for a LTE Irathom enabled GSM network
# Date        : Dec 2013
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 14A
# Revision    : CXP 903 0491-42-19
# Jira        : NETSUP-1019
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Jan 2014
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 14.1.7
# Revision    : CXP 903 0491-36
# Jira	      : NETSUP-992
# Purpose     : Ensure all 20000 external gsm cells in the LTE 28K network
#               are irathom enabled and not simulated - see Workaround2
# Date        : Jan 2014
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 14.2
# Revision    : CXP 903 0491-73-1
# Jira        : NETSUP-1674/NETSUP-1673
# Purpose     : Enable Irathom for LTE2GRAN using file as supplied by the GSM network
#               namely - ~/customdata/irathom/PrivateIrathomLTE2GRAN.csv
#               to write 20K GSM in the LTE network
# SNID        : LMI-14:001028
# Date        : May 2014
# Who         : epatdal
####################################################################
####################################################################
# Version10   : LTE 14B.1
# Revision    : CXP 903 0491-74-1 
# Jira        : NETSUP-1674/NETSUP-1673
# Purpose     : Support to establish LTE2GSM handover to already
#               deployed GSM to enable Irathom testing for GSM
#               configuration for MIM < E1180
#               Known restrictions with solution
#               1. LTE network populated groups = 1 - 10
#               2. 2 empty groups per LTE node ie. 11 and 12
#               3. some nodes can have 4 groups - issue with 124 frequencies/10 groups
#               4. SNAD anomaly frequency update executed for node groups > 3
# Comment     : updated to enable LTE2GSM configuration (< E1180) handover 2 GSM network
# SNID        : LMI-14:001028
# Date        : 20 July 2014
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 14B.1
# Revision    : CXP 903 0491-100-1
# Purpose     : Correct SNAD issue 17 seen in LTE network
# Description : Populate GeranFreqGroupRelation::geranFreqGroupRef to
#		        point to relevant GeranFreqGroup.
# Date        : Nov 2014
# Who         : edalrey
####################################################################
####################################################################
# Version12   : LTE 15B
# Revision    : CXP 903 0491-105-1
# Purpose     : Support to establish LTE2GSM handover for "old model" GSM
#               configuration ie. <= E1180
# Comment     : updated to enable LTE2GSM configuration (<= E1180)
#               handover LTE2GSM network
# SNID        : LMI-14:001028
# Date        : Dec 2014
# Who         : epatdal
####################################################################
####################################################################            
# Version13   : LTE 15B         
# Revision    : CXP 903 0491-112-1              
# Purpose     : Extend freq group's 3rd range 
# Description : Extend the range for freq group from 6<value<=9 to
#               6<value<=10. To account for new PrivateNewConfigIrathomLTE2GRAN.csv 
# Date        : 10 Dec 2014             
# Who         : edalrey         
#################################################################### 
####################################################################
# Version14   : LTE15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version15   : LTE 15B
# Revision    : CXP 903 0491-135-1
# Jira        : NETSUP-2748 
# Purpose     : resolves an issue where TDD cells are represented 
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Description : ensure TDD and FDD cells are not represented 
#               incorrectly 
# Date        : Mar 2015
# Who         : epatdal
####################################################################
####################################################################
# Version16   : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               GeranCellRelation MO
# Date        : feb 2018
# Who         : zyamkan
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

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
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
local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $MIMVERSION=$SIMNAME;$MIMVERSION=~s/-.*//g;$MIMVERSION=~s/LTE//;
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $element,$secequipnum;
local $nodenum,$freqgroup,$fregroup2,fregroup3;
local $actualgroupnodesize=0;# node size of each GeranFreqGroup
local $arfcnValueGeranDlCOUNT=0; # for GeranFrequency modified in reqId:3850
local $geranFrequencyIdCOUNT=1; # for GeranFrequency modified in reqId:3850
local $EXTERNALGERANCELLS=30000,$GERANFREQGROUPS=9;
local $NINTYFIVEPERCENTOFNETWORKNODES=ceil(($NETWORKCELLSIZE/$STATICCELLNUM)/100)*95; # 95% ofnetwork
local $groupsextgsmcells,$freqextgsmcells="",$externalcellid,$ttlnodegerancellrelations;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local @primarycells;
# Irathom data
local $IRATHOMDIR=$scriptpath;
$IRATHOMDIR=~s/bin.*/customdata\/irathom\//;
local ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype);
local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMGSMLTEFILENAME");
$IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";

# Ver12 : LTE 15B
local $IrathomRelationFile="$IRATHOMDIR/PrivateNewConfigIrathomLTE2GRAN.csv";

local $IRATHOMGSMTTLCELLS=&getENVfilevalue($ENV,"IRATHOMGSMTTLCELLS");
local $IRATHOMGSMENABLED=&getENVfilevalue($ENV,"IRATHOMGSMENABLED");
local $IRATHOMGSMREUSELEGACYCUSTOMDATA=&getENVfilevalue($ENV,"IRATHOMGSMREUSELEGACYCUSTOMDATA");
local $NINTYFIVEPERCENTOFNETWORKNODES=(($NETWORKCELLSIZE/$CELLNUM28K)/100)*95; # 95% ofnetwork
$NINTYFIVEPERCENTOFNETWORKNODES=floor($NINTYFIVEPERCENTOFNETWORKNODES);
local $currentTtlGSMcells=0;
local $IrathomDataRead=0;
local $IrathomDataNewlyCreated=0;

# Ver12 : LTE 15B
local $command1="createnewconfigLTE2GRANnetworkdata.pl";

local @IRATHOMGRANDATA=();
local $IrathomGSMdatapospointer=0;
local $startIrathomGSMdatapospointer=7;# first value on 20K GSM attributes file
local $IrathomGSMdatainmemory=0;
local @GeranFreqGroup;
local $creategeranfrequency;
local $TTLIRATHOMGRANDATArows=$IRATHOMGSMTTLCELLS-1;
local $TOTALIrathomGSMdatapospointer=$TTLIRATHOMGRANDATArows+$startIrathomGSMdatapospointer;
local $match=0;
# LTE14B
local $startfreqgroup;
local $staticstartfreqgroup;
local $endfreqgroup;
local $nodefreqgroupcreated=0;

# Check support for updated GSM configuration
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMsupportforupdatedGSMconfiguration="E1180";
####################
# Integrity Check
####################
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/){exit;}

# Check support for updated GSM configuration
$mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMsupportforupdatedGSMconfiguration);
if($mimcomparisonstatus eq "yes"){
  print "GSM configuration not supported for MIM $MIMVERSION in script ${0}\n";
  exit;
}# end if
################################
# MAIN
################################
print "... ${0} started running at $date\n";
################################
while ($NODECOUNT<=$NUMOFRBS){

$nodefreqgroupcreated=0;

# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);


$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

@GeranFreqGroup=&createGSMFreqGroup($NETWORKCELLSIZE,$STATICCELLNUM);
if (@GeranFreqGroup<2){
    print "FATAL ERROR : there is no GeranFreqGroup data generated\n";exit;
}# end if

##############################
# flexible CELLNUM allocation
##############################
@primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
$CELLNUM=@primarycells;

# check cell type
# CXP 903 0491-135-1
if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
    $TYPE="EUtranCellFDD";
}# end if
 else{
    $TYPE="EUtranCellTDD";
}# end else

#####################
# get GeranFreqGroup
#####################
$nodenum="";
foreach $element(@GeranFreqGroup){
                ($nodenum,$freqgroup,$freqgroup2,$freqgroup3,$actualgroupnodesize)=split(/\../,$element);
                if($nodenum==$nodecountfornodestringname){last;}
}# end foreach
if ($nodenum!=$nodecountfornodestringname)
{print PFH "FATAL ERROR : $nodecountfornodestringname NOT matched in GSM realtime created network\n";exit;}
######################################
# start create external geran cells
######################################
# check network threshhold
if ($nodecountfornodestringname<=$NINTYFIVEPERCENTOFNETWORKNODES){
   $ttlnodegerancellrelations=12; # per node 4 per cell * 3 groups
   $groupsextgsmcells=ceil($ttlnodegerancellrelations/3);
   $currentTtlGSMcells=$nodecountfornodestringname*$ttlnodegerancellrelations;
 }# end if
else
  # Workaround2 - need to drop ttlnodegerancellrelations from 45 to 30 because of MIM restrictions
  #               on number of MO children
  {$ttlnodegerancellrelations=30;
   $groupsextgsmcells=ceil($ttlnodegerancellrelations/3);
   $currentTtlGSMcells=$nodecountfornodestringname*$ttlnodegerancellrelations;
}# end else


# LTE14.2 check IRATHOMGSMTTLCELLS not exceeded
if($match==0){
  $IRATHOMGSMTTLCELLS=$IRATHOMGSMTTLCELLS+$ttlnodegerancellrelations;
  $match++;
}# end if

if($currentTtlGSMcells>$IRATHOMGSMTTLCELLS){
   $currentTtlGSMcells=$currentTtlGSMcells % $IRATHOMGSMTTLCELLS;
}# end if

# determine frequency group
$tempcount=1,$tempvar="";
$loopcounter=1,@not_sorted=($freqgroup,$freqgroup2,$freqgroup3),@sorted;
$loopcounter2;
@sorted=sort {$a <=> $b} @not_sorted;# sorted frequencygroups

# determine starting externalcellid
$externalcellid=(($nodecountfornodestringname*$ttlnodegerancellrelations)-($ttlnodegerancellrelations-1))%$EXTERNALGERANCELLS;
$externalcellid2=$externalcellid;$externalcellid3=$externalcellid;

 $tempcount=1;
 $arfcnValueGeranDlCOUNT=0; # for GeranFrequency modified in reqId:3850
 $xgeranFrequencyIdCOUNT=1; # for GeranFrequency modified in reqId:3850

 while ($tempcount<=3){# 3 GeranFreqGroups
   $loopcounter=0;
   if($tempcount==1)
   {$tempvar=$sorted[0];$geranFrequencyIdCOUNT=1;$geranfreqid=1;$loopcounter=1;$loopcounter2=1;$loopcounter3=1;}

   if($tempcount==2)
   {$tempvar=$sorted[1];$geranFrequencyIdCOUNT=$ttlnodegerancellrelations+1;$geranfreqid=17;$loopcounter=2;$loopcounter2=0;$loopcounter3=0;}

   if($tempcount==3)
   {$tempvar=$sorted[2];$geranFrequencyIdCOUNT=$ttlnodegerancellrelations+1;$geranfreqid=17;$loopcounter=2;$loopcounter2=0;$loopcounter3=0;}

################################
# START : check for Irathom
################################
if(($currentTtlGSMcells<=$IRATHOMGSMTTLCELLS)&&(uc($IRATHOMGSMENABLED eq "YES"))&&($IrathomGSMdatainmemory==0)){

     if((uc($IRATHOMGSMREUSELEGACYCUSTOMDATA eq "NO"))&&($IrathomDataNewlyCreated==0)){
       print "Executing $command1 to create Irathom enabled GSM network data\n";
       $retval=system("$command1 >/dev/null 2>&1");
          if($retval!=0){
               print "FATAL ERROR : unable to create $IrathomRelationFile\n";
               $retval=0;
               exit;
          }# end inner if
       $IrathomDataNewlyCreated=1; 
     }# end if

     if((uc($IRATHOMGSMREUSELEGACYCUSTOMDATA eq "YES"))){
        print "Re-reading GSM data in already created $IrathomRelationFile\n";
     }# end if

     open FH10, "$IrathomRelationFile" or die $!;
               @IRATHOMGRANDATA=<FH10>;
               $IrathomGSMdatainmemory=1;
     close(FH10);
  
    # find the array position of the first sim node GSM data detail
    foreach $arrayelement(@IRATHOMGRANDATA){
            if(!($arrayelement=~m/;/)){$IrathomGSMdatapospointer++;next;}
            ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype)=split(/;/,$arrayelement);
             if($ltenodename=~m/$LTENAME/){
                last;
             }# end inner if
            $IrathomGSMdatapospointer++;
    }# end foreach
}# end if


# LTE14.2 ensure reuse GSM 20K attributes file
if($IrathomGSMdatapospointer<$TOTALIrathomGSMdatapospointer){
    $IrathomGSMdatapospointer=$IrathomGSMdatapospointer;
}# end if
else{$IrathomGSMdatapospointer=$currentTtlGSMcells-$ttlnodegerancellrelations;}

if($IrathomGSMdatapospointer<$startIrathomGSMdatapospointer){
   $IrathomGSMdatapospointer=$startIrathomGSMdatapospointer;
}# end if
$copyIrathomGSMdatapospointer=$IrathomGSMdatapospointer; 
################################
# END : check for Irathom
################################
######################################
# start create GeranFreqGroupRelation
###############################a#######
$CELLCOUNT=1;
while ($CELLCOUNT<=$CELLNUM){# start cellcount
 if ($tempcount<=3){ # create 3 GeranFreqGroups
      @MOCmds=();
      if($tempcount==1){$tempvar=$freqgroup;}
      if($tempcount==2){$tempvar=$freqgroup2;}
      if($tempcount==3){$tempvar=$freqgroup3;}

      print "Creating frequencygrouprelation for $tempvar $TYPE=$LTENAME-$CELLCOUNT\n";

      @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
      identity "$tempvar"
      moType GeranFreqGroupRelation
      exception none
      nrOfAttributes 15
      "GeranFreqGroupRelationId" String ""
      "allowedPlmnList" Array Struct 0
      "cellReselectionPriority" Integer 1
      "geranFreqGroupRef" Ref "null"
      "includeInSystemInformation" Boolean true
      "nccPermitted" String "11111111"
      "pMaxGeran" Integer 1000
      "qRxLevMin" Integer -115
      "threshXHigh" Integer 4
      "threshXLow" Integer 0
      "userLabel" String ""
      )
    ^;# end @MO
     #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    
 }# end if
 $CELLCOUNT++;
}# end while cellcount
######################################
# end create GeranFreqGroupRelation
######################################
######################################
# start geran cells relation
######################################
$CELLCOUNT=1;$loopcounter4=1;$loopflag=1;
while ($CELLCOUNT<=$CELLNUM){# cellcount
   # reset 20K attributes file pos pointer
   $IrathomGSMdatapospointer=$copyIrathomGSMdatapospointer;
   $nodefreqgroupcreated=0;
   if($tempcount==1){ # start if loopcounter3
    while($loopcounter3<=$tempvar){ # number of groups 
      $loopcounter4=1;$externalcellid2=$externalcellid3;
      #if($loopflag>1){$IrathomGSMdatapospointer=$IrathomGSMdatapospointer-$ttlnodegerancellrelations;}
       # reset 20K attributes file pos pointer
      $IrathomGSMdatapospointer=$copyIrathomGSMdatapospointer;
     while($loopcounter4<=$ttlnodegerancellrelations){ # start loopcounter4
         @MOCmds=();
          # irathom enabled GSM data
       if(($currentTtlGSMcells<=$IRATHOMGSMTTLCELLS)&&(uc($IRATHOMGSMENABLED eq "YES"))&&($IrathomGSMdatainmemory==1)){

       # LTE14.2 ensure we re-use the 20K GSM attributes file data
       if($IrathomGSMdatapospointer>$TOTALIrathomGSMdatapospointer){$IrathomGSMdatapospointer=$startIrathomGSMdatapospointer;}       

       ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$IrathomGSMdatapospointer]);
     
        # LTE14B.1 workaround1 for IRATHOM
        $freqgroup=~s/\n//;
        $tempvar=$freqgroup;

       ###############################
       # start create GERANFREQGROUPS
       ###############################
       
        if($ttlnodegerancellrelations==12){# start if ttlnodegerancellrelations==12


       if($nodefreqgroupcreated==0){# start if nodefreqgroupcreated=0

          $nodefreqgroupcreated=1;

          if($tempvar<=3){$startfreqgroup=11;$endfreqgroup=12;}
          if($tempvar>3 && $tempvar<=6 ){$startfreqgroup=11;$endfreqgroup=12;}
          # CXP 903 0491-112-1
          if($tempvar>6 && $tempvar<=10 ){$startfreqgroup=11;$endfreqgroup=12;}

          $staticstartfreqgroup=$startfreqgroup;

          while ($startfreqgroup<=$endfreqgroup){# start while

                  @MOCmds=qq^ CREATE
                  (
                   parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
                   identity "$startfreqgroup"
                   moType GeranFreqGroupRelation
                   exception none
                   nrOfAttributes 15
                   "GeranFreqGroupRelationId" String ""
                   "allowedPlmnList" Array Struct 0
                   "cellReselectionPriority" Integer 1
                   "geranFreqGroupRef" Ref "null"
                   "includeInSystemInformation" Boolean true
                   "nccPermitted" String "11111111"
                   "pMaxGeran" Integer 1000
                   "qRxLevMin" Integer -115
                   "threshXHigh" Integer 4
                   "threshXLow" Integer 0
                   "userLabel" String ""
                   )
                  ^;# end @MO

               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

               @MOCmds=qq^ SET
               (
               mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,GeranFreqGroupRelation=$startfreqgroup"
               exception none
                nrOfAttributes 1
               "geranFreqGroupRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$startfreqgroup"
               )
              ^;# end @MO
               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

            $startfreqgroup++;

           }# end while 

          } # end if nodefreqgroupcreated=0

          if(($nodefreqgroupcreated==1) && ($tempvar<$staticstartfreqgroup||$tempvar>$endfreqgroup)){

                @MOCmds=qq^ CREATE
                  (
                   parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
                   identity "$tempvar"
                   moType GeranFreqGroupRelation
                   exception none
                   nrOfAttributes 15
                   "GeranFreqGroupRelationId" String ""
                   "allowedPlmnList" Array Struct 0
                   "cellReselectionPriority" Integer 1
                   "geranFreqGroupRef" Ref "null"
                   "includeInSystemInformation" Boolean true
                   "nccPermitted" String "11111111"
                   "pMaxGeran" Integer 1000
                   "qRxLevMin" Integer -115
                   "threshXHigh" Integer 4
                   "threshXLow" Integer 0
                   "userLabel" String ""
                   )
                   ^;# end @MO

               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

          }# end if
         }# end if ttlnodegerancellrelations==12
 
         if($ttlnodegerancellrelations>12){# start if ttlnodegerancellrelation>12
		# CXP 903 0491-100-1 : Populate GeranFreqGroupRelation::geranFreqGroupRef
                  @MOCmds=qq^ CREATE
                  (
                   parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
                   identity "$tempvar"
                   moType GeranFreqGroupRelation
                   exception none
                   nrOfAttributes 15
                   "GeranFreqGroupRelationId" String ""
                   "allowedPlmnList" Array Struct 0
                   "cellReselectionPriority" Integer 1
                   "geranFreqGroupRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$tempvar"
                   "includeInSystemInformation" Boolean true
                   "nccPermitted" String "11111111"
                   "pMaxGeran" Integer 1000
                   "qRxLevMin" Integer -115
                   "threshXHigh" Integer 4
                   "threshXLow" Integer 0
                   "userLabel" String ""
                   )
                   ^;# end @MO

               $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

         }# end if ttlnodegerancellrelations>12       



      ###############################
      # end create GERANFREQGROUPS
      ###############################

         @MOCmds=qq^ CREATE
         (
         parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,GeranFreqGroupRelation=$freqgroup"
         identity "$loopcounter4"
         moType GeranCellRelation
         exception none
         nrOfAttributes 4
         "GeranCellRelationId" String "$loopcounter4"
         "createdBy" Integer 0
          "externalGeranCellRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$freqgroup,GeranFrequency=$bccno,ExternalGeranCell=$ci"
        "timeOfCreation" String "2017-11-29T09:32:56"
     )
    ^;# end @MO
   $IrathomGSMdatapospointer++;
 }# end if
else {
       # non irathom enabled GSM data



         @MOCmds=qq^ CREATE
         (
         parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,GeranFreqGroupRelation=$tempvar"
         identity "$loopcounter4"
         moType GeranCellRelation
         exception none
         nrOfAttributes 4
         "GeranCellRelationId" String "$loopcounter4"
         "createdBy" Integer 0
          "externalGeranCellRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$tempvar,GeranFrequency=1,ExternalGeranCell=$externalcellid2"
        "timeOfCreation" String "2017-11-29T09:32:56"
     )
    ^;# end @MO
}# end else

     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
     $loopcounter4++;$externalcellid2++;
     }# end while loopcounter4
   $loopcounter3++;$loopflag++;
    }# end while loopcounter3
   }# end if tempcount
   ######################################
   # start relate GeranFrequencyGroup
   ######################################
   @MOCmds=();
   @MOCmds=qq^ SET
      (
       mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,GeranFreqGroupRelation=$freqgroup"
       exception none
       nrOfAttributes 1
       "geranFreqGroupRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$freqgroup"
      )
    ^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   #####################################
   # end relate GeranFrequencyGroup
   #####################################
 $CELLCOUNT++;$loopcounter3=1;
 }# end while CELLCOUNT
  $tempcount++;
}# while GeranFreqGroups
######################################
# end geran cells relation
######################################

push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

################################
# build MML script
################################
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
