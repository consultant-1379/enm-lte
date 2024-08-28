#!/usr/bin/perl
### VERSION HISTORY
########################################################################
# Version1    : LTE 13B
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
########################################################################
########################################################################
# Version2    : LTE 13B
# Revision    : 5
# Purpose     : Sprint 0.7  Irathom LTE WCDMA
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by the
#               WRAN network team)
# Dependency  : ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv
# Date        : Jan 2013
# Who         : epatdal
########################################################################
########################################################################
# Version3    : LTE 13B
# Revision    : 12
# Purpose     : Sprint 2.2 External Utran Network Inconsistencies
# Description : create total 20k external utran cells and ~500K relations
#               throughout the entire LTE network and ensure Irathom
#               enabled cells are deducted from the total external cell count
#               if they are included in the network
#               eg. Required External Utran Cells =10K ie. (Total External
#		Utran Cells=20K-Irathom External cells=10K)
# Date        : Feb 2013
# Who         : epatdal
########################################################################
########################################################################
# Version4    : LTE 13B
# Revision    : CXP 903 0491-29
# Jira        : NETSUP-784
# Purpose     : Updating ExternalUtranCellFDD.masterUtranCellId
#               with assigned cellid as per stakeholder request
# Date        : Oct 2013
# Who         : ecasjim
########################################################################
########################################################################
# Version5    : LTE 14.1.7
# Revision    : CXP 903 0491-35
# Jira        : NETSUP-1124
# Purpose     : Snad ruleset fix for setting Utran proxy plmnid to
#               (MCC=46 MNC=7 and MNCLength=2)
#               for all non irathom utran proxies in the LTE network
# Date        : Nov 2013
# Who         : epatdal
########################################################################
####################################################################
# Version6    : LTE 14A
# Revision    : CXP 903 0491-42-19
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Jan 2014
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 14B.1
# Revision    : CXP 903 0491-70-1
# Jira        : NETSUP-1672
# Purpose     : updated support for LTE2WRAN for IRATHOM
#               to include new 10K UtranData14B_For_LTE.csv file
#               and extra values RNCID and UARFCNUL
# Description : implement LTE2WRAN for IRATHOM
# SNID        : LMI-14:001028
# Date        : Jul 2014
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 15B
# Revision    : CXP 903 0491-120-1
# Jira        : NETSUP-2513
# Purpose     : as per SNAD requirement ensure TDD cells have not
#               got the EUtranCellTDD.physicalCellIdentity > 128
# Description : ensure EUtranCellTDD.physicalCellIdentity <= 128
# Date        : January 2015
# Who         : epatdal
####################################################################
####################################################################
# Version9    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version10   : LTE 15B
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
# Version11   : LTE 17A
# Revision    : CXP 903 0491-244-1
# Jira        : NSS-5333
# Purpose     : Resolve error in sims at the border of irathom data
#               to simulated data in build.
# Description : In the middle of the node for a bunch of cells, if
#               irathom data completes, then the script is taking
#               empty values. To resolve this made changes to come
#               out of the loop if irathom data completes.
# Date        : July 2016
# Who         : xsrilek
####################################################################
####################################################################
# Version12   : LTE 17A
# Revision    : CXP 903 0491-249-1
# Purpose     : Increase the number of UtranCellRelations
# Jira        : NSS-2160
# Description : To increase UtranCellRelations such that the average
#               is 6 per cell.
# Date        : Aug 2016
# Who         : xkatmri
###################################################################
####################################################################
# Version13   : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               ExternalUtranCellFDD MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################
# Env
####################
use POSIX;
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS13;
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
local $MIMVERSION=$SIMNAME;$MIMVERSION=~s/-.*//g;$MIMVERSION=~s/LTE//;
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $MAXCELLNUM;
local $NETSIMMOSCRIPT=$MOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
$NETSIMMOSCRIPT=~s/\.\///;local $whilecounter;
local $TYPE,$TYPEID,$TYPE2,$TYPE3;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $temputranfrequency,$utranfrequency=6;
local $TOTALFREQCOUNT=$utranfrequency;
local $nodenum,$utranfrequency,$cellnum,$extutrancellid;
local $snodenum,$sutranfrequency,$scellnum;
local $element,$UtranCellRelationNum;
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
local $NODENUMBERNETWORKNINETYFIVE; # nodes in 95% of network
local $NODENUMBERNETWORKFIVE;# nodes in 5% of network
local $TOTALNODESINNETWORK;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $IRATHOMENABLED=&getENVfilevalue($ENV,"IRATHOMENABLED");
local $element;
local @IRATHOMLTE2WRANFILENAME=();
local @IRATHOMLTE2WRANFILENAME2=();
local $tempcounter2=0;
local ($mcc,$mnc,$mncLength);
local $plmnIdentity;
local ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl,$rncid,$uarfcnul);
local $temputranfreq=0;
local $templtename1;$templtename2;
local $irathomsimmatch=0,$arrayposition=0,$match;
local $element2,$element3,$tempcounter3,$tcell;
local @arraypositionlist=();
local $TOTALUTRANCELLS;
local $TOTALUTRANPEREUTRANCELL=6;
local @EXTUTRANCELLID=();
local $IRATHOMTTLUTRANCELLS=0;
local $elementcounterforEXTUTRANCELLID=0;
local $tempelementcounterforEXTUTRANCELLID;
# settings for mcc,mnc and mnclength for non irathom utran proxies
local $nonirathommcc=46;
local $nonirathommnc=6;
local $nonirathommncLength=2;
# LTE14B.1
local $countit=0;
local $tempcellnum1;
local $tempcellstringname2;

