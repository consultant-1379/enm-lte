#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-153-1
# Jira        : OSS-77951
# Purpose     : DG2 to LTE handover for LTE 16A
# Description : Creates ExternalERnodeB under Eutra Network
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version2    : LTE 18B
# Revision    : CXP 903 0491-316-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               ExternalENodeBFunction MO
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
use LTE_Relations;
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
local $whilecounter;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");

local $nodenum,$nodenum2;
# for node cells/adjacent cells

local $nodecountinteger,@primarycells=();
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

while ($NODECOUNT<=$DG2NUMOFRBS){

  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
  
  print "Creates $LTENAME ExternalENodeBFunction ...\n";

  # get nodenum 
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$DG2NUMOFRBS);

  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$DG2NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$DG2NUMOFRBS)+$NODECOUNT;
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

    $EXTERNALNODESIM=&getLTESimNum($nodenum,$DG2NUMOFRBS);

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodenum>$DG2NUMOFRBS){
         $nodecountfornodestringname2=($nodenum-($EXTERNALNODESIM-1)*$DG2NUMOFRBS);
    }
    else{$nodecountfornodestringname2=$nodenum;}# end workaround

    $EXTERNALNODESTRING=&getLTESimStringNodeName($EXTERNALNODESIM,$nodecountfornodestringname2);

	# workaround to leave node ending with "0000"
    @EXT1 = split /ERBS/, $EXTERNALNODESTRING;
    if ("$EXT1[1]" == "0000") {
    $counter=$counter-1;
    next;}

    print "Create ExternalEnodeBFunction for Node $EXTERNALNODESTRING\n";

     @MOCmds=qq( CREATE
      (
      parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:EUtraNetwork=1"
       identity $EXTERNALNODESTRING
       moType Lrat:ExternalENodeBFunction
       exception none
       nrOfAttributes 4
       eNBId Int32 $eNBId
       "timeOfCreation" String "2017-11-29T09:32:56"
       masterEnbFunctionId String $eNBId
       mfbiSupport Boolean true
       eNodeBPlmnId Struct
        nrOfElements 3
        mcc Int32 353
         mnc Int32 57
         mncLength Int32 2
     );
    );# end @MO   
       
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

    # counter to check it ExternalENodeBFunction is satisfied
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
