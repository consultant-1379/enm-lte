#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : Created for LTE O 10.0 TERE
# Purpose     :
# Description :
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Version2    : Modified for FT
# Purpose     : Improvement of script design
# Description : Script will not run unless it is TYPE of FT
# Date        : 09 JUL 2010
# Who         : Fatih ONUR
####################################################################
# Version3    : Modified for LTE O 11.1 TERE
# Purpose     : Update
# Description : FDD and TDD node division provided
# Date        : 04 NOV 2010
# Who         : Fatih ONUR
####################################################################
####################################################################
# Version4    : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version6    : LTE 13A
# Purpose     : FDD/TDD handover support
# Description : OSS now supports FDD and TDD in the same network and
#               relations between the two types
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version7    : LTE 13B
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
# Version8    : LTE 13B
# Revision    : 5
# Purpose     : Sprint 0.7  Irathom LTE WCDMA
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by the
#               WRAN network team)
# Dependency  : ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv
# Date        : Jan 2013
# Who         : epatdal
########################################################################
####################################################################
# Version9    : LTE 14A
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
# Version10   : LTE 14.2
# Revision    : CXP 903 0491-70-1
# Jira        : NETSUP-1672
# Purpose     : support for LTE2WRAN for IRATHOM
# Description : implement LTE2WRAN for IRATHOM
#               removed 1277setUtranCellReselectionPrio.pl
#               and included update for cellReselectionPriority Integer 3
# SNID        : LMI-14:001028
# Date        : May 2014
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 14B.1
# Jira        : NETSUP-1672
# Purpose     : updated support for LTE2WRAN for IRATHOM
#               to include new 10K UtranData14B_For_LTE.csv file
#               and extra values RNCID and UARFCNUL
# Description : implement LTE2WRAN for IRATHOM
# SNID        : LMI-14:001028
# Date        : Juy 2014
# Who         : epatdal
####################################################################
####################################################################
# Version12   : LTE 14B.1
# Revision    : CXP 903 0491-73-2
# Purpose     : added support for UtranFreqRelation.allowedPlmnList
# Description : 15 plmnids added to UtranFreqRelation.allowedPlmnList
#               removed functionailty from 2133structsetEUtranGeranUtranRelations.pl
#               added functionailty to 1274createUtranFreqRelations.pl
# Date        : Juy 2014
# Who         : epatdal
####################################################################
####################################################################
# Version13   : LTE 15B
# Revision    : CXP 903 0491-111-1
# Purpose     : Manage handover from Irathom data to simulated data
#		mid-node.
# Description : Introduce a new state for $irathomsimmatch (=2) that
#		means the node has exhausted all Irathom data, but
#		still has remaining relations to define.
# Date        : 10 Dec 2014
# Who         : edalrey
####################################################################
####################################################################
# Version14   : LTE 15B
# Revision    : CXP 903 0491-122-1
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
# Purpose     : resolves anissue where TDD cells are represented
#               incorrectly as FDD cells in EUtran master and
#               proxy cells
# Description : ensure TDD and FDD cells are not represented
#               incorrectly
# Date        : Mar 2015
# Who         : epatdal
####################################################################
####################################################################
# Version16    : LTE 17A
# Revision    : CXP 903 0491-249-1
# Purpose     : Increase the number of UtranCellRelations
# Jira        : NSS-2160
# Description : To increase UtranCellRelations such that the average
#               is 6 per cell.
# Date        : Aug 2016
# Who         : xkatmri
###################################################################
####################
# Env
####################
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
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $whilecounter,$retval;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds=(),@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),$gridrow,$gridcol;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $FREQCOUNT,$TOTALFREQCOUNT=6;
local $IRATHOMENABLED=&getENVfilevalue($ENV,"IRATHOMENABLED");
local $element;
local @IRATHOMLTE2WRANFILENAME=();
local @IRATHOMLTE2WRANFILENAME2=();
local $tempcounter2=0;
local ($mcc,$mnc,$mncLength);
local $plmnIdentity;
local ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl);
local ($Trowid,$Tltecellname,$Tutranfreqrel,$Tutranfreq,$TextucFDDid,$Tmucid,$Tuserlabel,$Tlac,$Tpcid,$Tcid,$Trac,$Tarfcnvdl,$Tearfcndl);
local $temputranfreq=0;
local $templtename1;$templtename2;
local $irathomsimmatch=0,$arrayposition=0,$match;
local $element2,$element3,$tempcounter3,$tcell;
local @arraypositionlist=();
local $TOTALUTRANCELLS;
local $TOTALUTRANPEREUTRANCELL=6;
# LTE14B.1
local $countit=0;
local $tempcellnum1;
local $tempcellstringname2;
####################
# utran struct vars
####################
local $TtlGeranFreqGroupRelation=3;
local $TtlUtranFreqRelation=6;
local $TtladditionalPlmnList=5;
local $TtlactivePlmnList=6;
local $TtlallowedPlmnList=15;
local $activeMCC=353;
local $activeMNC=57;
local $activeMNClength=2;
local $activecounter,$activecounter2;
local $activecellnum;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
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

