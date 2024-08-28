#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : Created for LTE ST Simulations 
# Purpose     : TEP Request : 5024
# Description : LTE PCI values in LTE ST Simulations 
# Date        : Dec 2010
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
# Purpose     : LTE 12.2 LTE Handover
# Description : enables flexible LTE EUtran cell LTE handover
# Date        : Feb 2012
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
# Purpose     : LTE 12.2 LTE Handover
# Description : revising cell relations as a whole
# Date        : August 2012
# Who         : lmieody
####################################################################
####################################################################
# Version6    : LTE 13A
# Purpose     : Speed up simulation creation
# Description : One MML script and one netsim_pipe
# Date        : Aug 2012
# Who         : lmieody
####################################################################
####################################################################
# Version7    : LTE 13B
# Revision    : CXP 903 0491-29
# Jira        : NETSUP-784
# Purpose     : Updating ExternalENodeBFunction.masterEnbFunctionId
#               with "1" as per stakeholder request
# Date        : Oct 2013
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 14A
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
# Version9    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version11   : LTE 17A
# Revision    : CXP 903 0491-245-1
# Jira        : NSS-5222
# Purpose     : Remove 2131,2132 scripts from enm-lte codebase
# Description : Merge the operations of scripts 2131,2132 into 1281,
#               1282 and remove 2131,2132 such that time for build
#               reduces for ERBS nodes
# Date        : July 2016
# Who         : xravlat
####################################################################
####################################################################
# Version12    : LTE 18B
# Revision    : CXP 903 0491-319-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version13   : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               ExternalENodeBFunction MO
# Date        : Feb 2018
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
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodenum,$nodenum2;
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local $nodecountfornodestringname,$nodecountfornodestringname2;
local $numofexternalenodebfuncs,$adjacentcellsize;
local $eNBId,$ExternalENodeBFunctionId;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
local $ref_to_Cell_to_Node = &buildCelltoNode(\@PRIMARY_NODECELLS);
# EUtran network configuration
local $GENERICNODECELLS=&getENVfilevalue($ENV,"GENERICNODECELLS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local $EXTERNALEUTRANCELLPROXIES_MAJOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MAJOR");
local $EXTERNALEUTRANCELLPROXIES_MINOR=&getENVfilevalue($ENV,"EXTERNALEUTRANCELLPROXIES_MINOR");
local @networkblocks=(),@networkblockswithlteproxies=(),@eutranextnodes=();
local $networkblockslastnodenum=0;
local $element4,$counter,$match;
local @nodeeutranextnodes=();

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

# LTE14B.1 MIM support for attribute mfbiSupport
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMmfbiSupport="D1455";
$mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMmfbiSupport);
###############
# struct vars
###############
local $ttlPlmngUGroupIdListArrayStruct=16;
local $mcc=353;
local $mnc=57;
local $mncLength=2;
local $groupIdListCounter;
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
# Make MO & MML Scripts
################################
print "MAKING MML SCRIPT\n";