# CXP 903 0491-120-1
local $modremainder;
local $maxTDDpcid=128;

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/){exit;}
#-------------------------------
# Start get EXTUTRANCELLID
#-------------------------------
# determine breakdown of nodes in the network
$TOTALNODESINNETWORK=int($NETWORKCELLSIZE/$STATICCELLNUM);

# ensure IRATHOM cells are removed from total network nodes
# as IRATHOM Utran external cells are static
if (uc($IRATHOMENABLED) eq "YES"){
    local $IRATHOMTTLNODES=int(&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS")/($STATICCELLNUM*$STATICCELLNUM));
    $IRATHOMTTLUTRANCELLS=&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS");
    $TOTALNODESINNETWORK=$TOTALNODESINNETWORK-$IRATHOMTTLNODES;
}# end if IRATHOMENABLED

$NODENUMBERNETWORKNINETYFIVE=int(($TOTALNODESINNETWORK/100)*95);# nodes in 95% of network
$NODENUMBERNETWORKFIVE=ceil(($TOTALNODESINNETWORK/100)*5);# nodes in 5% of network

# establish external utran cells per frequency network breakdown
local $EXTCELLSPERFREQNINETYFIVE=11;
local $EXTCELLSPERFREQFIVE=11;

@EXTUTRANCELLID=&getNetworkExtUtranCellID($IRATHOMENABLED,$IRATHOMTTLUTRANCELLS,$NODENUMBERNETWORKNINETYFIVE,$EXTCELLSPERFREQNINETYFIVE,$NODENUMBERNETWORKFIVE,$EXTCELLSPERFREQFIVE);

#------------------------------
# End get EXTUTRANCELLID
#------------------------------
###################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
################################
# MAIN
################################
print "... ${0} started running at $date\n";
#------------------------------------------------
# start1 get IRATHOM Utran cells data
#------------------------------------------------
if (uc($IRATHOMENABLED) eq "YES"){
   local $IRATHOMDIR=$scriptpath;
   local $inputfilesize;
   local $csvinputfileline;

   $IRATHOMDIR=~s/bin.*/customdata\/irathom\//;
   local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMWRAN2LTEFILENAME");
   $IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";
   local $IrathomOutputFile="$IRATHOMDIR/PublicIrathomLTE2WRAN.csv";
   local $IrathomRelationFile="$IRATHOMDIR/PrivateIrathomLTE2WRAN.csv";
   $IRATHOMTTLUTRANCELLS=&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS");
   print "IRATHOM : enabled for $IRATHOMTTLUTRANCELLS external Utran cells\n";

   # start not required to be executed as executed in script 1275createUtranFrequency.pl
   #print "IRATHOM : executing script createLTE2WRANutranrelations.pl\n";
   #$retval=system("cd $scriptpath;./createLTE2WRANutranrelations.pl");

   # verify script success
   #if($retval<0){
      #print "FATAL ERROR : in execution $scriptpath.createLTE2WRANutranrelations.pl\n";exit;
   #}# end if
   # end not required to be executed as executed in script 1275createUtranFrequency.pl


   # verify LTE relations file PrivateIrathomLTE2WRAN.csv is created
   if (!(-e "$IrathomRelationFile")){
      print "FATAL ERROR : $IrathomRelationFile does not exist\n";exit;
   }# end if

   print "IRATHOM : Input file $IrathomInputFile\n";
   print "IRATHOM : Output file for LTE $IrathomRelationFile\n";
   #print "IRATHOM : Output file for WRAN $IrathomOutputFile\n";

   # open LTE input relations file PrivateIrathomLTE2WRAN.csv
   # contains all external Utran cells data
   open FH10, "$IrathomRelationFile" or die $!;
               @IRATHOMLTE2WRANFILENAME=<FH10>;
   close(FH10);

   # verify LTE relations file PrivateIrathomLTE2WRAN.csv is populated
   $inputfilesize=@IRATHOMLTE2WRANFILENAME;
   if($inputfilesize<$IRATHOMTTLUTRANCELLS){
      print "FATAL ERROR : in file $IrathomRelationFile\n";
      print "FATAL ERROR : file row size $inputfilesize is less than the required total Utrancell size of $IRATHOMTTLUTRANCELLS\n";
   }# end if

   # format IRATHOMLTE2WRANFILENAME for ROWIDs only

   foreach $element2(@IRATHOMLTE2WRANFILENAME){
            # plmnIdentity
            if($element2=~/MCC=/){# WRAN to LTE input file plmnIdentity
                    $plmnIdentity=&getIRATHOMcsvfilerawvalue($element2);
            }# end if
            ($mcc,$mnc,$mncLength)=split(/;/,$plmnIdentity);

            # ROWID
            if($element2=~/ROWID/){# start inner if
                $IRATHOMLTE2WRANFILENAME2[$tempcounter2]=$element2;
            }# end innner if
            $tempcounter2++;
   }# end foreach
}# end if
#------------------------------------------------
# end1 get IRATHOM Utran cells data
#------------------------------------------------
################################
# Make MO & MML Scripts
################################

while ($NODECOUNT<=$NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  print"Creating External Utran Cells for $LTENAME\n";

  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

   #-------------------------------------------------------------
   # start get external utran cellid start position for sim node1
   #-------------------------------------------------------------
   if($NODECOUNT==1){
   # find ExternalUtranCellID from EXTUTRANCELLID
   # ordered as nodenum-utranfrequency-cellnum-extutrancellid
   $elementcounterforEXTUTRANCELLID=0;
    foreach $element(@EXTUTRANCELLID){
         ($snodenum,$sutranfrequency,$scellnum,$extutrancellid)=split(/-/,$element);
          if($snodenum==$nodecountfornodestringname){
              last;
          }# end if
          $elementcounterforEXTUTRANCELLID++;
    }# end foreach element

   $tempelementcounterforEXTUTRANCELLID=$elementcounterforEXTUTRANCELLID;

   }# end if NODECOUNT=1
   #-------------------------------------------------------------
   # end get external utran cellid start position for sim node1
   #-------------------------------------------------------------

  #------------------------------------------------
  # start2 get IRATHOM Utran cells data
  #------------------------------------------------
  $irathomsimmatch=0;$match=0;$arrayposition=0;
  if (uc($IRATHOMENABLED) eq "YES"){
     foreach $element(@IRATHOMLTE2WRANFILENAME2){# start inner foreach

             # ROWID
             if($element=~/ROWID/){# start inner if
                $csvinputfileline=&getIRATHOMcsvfilerawvalue($element);
                ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl,$rncid,$uarfcnul)=split(/;/,$csvinputfileline);
             }# end innner if
             #---------------------------------------------------
             # start verify LTE node name is in @IRATHOMLTE2WRANFILENAME
             #---------------------------------------------------
             $templtename1=$LTENAME;
             $templtename2=$ltecellname;$templtename2=~s/-.*//;

             if($templtename2=~m/$templtename1/){
               $irathomsimmatch=1;
               last;# break the loop we have a sim match for irathom
             }# end inner if
             #---------------------------------------------------
             # end verify LTE node name is in @IRATHOMLTE2W1GRANFILENAME
             #---------------------------------------------------
             #----------------------------------------------------
             # start check for non ROWID data from WRAN input file
             #----------------------------------------------------
             if(($rowid =~m/ /)||($rowid =~m/\#/)){next;}
               else {}# end else
             #--------------------------------------------------
             # end check for non ROWID data from WRAN input file
             #--------------------------------------------------
             $arrayposition++;
     }# end inner foreach
  }# end if

  #------------------------------------------------
  # end2 get IRATHOM Utran cells data
  #------------------------------------------------

if($nodecountfornodestringname>$NODENUMBERNETWORKNINETYFIVE){print PFH "INFO : nodenum $nodecountfornodestringname exceeds 95% of network\n";}
@primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
$CELLNUM=@primarycells;

# start determine Irathom node cells position in file
if($irathomsimmatch==1){
     $tcell=0;$tempcounter3=0;
     @arraypositionlist=();
     $TOTALUTRANCELLS=$CELLNUM*$TOTALUTRANPEREUTRANCELL;

     while($tcell<$TOTALUTRANCELLS){
       $arraypositionlist[$tempcounter3]=$arrayposition;
       $arrayposition++;
       $tcell++;$tempcounter3++;
     }# end CELLNUM while

}# end if
# end determine Irathom node cells position in file

##################
# check cell type
##################
# CXP 903 0491-135-1
if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
    $TYPE="EUtranCellFDD";
    $TYPE2="ExternalUtranCellFDD";
    $TYPE3="ExternalUtranCellFDDId";
}# end if
else{
    $TYPE="EUtranCellTDD";
    $TYPE2="ExternalUtranCellTDD";
    $TYPE3="ExternalUtranCellTDDId";
}# end else

#---------------------------------------
# start Irathom enabled Utran cells
#---------------------------------------

if($irathomsimmatch==1){

##########################################
# start create ExternalUtranCellFDD
# for Utran Irathom enabled cell network
# Note : Utran cell numbers as are supplied
##########################################
$tempcounter3=0;$tempcellnum=1;

while($tempcellnum<=$TOTALUTRANCELLS){ # while TOTALUTRANCELLS

   #------------------------------------------------
   # start3 get IRATHOM Utran Freq and FreqRelation
   #------------------------------------------------
   if($irathomsimmatch==1){

     $csvinputfileline=&getIRATHOMcsvfilerawvalue($IRATHOMLTE2WRANFILENAME2[$arraypositionlist[$tempcounter3]]);
     ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl,$rncid,$uarfcnul)=split(/;/,$csvinputfileline);

    $tempcounter3++;

    # check if WRANtoLTE inputfile is end of file
    # then revert back to simulated external
    # utran cell
    if(($rowid =~m/ /)&&($irathomsimmatch==1)){$irathomsimmatch=0;}

    if(!($rowid=~m/ /)){
        $Trowid=$rowid;$Tltecellname=$ltecellname;$Tutranfreqrel=$utranfreqrel;$Tutranfreq=$utranfreq;$TextucFDDid=$extucFDDid;$Tmucid=$mucid;
        $Tuserlabel=$userlabel;$Tlac=$lac;$Tpcid=$pcid;$Tcid=$cid;$Trac=$rac;$Tarfcnvdl=$arfcnvdl;$Tearfcndl=$earfcndl;$Trncid=$rncid;$Tuarfcul=$uarfcul;
    }# end else

   }# end outer if
   #------------------------------------------------
   # end3 get IRATHOM Utran Freq and FreqRelation
   #------------------------------------------------

   # find ExternalUtranCellID from EXTUTRANCELLID
   # ordered as nodenum-utranfrequency-cellnum-extutrancellid
   #foreach $element(@EXTUTRANCELLID){
    #     ($snodenum,$sutranfrequency,$scellnum,$extutrancellid)=split(/-/,$element);
    #      if(($snodenum==$nodecountfornodestringname)&&($sutranfrequency==$temputranfrequency)&&($scellnum==$tempcellnum)){
    #          last;
    #      }# end if
   #}# end foreach element

   @MOCmds=();
   #-------------------------------
   # Irathom enabled Utran cells
   #-------------------------------
    # workaround for when file ROWID exhausted mid node cells
local $tempcellnum2=1;
while ($tempcellnum2<=$CELLNUM) { #CXP 903 0491-249-1 : For Irathom data, the number of cell relations to be 6 times the number of cells
         $tempcellnum1=$Tltecellname;
         $tempcellstringname2=$Tltecellname;
         $tempcellnum1=~s/.*?-//;
         $tempcellstringname2=~s/\-$tempcellnum1//;

      $ltecellname="$tempcellstringname2-$tempcellnum2";
      $utranfreq=$Tutranfreq;
      $rncid=$Trncid;
      $rac=$Trac;
      $cid=$Tcid;
      $lac=$Tlac;
      $mucid=$Tmucid;
      $pcid=$Tpcid;

   # SJ NETSUP-2513 CXP 903 0491-120-1
   if (($pcid>127)&&($TYPE eq "EUtranCellTDD")){
        $modpcidremainder = $pcid % $maxTDDpcid;
        $pcid=$modpcidremainder;
   }# end if SJ NETSUP-2513 CXP 903 0491-120-1

   if($irathomsimmatch==1){

   @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$utranfreq"
       identity "$cid"
       moType $TYPE2
       exception none
       nrOfAttributes 8
       "timeOfCreation" String "2017-11-29T09:32:56"
       $TYPE3 String "$cid"
       lac Integer $lac
       "masterUtranCellId" String "$mucid"
       "physicalCellIdentity" Integer $pcid
       "plmnIdentity" Struct
        nrOfElements 3
        "mcc" Integer $mcc
        "mnc" Integer $mnc
        "mncLength" Integer $mncLength
       rac Integer $rac
       "userLabel" String "$userlabel"
        cellIdentity Struct
        nrOfElements 2
         rncId Integer $rncid
         cId Integer $cid
      )
    ^;# end @MO

     }# end if irathomsimmatch
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcellnum2++;
 }

   $tempcellnum++
}# end while TOTALUTRANCELLS
##########################################
# end create ExternalUtranCellFDD
# for Utran Irathom enabled cell network
# Note : Utran cell numbers as are supplied
##########################################

}# end outer irathomsimmatch