while ($NODECOUNT<=$NUMOFRBS){# start outer while

  # CXP 903 0491-111-1
  if($irathomsimmatch==2){$irathomsimmatch=0;}

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  #------------------------------------------------
  # start2 get IRATHOM Utran cells data
  #------------------------------------------------
  $irathomsimmatch=0;$match=0;$arrayposition=0;
  if (uc($IRATHOMENABLED) eq "YES"){
     foreach $element(@IRATHOMLTE2WRANFILENAME2){# start inner foreach

             # ROWID
             if($element=~/ROWID/){# start inner if
                $csvinputfileline=&getIRATHOMcsvfilerawvalue($element);
                ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl)=split(/;/,$csvinputfileline);
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

  # get the node eutran frequency id
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);
  $freqid=&getERBSTotalCount($nodecountinteger,$NODESIM,$NUMOFRBS);
  $EUTRANCELLFREQRELATIONID=&getEUtranFreqID_NUM($freqid,"ID");

  # get node flexible primary cells
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};
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

  # check cell type
  # checking one cell on the node in this instance and then assuming all other cells are the same
  # this is a good assumption but would have been future proof to do per cell
  # CXP 903 0491-135-1
  if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      #print "$LTENAME UtranFreqRelation on FDD Node Cells...\n";
      $TYPE="EUtranCellFDD";
  }# end if
  else{
     #print "$LTENAME UtranFreqRelation on TDD Nodes Cells...\n";
     $TYPE="EUtranCellTDD";
  }# end else

  #---------------------------------------
  # start Irathom enabled Utran cells
  #---------------------------------------

  if($irathomsimmatch==1){

   $tempcounter3=0;$tempcellnum=1;

    while($tempcellnum<=$TOTALUTRANCELLS){ # while TOTALUTRANCELLS

   #------------------------------------------------
   # start3 get IRATHOM Utran Freq and FreqRelation
   #------------------------------------------------
   if($irathomsimmatch==1){

     $csvinputfileline=&getIRATHOMcsvfilerawvalue($IRATHOMLTE2WRANFILENAME2[$arraypositionlist[$tempcounter3]]);
     ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl)=split(/;/,$csvinputfileline);

    $tempcounter3++;

    # check if WRANtoLTE inputfile is end of file
    # then revert back to simulated external
    # utran cell
    # CXP 903 0491-111-1 : Updated (0 -> 0) with ( 1 -> 2 ).
    if(($rowid =~m/ /)&&($irathomsimmatch==1)){$irathomsimmatch=2;}

    if(!($rowid=~m/ /)){
        $Trowid=$rowid;$Tltecellname=$ltecellname;$Tutranfreqrel=$utranfreqrel;$Tutranfreq=$utranfreq;$TextucFDDid=$extucFDDid;$Tmucid=$mucid;
        $Tuserlabel=$userlabel;$Tlac=$lac;$Tpcid=$pcid;$Tcid=$cid;$Trac=$rac;$Tarfcnvdl=$arfcnvdl;$Tearfcndl=$earfcndl;
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

   if($irathomsimmatch==1){
    @MOCmds=qq^CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$ltecellname"
          identity $utranfreq
          moType UtranFreqRelation
          exception none
          nrOfAttributes 3
          cellReselectionPriority Integer 3
          userLabel String "IrathomEnabled"
          "utranFrequencyRef" Ref "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$utranfreq"
     );
    ^;# end @MO

    print "Create UtranFreqRelation - $TYPE=$ltecellname UtranFreqRelation=$utranfreq...utranFrequency=$utranfreq\n";

   }# end if inner irathomsimmatch

   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   ######################################################
   # SUPPRESSED - LTE14B.1 start build UtranFreqRelation struct array
   ######################################################
   $activecounter2=1;
   $activeMNC=57;

   while($activecounter2<=$TtlUtranFreqRelation){
    @MOCmds=();
    # build mo script
    @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,$TYPE=$ltecellname,UtranFreqRelation=$utranfreq
       exception none
       nrOfAttributes 3
       allowedPlmnList Array Struct $TtlallowedPlmnList
    ^;# end @MO
    #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=();$activecounter=1;

    $activeMNC=57;
    while($activecounter<=$TtlallowedPlmnList){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $activeMCC
             mnc Integer $activeMNC
             mncLength Integer $activeMNClength
    ^;# end @MOCmds
    #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $activecounter++;
    $activeMNC++;
    }# end while allowedPlmnList

   $activecounter2++;
   @MOCmds=();
   #@MOCmds=qq^
   #  )
   # ^;# end @MO
   #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   }# end while TtlUtranFreqRelation

   ####################################################
   # SUPPRESSED - LTE14B.1 end build UtranFreqRelation struct array
   ####################################################

$tempcellnum2++;
 }
    $tempcellnum++;

  }# end while TOTALUTRANCELLS

 }# end outer irathomsimmatch
 #--------------------------------------
 # end Irathom enabled Utran cells
 #--------------------------------------

 #--------------------------------------
 # start non Irathom enabled Utran cells
 #--------------------------------------

