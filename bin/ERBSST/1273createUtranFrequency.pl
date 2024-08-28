#!/usr/bin/perl 
### VERSION HISTORY
####################################################################
# Version1    : Created for LTE O 10.0 TERE
# Date        : 14 July 2009
# Who         : Ronan Mehigan
####################################################################
# Version2    : Modified for req id 2490
# Purpose     : To set arfcnValueUtranDl attribute of UtranFrequency
# Date        : 09 Nov 2009
# Who         : Fatih ONUR
####################################################################
# Version3    : Modified for FT
# Purpose     : Improvement of script design
# Description : Script will not run unless it is TYPE of FT
# Date        : 09 JUL 2010
# Who         : Fatih ONUR
####################################################################
####################################################################
# Version4    : LTE 13B
# Revision    : 5
# Purpose     : Sprint 0.7  Irathom LTE WCDMA
# Description : enables support for 10,000 simulated online WRAN
#               ExternalUtranCells (external cell data supplied by 
#               the WRAN network team)
# Dependency  : ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv  
# Date        : Jan 2013
# Who         : epatdal
####################################################################
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
# Version6    : LTE 14.2
# Revision    : CXP 903 0491-70-1
# Jira        : NETSUP-1672
# Purpose     : support for LTE2WRAN for IRATHOM 
# Description : implement LTE2WRAN for IRATHOM
# SNID        : LMI-14:001028
# Date        : May 2014
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
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
local @MOCmds,@MMLCmds,@netsim_output;
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
local $templtename1;$templtename2;
local $irathomsimmatch=0,$arrayposition=0,$match;
local $element2;
# LTE14.2
local @utranfreqlist=();
local @uniqutranfreqlist=();
local $utranfreqcounter=0;
local %hash;
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
   print "IRATHOM : executing script $scriptpath/createLTE2WRANutranrelations.pl\n";
   $retval=system("cd $scriptpath;./createLTE2WRANutranrelations.pl");
   
   # verify script success  
   if($retval<0){
      print "FATAL ERROR : in execution $scriptpath.createLTE2WRANutranrelations.pl\n";exit;
   }# end if

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
                $csvinputfileline=&getIRATHOMcsvfilerawvalue($element2);
                ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl)=split(/;/,$csvinputfileline);
                # determine IRATHOM max UtranFrequency required  
                $TOTALFREQCOUNT=$utranfreq;
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

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  #------------------------------------------------
  # start2 get IRATHOM Utran cells data
  #------------------------------------------------
  $irathomsimmatch=0;$match=0;$arrayposition=0;

  # LTE14.2 create IRATHOM enabled utranfreqlist
  $utranfreqcounter=0;
  @utranfreqlist=();

  if (uc($IRATHOMENABLED) eq "YES"){
     foreach $element(@IRATHOMLTE2WRANFILENAME2){# start inner foreach

             #-----------------------------------------------------------
             # Start check for non ROWID data from WRAN input file
             #-----------------------------------------------------------
             # ROWID
             if($element=~/ROWID/){# start inner if
                $csvinputfileline=&getIRATHOMcsvfilerawvalue($element);
                ($rowid,$ltecellname,$utranfreqrel,$utranfreq,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$earfcndl)=split(/;/,$csvinputfileline);
             }# end innner if

             #-----------------------------------------------------------
             # start verify LTE node name is in @IRATHOMLTE2WRANFILENAME
             #-----------------------------------------------------------
             $templtename1=$LTENAME;
             $templtename2=$ltecellname;$templtename2=~s/-.*//;
             if($templtename2=~m/$templtename1/){
               $irathomsimmatch=1;

               # LTE14.2 write frequencies
               $utranfreqlist[$utranfreqcounter]="$utranfreq"; 

               $utranfreqcounter++;
 
               #last;# break the loop we have a sim match for irathom
             }# end inner if

             #-----------------------------------------------------------
             # end verify LTE node name is in @IRATHOMLTE2W1GRANFILENAME
             #-----------------------------------------------------------
             #-----------------------------------------------------------
             # start check for non ROWID data from WRAN input file
             #-----------------------------------------------------------
             if(($rowid =~m/ /)||($rowid =~m/\#/)){next;}
               else {}# end else

             #-----------------------------------------------------------
             # End check for non ROWID data from WRAN input file
             #-----------------------------------------------------------

             $arrayposition++;
     }# end inner foreach
  }# end if
  #------------------------------------------------
  # end2 get IRATHOM Utran cells data
  #------------------------------------------------
  # LTE14.2
  @uniqutranfreqlist=@utranfreqlist;

  %hash = map { $_, 1 } @utranfreqlist;
  @uniqutranfreqlist=keys %hash;
  
  # create UtranFrequencies
  
  print "Creating UtranFrequencies for $LTENAME\n"; 
 
  $FREQCOUNT=1;
  @MOCmds=();

   # LTE14.2
   #############################
   # START : IRATHOM not enabled
   #############################
   if($irathomsimmatch==0){
   $TOTALFREQCOUNT=6;
   while ($FREQCOUNT<=$TOTALFREQCOUNT){# while $TOTALFREQCOUNT
    # create UtranFrequency

    @MOCmds=qq^CREATE
      (
        parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1"
           identity $FREQCOUNT
           moType UtranFrequency
           exception none
           nrOfAttributes 1
           arfcnValueUtranDl Integer $FREQCOUNT
     );
    ^;# end @MO

     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

     $FREQCOUNT++;
    }# end while TOTALFREQCOUNT
   }# end IRATHOM
   ############################
   # END : IRATHOM not enabled
   ############################

   #############################
   # START : IRATHOM enabled
   #############################
   if($irathomsimmatch==1){
     $utranfreqcounter=0;       
   while (<@uniqutranfreqlist>){# while 
    # create UtranFrequency

    @MOCmds=qq^CREATE
      (
        parent "ManagedElement=1,ENodeBFunction=1,UtraNetwork=1"
           identity $uniqutranfreqlist[$utranfreqcounter]
           moType UtranFrequency
           exception none
           nrOfAttributes 1
           arfcnValueUtranDl Integer $utranfreqlist[$utranfreqcounter]
     );
    ^;# end @MO

     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

     $utranfreqcounter++;
    }# end while 

   }# end IRATHOM
   ############################
   # END : IRATHOM enabled
   ############################

  push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

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
