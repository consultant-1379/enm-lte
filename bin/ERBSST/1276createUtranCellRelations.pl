#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version2    : LTE 13B
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
########################################################################
# Version3    : LTE 13B
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
# Version4    : LTE 13B
# Revision    : 12
# Purpose     : Sprint 2.2 External Utran Network Inconsistencies
# Description : create total 20k external utran cells and ~500K relations
#               throughout the entire LTE network and ensure Irathom
#               enabled cells are deducted from the total external cell count
#               if they are included in the network
#               eg. Required External Utran Cells =10K ie. (Total External Utran Cells=20K-Irathom External cells=10K)
# Date        : Feb 2013
# Who         : epatdal
########################################################################
####################################################################
# Version5    : LTE 14A
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
# Version6    : LTE 14B.1
# Revision    : CXP 903 0491-70-1
# Purpose     : updated support for LTE2WRAN for IRATHOM
#               to include new 10K UtranData14B_For_LTE.csv file
#               and extra values RNCID and UARFCNUL
# Description : implement LTE2WRAN for IRATHOM
# Jira        : NETSUP-1672
# SNID        : LMI-14:001028
# Date        : Juy 2014
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 14B.1
# Revision    : CXP 903 0491-92-1
# Purpose     : make externalUtranCellFDDRef applicable to TDD & FDD
# Date        : September 2014
# Who         : edalrey
####################################################################
####################################################################
# Version8    : LTE 15B
# Revision    : CXP 903 0491-111-1
# Purpose     : Manage handover from Irathom data to simulated data
#               mid-node.
# Description : Introduce a new state for $irathomsimmatch (=2) that
#               means the node has exhausted all Irathom data, but
#               still has remaining relations to define.
# Date        : 10 Dec 2014
# Who         : edalrey
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
# Purpose     : resolves an issue where TDD cells are represented
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Jira        : NETSUP-2748
# Description : ensure TDD and FDD cells are not represented
#               incorrectly
# Date        : Mar 2015
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 17A
# Revision    : CXP 903 0491-249-1
# Purpose     : Increase the number of UtranCellRelations
# Jira        : NSS-2160
# Description : To increase UtranCellRelations such that the average
#               is 6 per cell.
# Date        : Aug 2016
# Who         : xkatmri
###################################################################
####################################################################
# Version12   : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version13   : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               UtranCellRelation MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
# Version18   : LTE 18.12
# Revision    : CXP 903 0491-342-1
# Jira        : NSS-19508
# Purpose     : Increase the relation count as per NRM 4.1
# Description : EXTCELLSPERFREQ for 95%,5% have been increase from 6 to 11
# Date        : Jun 2018
# Who         : xravlat
####################################################################
########################################################################################
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
local @EXTUTRANCELLID=&getNetworkExtUtranCellID($NETWORKCELLSIZE,$STATICCELLNUM);
local $temputranfrequency,$utranfrequency=6;
local $TOTALFREQCOUNT=$utranfrequency;
local $nodenum,$utranfrequency,$cellnum,$extutrancellid;
local $snodenum,$sutranfrequency,$scellnum;
local $element,$UtranCellRelationNum;
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
local $NODENUMBERNETWORKNINETYFIVE;
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
# LTE14B.1
local $countit=0;
local $tempcellnum1;
local $tempcellstringname2;
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;

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

####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/UtranCellRelation.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
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
   local $IRATHOMTTLUTRANCELLS=&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS");
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

  # CXP 903 0491-111-1
  if($irathomsimmatch==2){$irathomsimmatch=0;}

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  print"Creating UtranFreqRelations for $LTENAME\n";

  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

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
# CXP 903 0491-92-1 - externalUtranCellFDDRef applies to both FDD and TDD cells as per CPI documentation & attribute description
    $TYPE4="externalUtranCellFDDRef";

#---------------------------------------
# start Irathom enabled Utran cells
#---------------------------------------