while ($NODECOUNT<=$NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  print "Creates $LTENAME ExternalENodeBFunction ...\n";

  # get nodenum 
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

  # start size network by major minor EXTERNALENODEFUNCTION breakdown

  if($nodecountfornodestringname>$ttlnetworknodes_minor){
     $EXTERNALENODEBFUNCTION=$extenodeb_major;
  }# end if
  else{$EXTERNALENODEBFUNCTION=$extenodeb_minor;}# end else
  # end size network by major minor EXTERNALENODEFUNCTION breakdown

  #######################################################
  # start get external enodebfuntion
  #######################################################
  # Want to start with the number of the node ($nodecountfornodestringname)
  # and from that work out the cells that are related to its 
  # cells (@exteutrancells)
  # then the nodes holding those cells (@nodeeutranextnodes).
  # We then create the ExternalENodeBFunction for each of those nodes
  # Coming in to this phase all we need is $nodecountinteger and 
  # on the way out we need @nodeeutranextnodes
  # That should do it
  
  # Cells related to the cells in our node
  local @exteutrancells = &getNodeExternalEUtranCells($nodecountfornodestringname, $ref_to_CellRelations, \@PRIMARY_NODECELLS);

  # Nodes where those cells reside
  local @nodeeutranextnodes = &getNodesForCells($ref_to_Cell_to_Node, @exteutrancells);
  
  #######################################################
  # end get external enodebfuntion
  #######################################################
  #####################################
  # start create external enobdeb funcs
  #####################################
  local $nodenum,$EXTERNALNODESIM,$EXTERNALNODESTRING;
  local $counter=0;

  foreach $nodenum(@nodeeutranextnodes){

    $counter=$counter+1;
    $eNBId=$nodenum;

    $EXTERNALNODESIM=&getLTESimNum($nodenum,$NUMOFRBS);

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodenum>$NUMOFRBS){
         $nodecountfornodestringname2=($nodenum-($EXTERNALNODESIM-1)*$NUMOFRBS);
    }
    else{$nodecountfornodestringname2=$nodenum;}# end workaround

    $EXTERNALNODESTRING=&getLTESimStringNodeName($EXTERNALNODESIM,$nodecountfornodestringname2);

    # workaround to leave node ending with "0000"
    @EXT1 = split /ERBS/, $EXTERNALNODESTRING;
    if ("$EXT1[1]" == "0000") {
    $counter=$counter-1;
    next;}

    print "Create External EnodeBFunction Node $EXTERNALNODESTRING\n";

    ################################################
    # start : MIM support for attribute mfbiSupport
    ################################################
    if($mimcomparisonstatus eq "no"){ # no MIM support for mfbiSupport
      @MOCmds=();
      @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"
       identity $EXTERNALNODESTRING
       moType ExternalENodeBFunction
       exception none
       nrOfAttributes 6
       ExternalENodeBFunctionId String $EXTERNALNODESTRING
       eNBId Integer $eNBId
       "timeOfCreation" String "2017-11-29T09:32:56"
       masterEnbFunctionId String $eNBId
       eNodeBPlmnId Struct
        nrOfElements 3
        mcc Integer 353
         mnc Integer 57
         mncLength Integer 2
       gUGroupIdList Array Struct $ttlPlmngUGroupIdListArrayStruct
    ^;# end @MO
    }# end if
    else{@MOCmds=();
     @MOCmds=qq^ CREATE
      (
      parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"
       identity $EXTERNALNODESTRING
       moType ExternalENodeBFunction
       exception none
       nrOfAttributes 6
       ExternalENodeBFunctionId String $EXTERNALNODESTRING
       eNBId Integer $eNBId
       "timeOfCreation" String "2017-11-29T09:32:56"
       masterEnbFunctionId String $eNBId
       mfbiSupport Boolean true
       eNodeBPlmnId Struct
        nrOfElements 3
        mcc Integer 353
         mnc Integer 57
         mncLength Integer 2
       gUGroupIdList Array Struct $ttlPlmngUGroupIdListArrayStruct
    ^;# end @MO
    }# end else
    ################################################
    # end : MIM support for attribute mfbiSupport
    ################################################
    ###########################################
    # 1. start build gUGroupIdList struct array
    ###########################################
    $groupIdListCounter=1;
    while($groupIdListCounter<=$ttlPlmngUGroupIdListArrayStruct){
     # build mo script
     push(@MOCmds,(qq^        nrOfElements 4
             mcc Integer $mcc
             mnc Integer $mnc
             mncLength Integer $mncLength
             mmeGI Integer 0
    ^));# end @MOCmds
    $groupIdListCounter++;
    }# end
   push(@MOCmds,(qq^
      );
     ^));
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   #########################################
   # 1. end build gUGroupIdList  struct array
   #########################################

  if ($counter eq $EXTERNALENODEBFUNCTION){last;}

  }# end foreach create external enobdeb funcs
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
