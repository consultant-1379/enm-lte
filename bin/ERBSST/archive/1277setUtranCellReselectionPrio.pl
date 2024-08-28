#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : LTE 13B
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
# Ver2        : LTE 13B
# Purpose     : Sprint 0.7  Irathom LTE WCDMA
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by the
#               WRAN network team)
# Dependency  : ~/LTESimScripts/customdata/irathom/PrivateIrathomLTE2WRAN.csv
# Date        : Jan 2013
# Who         : epatdal
########################################################################
####################################################################
# Ver3        : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE 
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next 
#               script                             
# Date        : Nov 2013
# Who         : epatdal
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

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/){exit;}
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
local ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl);
local $temputranfreq=0;
local $templtename1;$templtename2;
local $irathomsimmatch=0,$arrayposition=0,$match;
local $element2,$element3,$tempcounter3,$tcell;
local @arraypositionlist=();
local $TOTALUTRANCELLS;
local $TOTALUTRANPEREUTRANCELL=4;
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
while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  print"Setting UtranFreqRelations cellReselectionPriority for $LTENAME\n";

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

  # determine nodes in ninetyfive percent of the network
  $TOTALNODESINNETWORK=int($NETWORKCELLSIZE/$STATICCELLNUM);
  $TOTALNODESINNETWORK=$TOTALNODESINNETWORK-160; # remove TDD network nodes of 160 from TDD calculation
  $NODENUMBERNETWORKNINETYFIVE=int(($TOTALNODESINNETWORK/100)*95);

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
if (&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) {
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

############################################
# TEP 6672
# Start SET
# UtranFreqRelation cellReselectionPriority
#
############################################

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
     ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl)=split(/;/,$csvinputfileline);

    $tempcounter3++;

    # check if WRANtoLTE inputfile is end of file
    # then revert back to simulated external
    # utran cell
    if($rowid =~m/ /){$irathomsimmatch=0;}

   }# end outer if
   #------------------------------------------------
   # end3 get IRATHOM Utran Freq and FreqRelation
   #------------------------------------------------
 
   #-------------------------------
   # Irathom enabled Utran cells
   #-------------------------------
   if($irathomsimmatch==1){

     @MOCmds=qq^ SET
      (
       mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$ltecellname,UtranFreqRelation=$utranfreq"
       exception none
       nrOfAttributes 1
       cellReselectionPriority Integer 3
      )
    ^;# end @MO

    }# end if irathomsimmatch

  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

  $tempcellnum++;

 }# end while TOTALUTRANCELLS
############################################
# TEP 6672 
# End SET
# UtranFreqRelation cellReselectionPriority 
#
############################################

}# end outer irathomsimmatch

#--------------------------------------
# end Irathom enabled Utran cells
#--------------------------------------

#--------------------------------------
# start non Irathom enabled Utran cells
#--------------------------------------

if($irathomsimmatch==0){

############################################
# TEP 6672 
# Start SET
# UtranFreqRelation cellReselectionPriority 
#
############################################

$UtranCellRelationNum=1;

while($UtranCellRelationNum<=$CELLNUM){# while utrancellrelation
$tempcellnum=1;$temputranfrequency=1;$tempcounter3=0;
  while($temputranfrequency<=$utranfrequency){

  #-------------------------------
  # non Irathom enabled Utran cells
  #------------------------------

      @MOCmds=qq^ SET
      (
       mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$UtranCellRelationNum,UtranFreqRelation=$temputranfrequency"
       exception none
       nrOfAttributes 1
       cellReselectionPriority Integer 3
      )
    ^;# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

    $temputranfrequency++;
 
    }# end inner while
  $UtranCellRelationNum++;
}# end outer while

############################################
# TEP 6672 
# End SET
# UtranFreqRelation cellReselectionPriority 
#
############################################

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
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

# output mml script execution 
print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink @NETSIMMOSCRIPTS;
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