if($irathomsimmatch==1){

##########################################
# start create UtranCellRelations
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
    # CXP 903 0491-111-1 : Updated (0 -> 0) with ( 1 -> 2 ).
    if(($rowid =~m/ /)&&($irathomsimmatch==1)){$irathomsimmatch=2;}

    if(!($rowid=~m/ /)){
        $Trowid=$rowid;$Tltecellname=$ltecellname;$Tutranfreqrel=$utranfreqrel;$Tutranfreq=$utranfreq;$TextucFDDid=$extucFDDid;$Tmucid=$mucid;
        $Tuserlabel=$userlabel;$Tlac=$lac;$Tpcid=$pcid;$Tcid=$cid;$Trac=$rac;$Tarfcnvdl=$arfcnvdl;$Tearfcndl=$earfcndl;$Trncid=$rncid;$Tuarfcul=$uarfcul;
    }# end else

   }# end outer if
   #------------------------------------------------
   # end3 get IRATHOM Utran Freq and FreqRelation
   #------------------------------------------------

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

   if($irathomsimmatch==1){

   @MOCmds=qq^ CREATE
      (
    parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$ltecellname,UtranFreqRelation=$utranfreq"
    identity "$cid"
    moType UtranCellRelation
    exception none
    nrOfAttributes 2
    "timeOfCreation" String "2017-11-29T09:32:56"
    UtranCellRelationId String "$cid"
      )
    ^;# end @MO
print $fh "@MOCmds";
    print "$TYPE $ltecellname UtranCellRelation $utranfreq cid $cid\n";

    }# end if irathomsimmatch

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

    $tempcellnum2++;

   }

   if($tempcellnum >= 64){last;} #UtranFreqRelation can have a maximum of 64 UtranCellRelation

   $tempcellnum++;

  }# end while TOTALUTRANCELLS
##########################################
# end create UtranCellRelations
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
###############################
# start create UtranCellRelation
# for < 95% FDD cell network
################################
if(($nodecountfornodestringname<=$NODENUMBERNETWORKNINETYFIVE)||( $TYPE2 eq "ExternalUtranCellTDD")){ # start network < 95 %
$UtranCellRelationNum=1;
$STATICCELLNUM=$EXTCELLSPERFREQNINETYFIVE;

while($UtranCellRelationNum<=$CELLNUM){# while utrancellrelation
$tempcellnum=1;$temputranfrequency=1;$tempcounter3=0;

while($temputranfrequency<=$utranfrequency){ # while utranfrequency
 $tempcellnum=1;

 while($tempcellnum<=$STATICCELLNUM){ # while CELLNUM

   #-------------------------------
   # non Irathom enabled Utran cells
   #------------------------------

    @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$UtranCellRelationNum,UtranFreqRelation=$temputranfrequency"
      identity "$tempcellnum"
      moType UtranCellRelation
      exception none
      nrOfAttributes 2
      "timeOfCreation" String "2017-11-29T09:32:56"
      UtranCellRelationId String "$tempcellnum"
      )
    ^;# end @MO
print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

  $tempcellnum++;
 }# end while CELLNUM
 $temputranfrequency++;
}# end while utranfrequency
$UtranCellRelationNum++;
}# end UtranCellRelation
}# end network < 95 %
################################
# end create UtranCellRelation
# for < 95 % FDD cell network
################################
################################
# start create UtranCellRelation
# for > 95% FDD cell network
################################
if(($nodecountfornodestringname>$NODENUMBERNETWORKNINETYFIVE)&&!( $TYPE2 eq "ExternalUtranCellTDD")){ # start network > 95 %
$UtranCellRelationNum=1;
$MAXCELLNUM=$EXTCELLSPERFREQFIVE;

while($UtranCellRelationNum<=$CELLNUM){# while utrancellrelation
$tempcellnum=1;$temputranfrequency=1;$tempcounter3=0;
while($temputranfrequency<=$utranfrequency){ # while utranfrequency
 $tempcellnum=1;
 while($tempcellnum<=$MAXCELLNUM){ # while CELLNUM

   #-------------------------------
   # non Irathom enabled Utran cells
   #------------------------------

     @MOCmds=qq^ CREATE
      (
     parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$UtranCellRelationNum,UtranFreqRelation=$temputranfrequency"
     identity "$tempcellnum"
     moType UtranCellRelation
     exception none
     nrOfAttributes 2
     "timeOfCreation" String "2017-11-29T09:32:56"
     UtranCellRelationId String "$tempcellnum"
      )
    ^;# end @MO
print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

  $tempcellnum++;
 }# end while CELLNUM
 $temputranfrequency++;
}# end while utranfrequency
$UtranCellRelationNum++;
}# end UtranCellRelation
}# end network > 95 %
################################
# end create UtranCellRelation
# for > 95 % FDD cell network
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
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
