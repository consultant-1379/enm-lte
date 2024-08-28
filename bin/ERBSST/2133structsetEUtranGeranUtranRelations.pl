#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Verion1     : LTE 11.2.8 ST Simulations 
# Purpose     : TEP Request : 6038
# Description : Sets Struct Array for ENodeBFunction Cells and
#               EUtranFreqRelation,GeranFreqGroupRelation and
#               UtranFreqRelation
#               Struct Array set are as follows :
#               EUtranCell=additionalPlmnList,activePlmnList
#               EUtranFreqRelation=allowedPlmnList
#               GeranFreqGroupRelation=allowedPlmnList
#               UtranFreqRelation=allowedPlmnList
# Date        : July 2011
# Who         : epatdal
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
# Version3    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover Internal
# Description : enable flexible LTE EUtran cell LTE handover
# Date        : Mar 2012
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 12.2
# Purpose     : LTE 12.2 LTE Handover
# Description : support for EXTERNALENODEBFUNCTION major minor network breakdown
# Date        : April 2012
# Who         : epatdal
####################################################################
####################################################################
# Version5    : LTE 13A
# Purpose     : LTE 13A Frequencies
# Description : Support for new relations and frequency setup
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
# Version7    : LTE 13A
# Purpose     : Speed up sim creation
# Description : Script altered to use single MML script, single pipe
# Date        : Sep 2012
# Who         : lmieody
####################################################################
########################################################################
# Version8    : LTE 13B
# Revision    : 5
# Purpose     : Sprint 0.7  Irathom LTE WCDMA
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by the
#               WRAN network team)
# Dependency  : ~/LTESimScripts/customdata/irathom/PrivateIrathomLTE2WRAN.csv
# Date        : Jan 2013
# Who         : epatdal
########################################################################
####################################################################
# Version9    : LTE 14A
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
# Version10   : LTE 14B.1
# Purpose     : added support for UtranFreqRelation.allowedPlmnList
# Description : 15 plmnids added to UtranFreqRelation.allowedPlmnList
#               removed functionailty from 2133structsetEUtranGeranUtranRelations.pl
#               added functionailty to 1274createUtranFreqRelations.pl
# Date        : Juy 2014
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 15B
# Revision    : CXP 903 0491-122-1 
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
####################################################################
# Version12   : LTE 15B
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
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_OSS12;
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
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT=$MOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
$NETSIMMOSCRIPT=~s/\.\///;local $whilecounter;
local $TYPE,$TYPEID;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local $NODESIM,$nodecountinteger,$freqid,$EUTRANCELLFREQID;
local @GeranFreqGroup,$tempcount=1,$tempvar="",$nodenum,$freqgroup,$freqgroup2,$freqgroup3,$actualgroupnodesize;
# ensure TDD and FDD cells are not related
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
local $TEMPNODESIM="",$TDDMATCH=0;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
#------------------------------------------------------------------------
# 60K optimisation
#------------------------------------------------------------------------
my @Cell_to_Node = @{$ref_to_Cell_to_Node};
&store_Cells_to_Node(@Cell_to_Node);

local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
my @Cell_to_Freq = @{$ref_to_Cell_to_Freq};
&store_Cells_to_Freq(@Cell_to_Freq);
#------------------------------------------------------------------------
local $tempnodenum,$EUTRANCELLFREQRELATIONID,$eutranfreqband,$element;
local $tcount1,$tcount2,$telement,$tempextnodenum,$tempextnodecell;
# EUtran network configuration
local $GENERICNODECELLS=&getENVfilevalue($ENV,"GENERICNODECELLS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local $EXTERNALEUTRANCELLPROXIES_MAJOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MAJOR");
local $EXTERNALEUTRANCELLPROXIES_MINOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MINOR");
local $INTEREUTRANCELLRELATIONS_MAJOR=&getENVfilevalue($ENV,"INTEREUTRANCELLRELATIONS_MAJOR");
local $INTEREUTRANCELLRELATIONS_MINOR=&getENVfilevalue($ENV,"INTEREUTRANCELLRELATIONS_MINOR");
local $tempintereutrancellrelations;
local @networkblocks=(),@networkblockswithlteproxies=(),@eutranextnodes=();
local @designatedlteproxies=(),@nodematchedlteproxies;
local $networkblockslastnodenum=0;
local $element4,$counter,$match,$tempcounter,$tempcounter2,$tcounter;
local @nodeeutranextnodes=();
local $nmatch,$nelement1,$nelement2,$ncounter2,$ncounter3;
local @nallexternalnodecelldata,@nexternalnodecelldata;
local @sortednexternalnodecelldata;
local $nodecellindex,$ttlsizenallexternalnodecelldata;
local @eutranfreqbands=();
local $RelationsPerFreqBand,$RELATIONID;
local $nodenum,$EXTERNALNODESIM,$EXTERNALNODESTRING;
local $nodecountfornodestringname,$nodecountfornodestringname2;