if($irathomsimmatch==0){

  $CELLCOUNT=1;$tempcounter3=0;
  while($CELLCOUNT<=@primarycells){ # CELLNUM

   $FREQCOUNT=1;

   while ($FREQCOUNT<=$TOTALFREQCOUNT){# while $TOTALFREQCOUNT

    @MOCmds=qq^CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
          identity $FREQCOUNT
          moType UtranFreqRelation

          nrOfAttributes 2
          cellReselectionPriority Integer 3
          "utranFrequencyRef" Ref "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$FREQCOUNT"
     );
    ^;# end @MO
     print "Create UtranFreqRelation - $TYPE=$LTENAME-$CELLCOUNT...UtranFreqRelation=$FREQCOUNT...utranFrequency=$FREQCOUNT\n";

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

    ######################################################
   # LTE14B.1 start build UtranFreqRelation struct array
   ######################################################
   $activecounter2=1;

   while($activecounter2<=$TtlUtranFreqRelation){
    @MOCmds=();
    # build mo script
    @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,UtranFreqRelation=$FREQCOUNT
       exception none
       nrOfAttributes 3
       allowedPlmnList Array Struct $TtlallowedPlmnList
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=();$activecounter=1;

    $activeMNC=57;
    while($activecounter<=$TtlallowedPlmnList){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $activeMCC
             mnc Integer $activeMNC
             mncLength Integer $activeMNClength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $activecounter++;
    $activeMNC++;
    }# end while allowedPlmnList

   $activecounter2++;
   @MOCmds=();
   @MOCmds=qq^
      )
    ^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   }# end while TtlUtranFreqRelation

   ####################################################
   # LTE14B.1 end build UtranFreqRelation struct array
   ####################################################

    $FREQCOUNT++;
   }# end while FREQCOUNT

   $CELLCOUNT++;
  }# end inner CELLNUM while

}# end outer irathomsimmatch
#--------------------------------------
# end  non Irathom enabled Utran cells
#--------------------------------------
  push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

  ##################################################
  # Start of update due to NETSim TR TRSPS00013074 #
  ##################################################
  $ERBSEARFCNCOUNT=$ERBSEARFCNCOUNT+1;
  ################################################
  # End of update due to NETSim TR TRSPS00013074 #
  ################################################
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
# remove mo script
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################