#--------------------------------------
# end Irathom enabled Utran cells
#--------------------------------------
#--------------------------------------
# start non Irathom enabled Utran cells
#--------------------------------------
#######################################################################################################
# LTE 13B Utran Network Configuration (note: includes Irathom and simulated utran cells)
#
# LTE Nodenum - Network% - ttl relations - avg.cell - freq. - freq per relation - comment
#    625      -                                                                   Irathom 10,00 cells
#    344      -    5     -   82560       -     4    -   6   -      10
#   6531      -   95     -  626976       -     4    -   6   -       4
#   7500      -  100     -  719536
#######################################################################################################
if($irathomsimmatch==0){

###################################
# start create ExternalUtranCellFDD
# for < 95% FDD cell network
###################################
if(($nodecountfornodestringname<=$NODENUMBERNETWORKNINETYFIVE)||($TYPE2 eq "ExternalUtranCellTDD")){ # start network < 95 %
    $tempcellnum=1;$temputranfrequency=1;
    $STATICCELLNUM=$EXTCELLSPERFREQNINETYFIVE;

@MOCmds=();

while($temputranfrequency<=$utranfrequency){ # while utranfrequency
 $tempcellnum=1;

 while($tempcellnum<=$STATICCELLNUM){ # while CELLNUM

   # find ExternalUtranCellID from EXTUTRANCELLID
   # ordered as nodenum-utranfrequency-cellnum-extutrancellid
   #$tempelementcounterforEXTUTRANCELLID=$elementcounterforEXTUTRANCELLID;
   # LTE14B.1
   $tempelementcounterforEXTUTRANCELLID=0;
   while ($tempelementcounterforEXTUTRANCELLID<=@EXTUTRANCELLID){
         ($snodenum,$sutranfrequency,$scellnum,$extutrancellid)=split(/-/,$EXTUTRANCELLID[$tempelementcounterforEXTUTRANCELLID]);
         if(($snodenum==$nodecountfornodestringname)&&($sutranfrequency==$temputranfrequency)&&($scellnum==$tempcellnum)){
              last;
          }# end if
         $tempelementcounterforEXTUTRANCELLID++;
   }# end while
  if ((($tempelementcounterforEXTUTRANCELLID-1)==@EXTUTRANCELLID) &&($extutrancellid eq "")){ last;}
   #-------------------------------
   # non Irathom enabled Utran cells
   #------------------------------
    @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$temputranfrequency"
        identity "$extutrancellid"
        moType $TYPE2
        exception none
        nrOfAttributes 3
        "timeOfCreation" String "2017-11-29T09:32:56"
        $TYPE3 String "$extutrancellid"
        "masterUtranCellId" String "$extutrancellid"
        "plmnIdentity" Struct
         nrOfElements 3
        "mcc" Integer $nonirathommcc
        "mnc" Integer $nonirathommnc
        "mncLength" Integer $nonirathommncLength
        cellIdentity Struct
        nrOfElements 2
         rncId Integer 1
         cId Integer $extutrancellid
      )
    ^;# end @MO

    #print "$TYPE2 UtranFrequency=$temputranfrequency identity $extutrancellid\n";

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

  $tempcellnum++;
 }# end while CELLNUM

 $temputranfrequency++;
}# end while utranfrequency
}# end network < 95 %
################################
# end create ExternalUtranCellFDD
# for < 95% FDD cell network
################################
###################################
# start create ExternalUtranCellFDD
# for > 95% FDD cell network
###################################
if(($nodecountfornodestringname>$NODENUMBERNETWORKNINETYFIVE)&&!( $TYPE2 eq "ExternalUtranCellTDD")){ # start network > 95 %
$tempcellnum=1;$temputranfrequency=1;$tempcounter3=0;
$MAXCELLNUM=$EXTCELLSPERFREQFIVE;

while($temputranfrequency<=$utranfrequency){ # while utranfrequency
 $tempcellnum=1;
 while($tempcellnum<=$MAXCELLNUM){ # while CELLNUM

   # find ExternalUtranCellID from EXTUTRANCELLID
   # ordered as nodenum-utranfrequency-cellnum-extutrancellid
   #$tempelementcounterforEXTUTRANCELLID=$elementcounterforEXTUTRANCELLID;
   while ($tempelementcounterforEXTUTRANCELLID<=@EXTUTRANCELLID){
         ($snodenum,$sutranfrequency,$scellnum,$extutrancellid)=split(/-/,$EXTUTRANCELLID[$tempelementcounterforEXTUTRANCELLID]);
         if(($snodenum==$nodecountfornodestringname)&&($sutranfrequency==$temputranfrequency)&&($scellnum==$tempcellnum)){
              last;
          }# end if
         $tempelementcounterforEXTUTRANCELLID++;
   }# end while

   #-------------------------------
   # non Irathom enabled Utran cells
   #------------------------------
      @MOCmds=qq^ CREATE
      (
       parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$temputranfrequency"
       identity "$extutrancellid"
       moType $TYPE2
       exception none
       nrOfAttributes 2
       "timeOfCreation" String "2017-11-29T09:32:56"
       $TYPE3 String "$extutrancellid"
       "masterUtranCellId" String "$extutrancellid"
        "plmnIdentity" Struct
        nrOfElements 3
        "mcc" Integer $nonirathommcc
        "mnc" Integer $nonirathommnc
        "mncLength" Integer $nonirathommncLength
        cellIdentity Struct
        nrOfElements 2
         rncId Integer 1
         cId Integer $extutrancellid
      )
    ^;# end @MO

   #print "$TYPE2 UtranFrequency=$temputranfrequency identity $extutrancellid\n";

   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

  $tempcellnum++;

 }# end while MAXCELLNUM

 $temputranfrequency++;
}# end while utranfrequency

}# end network > 95 %
################################
# end create ExternalUtranCellFDD
# for > 95% FDD cell network
################################

}# end outer irathomsimmatch
#--------------------------------------
# end  non Irathom enabled Utran cells
#--------------------------------------

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