# start size network by major minor breakdown
local $ttlnetworknodes=int($NETWORKCELLSIZE/$STATICCELLNUM);# ttl lte nodes in network
local $ltenetwork_major=$LTENETWORKBREAKDOWN,$ltenetwork_minor=$LTENETWORKBREAKDOWN;
$ltenetwork_major=~s/\:.*//;$ltenetwork_major=~s/^\s+//;$ltenetwork_major=~s/\s+$//;
$ltenetwork_minor=~s/^.*://;$ltenetwork_minor=~s/^\s+//;$ltenetwork_minor=~s/\s+$//;
local $ttlnetworknodes_major=int(($ttlnetworknodes/100)*$ltenetwork_major);
local $ttlnetworknodes_minor=int(($ttlnetworknodes/100)*$ltenetwork_minor);
local $RelationsPerFreqBand,$RELATIONID;
# end size network by major minor breakdown

# start size network by major minor EXTERNALENODEFUNCTION breakdown
local $extenodeb_major=$EXTERNALENODEBFUNCTION;
local $extenodeb_minor=$EXTERNALENODEBFUNCTION;
$extenodeb_major=~s/\:.*//;$extenodeb_major=~s/^\s+//;$extenodeb_major=~s/\s+$//;
$extenodeb_minor=~s/^.*://;$extenodeb_minor=~s/^\s+//;$extenodeb_minor=~s/\s+$//;
# end size network by major minor EXTERNALENODEFUNCTION breakdown

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
local $TOTALFREQCOUNT=6;
local $thismatch=0;
local $TOTALUTRANPEREUTRANCELL=4;

