#!/usr/bin/perl
### VERSION HISTORY
########################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-152-1
# Jira        : OSS-77902
# Purpose     : Creates DG2 Utran Freq Relations
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by the
#               WRAN network team)
# Date        : May 2015
# Who         : xsrilek
########################################################################
####################################################################
# Version2    : LTE 17A
# Revision    : CXP 903 0491-249-1
# Purpose     : Increase the number of UtranCellRelations
# Jira        : NSS-2160
# Description : To increase UtranCellRelations such that the average
#               is 6 per cell.
# Date        : Aug 2016
# Who         : xkatmri
###################################################################
####################################################################
# Version3    : ENM 17.14
# Revision    : CXP 903 0491-307-1
# Jira        : NSS-13661
# Purpose     : Attribute out of range exception for DG2 Nodes
# Description : Setting the mandatory attributes for BCG export 
#               & import to pass for DG2 Nodes. Setting attributes
#               prsMutingPattern, additionalPlmnList, freqBand          
# Date        : Aug 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : ENM 19.15
# Revision    : CXP 903 0491-367-1
# Jira        : NSS-32034
# Purpose     : 80K LTE 35K Design for Utran relations
# Description : Design change to meet specific counts mentioned in 
#               above JIRA.       
# Date        : Sep 2017
# Who         : xmitsin
####################################################################
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
local $whilecounter,$retval;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds=(),@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
# for node cells/adjacent cells

local $nodecountinteger,@primarycells=();
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $FREQCOUNT,$TOTALFREQCOUNT=5;##nrm#6.2,
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
local $TOTALUTRANPEREUTRANCELL=5; #####nrm6.2Change,#6
# LTE14B.1
local $countit=0;
local $tempcellnum1;
local $tempcellstringname2;
####################
# utran struct vars
####################
local $TtlGeranFreqGroupRelation=3;
local $TtlUtranFreqRelation=5;#####nrm6.2Change,#6
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
  # print "IRATHOM : enabled for $IRATHOMTTLUTRANCELLS external Utran cells\n";

   # start not required to be executed as executed in script 4275createDG2UtranFrequency.pl
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
   print "IRATHOM : Output file for WRAN $IrathomOutputFile\n";

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
                $tempcounter2++; ####nrm6.2
            }# end innner if

   }# end foreach
}# end if

#------------------------------------------------
# end1 get IRATHOM Utran cells data
#------------------------------------------------
################################
# Make MO & MML Scripts
################################

while ($NODECOUNT<=$DG2NUMOFRBS){# start outer while

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
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);
  $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);
  $freqid=&getERBSTotalCount($nodecountinteger,$NODESIM,$DG2NUMOFRBS);
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
      $TYPE="Lrat:EUtranCellFDD";
  }# end if
  else{
     $TYPE="Lrat:EUtranCellTDD";
  }# end else

  #---------------------------------------
  # start Irathom enabled Utran cells
  #---------------------------------------

  if($irathomsimmatch==1){
  
  

   $tempcounter3=0;$tempcellnum=1;
  

   #### Changes as per JIRA:https://jira-oss.seli.wh.rnd.internal.ericsson.com/browse/NSS-32034 ###

    while($tempcellnum<=$TOTALUTRANPEREUTRANCELL){ # while TOTALUTRANCELLS
  

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
#print "   # workaround for when file ROWID exhausted mid node cell\n";
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
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$ltecellname"
          identity $utranfreqrel
          moType Lrat:UtranFreqRelation
          exception none
          nrOfAttributes 5
          cellReselectionPriority Int32 3
          userLabel String "IrathomEnabled"
          "utranFrequencyRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$utranfreq"
          utranFreqToQciProfileRelation Array Struct 0
          allowedPlmnList Array Struct 1
          nrOfElements 3
          mcc Int32 353
          mnc Int32 57
          mncLength Int32 2
     );
    ^;# end @MO


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
       mo ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$ltecellname,Lrat:UtranFreqRelation=$utranfreqrel
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
             mcc Int32 $activeMCC
             mnc Int32 $activeMNC
             mncLength Int32 $activeMNClength
    ^;# end @MOCmds
    #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $activecounter++;
    $activeMNC++;
    }# end while allowedPlmnList

   $activecounter2++;
   @MOCmds=();
	   # CXP 903 0491-111-1 : Comment out, eventually remove.
	   #@MOCmds=qq^
	   #   )
	   # ^;# end @MO
	   #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   }# end while TtlUtranFreqRelation

   ####################################################
   # SUPPRESSED - LTE14B.1 end build UtranFreqRelation struct array
   ####################################################

    $tempcellnum2++;
 }############## ENd while 6 times
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
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT"
          identity $FREQCOUNT
          moType Lrat:UtranFreqRelation

          nrOfAttributes 4
          cellReselectionPriority Int32 3
          "utranFrequencyRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$FREQCOUNT"
          utranFreqToQciProfileRelation Array Struct 0
          allowedPlmnList Array Struct 1
          nrOfElements 3
          mcc Int32 353
          mnc Int32 57
          mncLength Int32 2
     );
    ^;# end @MO


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
       mo ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,$TYPE=$LTENAME-$CELLCOUNT,Lrat:UtranFreqRelation=$FREQCOUNT
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
             mcc Int32 $activeMCC
             mnc Int32 $activeMNC
             mncLength Int32 $activeMNClength
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
