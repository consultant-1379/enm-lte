#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 11.2.8 ST Simulations 
# Purpose     : TEP Request : 6038
# Description : The MO TermPointToMme should be configured so that 
#               each ERBS has 10 TermPointToMme
#               A MME pool of 10 nodes serving the entire LTE network 
#               Each LTE node connects to the pool of 10 MME nodes
# Date        : Jan 2011
# Who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 13A
# Purpose     : Speed up sim creation
# Description : Script altered to use single MML script, single pipe
# Date        : Sep 2012
# Who         : lmieody
####################################################################
####################################################################
# Version3    : LTE 14A
# Revision    : CXP 903 0491-42-19
# Jira        : NETSUP-1019
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 14B
# Purpose     : Support E1180 
# Description : For E1180, MO servedPlmnIdList is not created 
# Date        : August 2014
# Who         : ecasjim
####################################################################
####################################################################
# Version5    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 15.15
# Revision    : CXP 903 0491-177-1
# Jira        : NETSUP-3585
# Purpose     : populate TermPointToMme MO attributes 
#               mmeGIListLTERelated, mmeCodeListLTERelated and 
#               mmeCodeListOtherRATs
# Description : set mmeGIListLTERelated, mmeCodeListLTERelated and 
#               mmeCodeListOtherRATs attributes under 
#               ManagedElement=1,ENodeBFunction=1,TermPointToMme=1
# Date        : Sept 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version7    : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts 
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
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
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# for storing data to create topology file
local $topologyDirPath=$scriptpath;
$topologyDirPath=~s/bin.*/customdata\/topology\//;

###############
# struct vars
###############
local $TtlTermPointToMmeMOs=10;
local $TtlservedPlmnIdListArrayStruct=6;
local $TtlservedPlmnListLTERelatedArrayStruct=16;
local $TtlservedPlmnListOtherRATsArrayStruct=32;
local $MCC=353;
local $MNC=57;
local $MNClength=2;
local $CounterforTermPointToMMe;
local $tempcounter;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/TermPointToMme.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){
  $CounterforTermPointToMMe=1; 
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
 
  while($CounterforTermPointToMMe<=$TtlTermPointToMmeMOs){# TermPointToMMe
    # build mo script

########################################################
# Support for E1180
########################################################

# Check support for updated GSM configuration
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMsupportforupdatedGSMconfiguration="E1180";

# Check support for updated GSM configuration
  $mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMsupportforupdatedGSMconfiguration);
  
  if($mimcomparisonstatus eq "yes")
  {
      @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1"
       identity $CounterforTermPointToMMe
         moType TermPointToMme
         exception none
         nrOfAttributes 3
      "mmeCodeListLTERelated" Array Integer 1
        0
      "mmeCodeListOtherRATs" Array Integer 1
        0
      "mmeGIListLTERelated" Array Integer 1
        0
    ^;# end @MO

print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  }

  else
  {
      @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1"
       identity $CounterforTermPointToMMe
         moType TermPointToMme
         exception none
         nrOfAttributes 6
      "mmeCodeListLTERelated" Array Integer 1
        0
      "mmeCodeListOtherRATs" Array Integer 1
        0
      "mmeGIListLTERelated" Array Integer 1
        0
       servedPlmnIdList Array Struct $TtlservedPlmnIdListArrayStruct
    ^;# end @MO

print $fh "@MOCmds";
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

    ###########################################
    # 1. start build servedPlmnIdList struct array
    ###########################################
    @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtlservedPlmnIdListArrayStruct){
     @MOCmds=(); 
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength 
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end servedPlmnIdList
 }

########################################################
# END Support for E1180
########################################################

   #########################################
   # 1. end build servedPlmnIdList struct array
   #########################################
   #########################################
   # 2. start build servedPlmnListLTERelated struct array
   #########################################
   @MOCmds=();
   @MOCmds=qq^
     servedPlmnListLTERelated Array Struct $TtlservedPlmnListLTERelatedArrayStruct      
   ^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtlservedPlmnListLTERelatedArrayStruct){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end servedPlmnListLTERelated 
   #########################################
   # 2. end build servedPlmnListLTERelated struct array
   #########################################
   #########################################
   # 3. start build servedPlmnListOtherRATs struct array
   #########################################
    @MOCmds=();
   @MOCmds=qq^
     servedPlmnListOtherRATs Array Struct $TtlservedPlmnListOtherRATsArrayStruct
   ^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   @MOCmds=();$tempcounter=1;
    while($tempcounter<=$TtlservedPlmnListOtherRATsArrayStruct){
     @MOCmds=();
     # build mo script
     @MOCmds=qq^        nrOfElements 3
             mcc Integer $MCC
             mnc Integer $MNC
             mncLength Integer $MNClength
    ^;# end @MOCmds
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $tempcounter++;
    }# end servedPlmnListOtherRATs
   #########################################
   # 3. end build servedPlmnListOtherRATs struct array
   #########################################
   #########################################
   # structs array clean up
   #########################################
    @MOCmds=();
    @MOCmds=qq^
      ) 
    ^;# end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
    $CounterforTermPointToMMe++;
   }# end inner TermPointToMMe while

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
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