###############
# struct vars
###############
local $TtlGeranFreqGroupRelation=3;
local $TtlUtranFreqRelation=6;
local $TtladditionalPlmnList=5;
local $TtlactivePlmnList=6;
local $TtlallowedPlmnList=15;
local $MCC=353;
local $MNC=57;
local $MNClength=2;
local $tempcounter,$temcounter2;
local $tempcellnum;
####################
# Integrity Check
####################
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/){exit;}
local @GeranFreqGroup=&createGSMFreqGroup($NETWORKCELLSIZE,$STATICCELLNUM);
if (@GeranFreqGroup<2){
    print "FATAL ERROR : there is no GeranFreqGroup data generated\n";exit;
}# end if
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
  $NODESTRING=$LTENAME;

  print "Setting structs (EUtran,Geran,Utran) for $LTENAME\n"; 

  # get node primary and adjacent cells
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # workaround for error in &getLTESimStringNodeName
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

  @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  $CELLNUM=@primarycells;# flexible cellnum

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
  }# end if
  else{
      $TYPE="EUtranCellTDD";
  }# end else

 #---------------------------------------
 # start Irathom enabled Utran cells
 #---------------------------------------

 if($irathomsimmatch==1){

  if($thismatch==0){

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

        @MOCmds=();
    # build mo script
    @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,$TYPE=$ltecellname,UtranFreqRelation=$utranfreq
       exception none
       nrOfAttributes 3
       allowedPlmnList Array Struct $TtlallowedPlmnList
    ^;# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    
    @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtlallowedPlmnList){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $mcc
             mnc Integer $mnc
             mncLength Integer $mncLength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end while allowedPlmnList
    $tempcounter2++;
    
    @MOCmds=();
    @MOCmds=qq^
      )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    
    }# end if irathomsimmatch

   $tempcellnum++;

 }# end outer while TOTALUTRANCELLS
 
  $thismatch=1; # only need to do this once

 }# end thismatch

 }# end outer irathomsimmatch

 #--------------------------------------
 # end Irathom enabled Utran cells
 #--------------------------------------
 
 ############################################
 # start set ExternalEUtranCell Relations
 ############################################ 
 $CELLCOUNT=1;$tempcellnum=1;
   $cell_index=1;
   foreach $Cell (@primarycells) {
    # build mo script
    @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index
       identity $LTENAME-$tempcellnum
       exception none
       nrOfAttributes 3 
       additionalPlmnList Array Struct $TtladditionalPlmnList 
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    ###########################################
    # 1. start build additionalPlmnList struct array
    ###########################################
    @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtladditionalPlmnList){             
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end 
   #########################################
   # 1. end build additionalPlmnList struct array
   #########################################
   ###########################################
   # 2. start build activePlmnList struct array
   ###########################################
    @MOCmds=();
    @MOCmds=qq^
     activePlmnList Array Struct $TtlactivePlmnList
   ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtlactivePlmnList){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end
    @MOCmds=();
    @MOCmds=qq^
      )
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   #########################################
   # 2. end build activePlmnList struct array
   #########################################
   #########################################
   # 3. start build EUtranFreqRelation struct array
   #########################################
    @InterEUtranCellRelations = &getInterEUtranCellRelations($Cell, $ref_to_CellRelations);
    @related_cells = (@InterEUtranCellRelations, @primarycells);
    @Frequencies = &getCellsFrequencies($ref_to_Cell_to_Freq, @related_cells);
    foreach $Frequency (@Frequencies) {
    	
    	# CXP 903 0491-135-1
    	if(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)) {
    	   if($Frequency<36005){$Frequency=$Frequency+36004;}
    	}
    	
    	@MOCmds=();
    	# build mo script
    	@MOCmds=qq^ SET
    	  (
    	   mo ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index,EUtranFreqRelation=$Frequency
    	   exception none
    	   nrOfAttributes 3
    	   allowedPlmnList Array Struct $TtlallowedPlmnList
    	^;# end @MO
    	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    	@MOCmds=();$tempcounter=1;
    	while($tempcounter<=$TtlallowedPlmnList){
    		 @MOCmds=();
    		 # build mo script
    		 @MOCmds=qq^        nrOfElements 3
    		         mcc Integer $MCC
    		         mnc Integer $MNC
    		         mncLength Integer $MNClength
    		^;# end @MOCmds
    		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    		$tempcounter++;
    	}# end while allowedPlmnList
   	@MOCmds=();
   	@MOCmds=qq^
   	   )
   	 ^;# end @MO
   	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    }# end foreach @Frequencies
   #########################################
   # 3. end build EUtranFreqRelation struct array
   #########################################
   #########################################
   # SUPPRESSED - 4. start build GeranFreqGroupRelation struct array
   #########################################
   foreach $element(@GeranFreqGroup){
           ($nodenum,$freqgroup,$freqgroup2,$freqgroup3,$actualgroupnodesize)=split(/\../,$element);
            if($nodenum==$nodecountfornodestringname){last;}
   }# end foreach
   if ($nodenum!=$nodecountfornodestringname)
   {print "FATAL ERROR : $nodecountfornodestringname NOT matched in GSM realtime created network\n";exit;} 
   
   $tempcounter2=1;
   while($tempcounter2<=$TtlGeranFreqGroupRelation){ # start while TtlGeranFreqGroupRelation
    if($tempcounter2==1){$tempvar=$freqgroup;}
    if($tempcounter2==2){$tempvar=$freqgroup2;}
    if($tempcounter2==3){$tempvar=$freqgroup3;}
    @MOCmds=();
    # build mo script
    @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index,GeranFreqGroupRelation=$tempvar
       exception none
       nrOfAttributes 3
       allowedPlmnList Array Struct $TtlallowedPlmnList
    ^;# end @MO
    # $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    @MOCmds=();$tempcounter=1;
   
    while($tempcounter<=$TtlallowedPlmnList){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength
    ^;# end @MOCmds
    # $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end while allowedPlmnList
   $tempcounter2++;
   @MOCmds=();
   @MOCmds=qq^
      )
    ^;# end @MO
   # $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   }# end while TtlGeranFreqGroupRelation
   #########################################
   # SUPPRESSED - 4. end build GeranFreqGroupRelation struct array
   #########################################

   #--------------------------------------
   # start non Irathom enabled Utran cells
   #--------------------------------------

   if($irathomsimmatch==0){

   #########################################
   # DEPRECATED - 5. start build UtranFreqRelation struct array
   #########################################
   #########################################
   # DEPRECATED - 5. end build UtranFreqRelation struct array
   #########################################

   }# end outer irathomsimmatch

   #--------------------------------------
   # end  non Irathom enabled Utran cells
   #--------------------------------------

   $cell_index++;

   }# end foreach (@primarycells)
  #####################################
  # end create external enobdeb funcs
  #####################################

  push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

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
