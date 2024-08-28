#!/usr/bin/perl 
### VERSION HISTORY
####################################################################
# Version1    : Created for Non-Planned PCI
# Revision    : CXP 903 0491-95-1
# Jira        : OSS-45751
# Description : Two new MOs need to be populated:
#	        nonPlannedPhysCellId set to 494
#		and nonPlannedPhysCellIdRange set to 9.
# 		This configuration is only for 10% of
#		the Micro/Macro network.
# Date        : 17 Sept 2014
# Who         : ecasjim
#####################################################################
####################################################################
# Version2    : Modified to support CSG and Hybrid CSG Features
# Revision    : CXP 903 0491-235-1
# Jira        : NSS-4527
# Description : Two new MOs need to be populated for each CSG and
#		Hybrid CSG
#	        sgPhysCellId = 486, csgPhysCellIdRange = 8
#		hybridCsgPhysCellId = 476, hybridCsgPhysCellIdRange = 10
#		This configuration is based on the percentage in the
#		CONFIG.env  for Micro/Macro network.
# Date        : 08 July 2016
# Who         : xsrilek
####################################################################
####################################################################
# Version3    : ENM 16.15
# Revision    : CXP 903 0491-260-1
# Jira        : NSS-6876
# Purpose     : Handle Non-Planned, CSG, Hybrid CSG feature skipping
#               for small builds
# Description : Change the equality check condition so that skipping
#               of the scripts is done properly.
# Date        : Sep 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 18B
# Revision    : CXP 903 0491-319-1
# Jira        : NSS-13832
# Purpose     : Increase in LTE Handover relations based on Softbank MR
# Description : Increase LTE Handover relations per node
# Date        : Nov 2017
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
Example: $0  LTEG1301-limx160-RV-FDD-LTE01 CONFIG.env 01);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $LTENETWORKBREAKDOWN=&getENVfilevalue($ENV,"LTENETWORKBREAKDOWN");

# start size network by major minor breakdown
local $ttlnetworknodes=int($NETWORKCELLSIZE/$STATICCELLNUM);# ttl lte nodes in network
local $ltenetwork_major=$LTENETWORKBREAKDOWN,$ltenetwork_minor=$LTENETWORKBREAKDOWN;
$ltenetwork_major=~s/\:.*//;$ltenetwork_major=~s/^\s+//;$ltenetwork_major=~s/\s+$//;
$ltenetwork_minor=~s/^.*://;$ltenetwork_minor=~s/^\s+//;$ltenetwork_minor=~s/\s+$//;
local $ttlnetworknodes_major=int(($ttlnetworknodes/100)*$ltenetwork_major);
local $ttlnetworknodes_minor=int(($ttlnetworknodes/100)*$ltenetwork_minor);
local $NumOfFreqAllowed;
# end size network by major minor breakdown

# for node cells/adjacent cells
local $nodecountinteger,@primarycells=();
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
local $EXTERNALENODEBFUNCTION=&getENVfilevalue($ENV,"EXTERNALENODEBFUNCTION");
local @eutranfreqbands=&getNetworkEUtranFrequencyBands($NETWORKCELLSIZE,$EXTERNALENODEBFUNCTION,@PRIMARY_NODECELLS);

# Non-Planned PCI values
local $nonPlannedPCIRange=9;
local $nonPlannedPCIId=494;
# CSG PCI Values
local $csgPhysCellIdRange=8;
local $csgPhysCellId=486;
# Hybrid CSG PCI Values
local $hybridCsgPhysCellIdRange=10;
local $hybridCsgPhysCellId=476;

local $NonPlannedPCIPercentage=&getENVfilevalue($ENV,"NPPCIPERCENTAGE");
local $csgPercentage=&getENVfilevalue($ENV,"CSGPERCENTAGE");
local $hybridCsgPercentage=&getENVfilevalue($ENV,"HYBRIDCSGPERCENTAGE");
local @featureNodes,@nonPlannedPCINodes,@csgNodes,@hybridCsgNodes;
local $totalFeatureNodesCount;
local $csgNodeCountCounter=1;
local $NPciNodeCountCounter=1;
local $hybridCsgNodeCountCounter=1;
local $totalFeaturePercentage=$NonPlannedPCIPercentage+$csgPercentage+$hybridCsgPercentage;

if($totalFeaturePercentage<=100){ $AdjustedFeaturePercentage=((1 / $totalFeaturePercentage) * 100);}
else {
	print "FATAL ERROR : Percentage of features greater than 100\n";
	print "NPPCIPERCENTAGE=$NonPlannedPCIPercentage\n";
	print "CSGPERCENTAGE=$csgPercentage\n";
	print "HYBRIDCSGPERCENTAGE=$hybridCsgPercentage\n";
	exit;
}

# Calculations to get percentages for feature implementation
local $nPciinTotlaFeaturePercentage=int(($NonPlannedPCIPercentage/$totalFeaturePercentage)*100);
local $adjustedNPciPercentage=((1 / $nPciinTotlaFeaturePercentage) * 100);
local $totalFeaturePercentagewithoutNPci=$totalFeaturePercentage-$NonPlannedPCIPercentage;
local $csgperintotalFeaturePercentage=int(($csgPercentage/$totalFeaturePercentagewithoutNPci)*100);
local $adjustedCsgPercentage=((1 / $csgperintotalFeaturePercentage) * 100);
local $totalFeaturePercentagewithoutNPciCsg=$totalFeaturePercentage-$NonPlannedPCIPercentage-$csgPercentage;
local $hybridCsgperintotalFeaturePercentage=int(($hybridCsgPercentage/$totalFeaturePercentagewithoutNPciCsg)*100);
local $adjustedHybridCsgPercentage=((1 / $hybridCsgperintotalFeaturePercentage) * 100);

# Check support for Feature MOs (Non-Planned PCI, CSG, hybrid CSG)
local $MIMVERSION=&queryMIM($SIMNAME);
local $MIMsupportforNonPlannedPCI = "E1200";
local $MIMsupportforCSG = "G1260";
local $MIMsupportforhybridCSG = "G1260";
local $mimcomparisonstatusNPCI=&isgreaterthanMIM($MIMVERSION,$MIMsupportforNonPlannedPCI);
local $mimcomparisonstatusCSG=&isgreaterthanMIM($MIMVERSION,$MIMsupportforCSG);
local $mimcomparisonstatushybridCSG=&isgreaterthanMIM($MIMVERSION,$MIMsupportforhybridCSG);

####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
if(@eutranfreqbands<1){
   print "FATAL ERROR : @eutranfreqbands < 1\n";
   exit;
}# end if
################################
# MAIN
################################
print "...${0} started running at $date\n";

while ($NODECOUNT<=$NUMOFRBS){
 if($NODECOUNT % $AdjustedFeaturePercentage == 0) { push (@featureNodes, $NODECOUNT); }
 else {
  print "Skipping nodes to satisfy Features(Non-Planned, CSG, Hybrid CSG) percentage requirement of $NonPlannedPCIPercentage, $csgPercentage, $hybridCsgPercentage \n";
  $NODECOUNT++;
  next;
 }
 $NODECOUNT++;
}

$totalFeatureNodesCount=@featureNodes;
while ($NPciNodeCountCounter<=$totalFeatureNodesCount){
  if($NPciNodeCountCounter % $adjustedNPciPercentage==0) { push (@nonPlannedPCINodes, $featureNodes[$NPciNodeCountCounter-1]); }
  $NPciNodeCountCounter++;
}
@featureNodes=&removeArrayFrmArray(\@nonPlannedPCINodes,\@featureNodes);
$totalFeatureNodesCount=@featureNodes;
while ($csgNodeCountCounter<=$totalFeatureNodesCount){
  if($csgNodeCountCounter % $adjustedCsgPercentage==0) { push (@csgNodes, $featureNodes[$csgNodeCountCounter-1]); }
  $csgNodeCountCounter++;
}
@featureNodes=&removeArrayFrmArray(\@csgNodes,\@featureNodes);
$totalFeatureNodesCount=@featureNodes;
while ($hybridCsgNodeCountCounter<=$totalFeatureNodesCount){
  if($hybridCsgNodeCountCounter % $adjustedHybridCsgPercentage==0) { push (@hybridCsgNodes, $featureNodes[$hybridCsgNodeCountCounter-1]); }
  $hybridCsgNodeCountCounter++;
}
######################################
#Start Implemeting Features
######################################
  if($mimcomparisonstatusNPCI eq "yes"){
	&implementFeature("NPCI",@nonPlannedPCINodes);
  }
  if($mimcomparisonstatusCSG eq "yes"){
	&implementFeature("CSG",@csgNodes);
  }
  if($mimcomparisonstatushybridCSG eq "yes"){
	&implementFeature("hybridCSG",@hybridCsgNodes);
  }
######################################
#End Implemeting Features
######################################

 #CXP 903 0491-260-1
    if ( $NETSIMMMLSCRIPT eq "") {
    print "... ${0} ended running as no Non-Planned, CSG, Hybrid CSG cells were created at $date\n";
    exit;
    }

 # execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
  print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
#unlink "$NETSIMMMLSCRIPT";
#unlink @NETSIMMOSCRIPTS;
print "... ${0} ended running at $date\n";

################################
#Start subroutines
################################
#---------------------------------------------------------------
#  Name : implementFeature
#  Description : implemets features
#			-> Non-Planned PCI cells
#			-> CSG cells
#			-> hybrid CSG cells
#
#  Params : "NPCI" or "CSG" or "hybridCSG" ,@nonPlannedPCINodes
#  Example : &implementFeature("NPCI",@nonPlannedPCINodes);
#  Return : nothing
#
#---------------------------------------------------------------
sub implementFeature{
 local ($feature,@nodes)=@_;
foreach $nodeCount (@nodes) {
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$nodeCount);

  # get the node eutran frequency id
  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$nodeCount,$NUMOFRBS);

  # Determine the number of frequency to be used based on major minor network
  if($nodecountinteger>$ttlnetworknodes_minor){
     $NumOfFreqAllowed=4;
  }# end if
  else{$NumOfFreqAllowed=9;
	   }# end else
  # end number of frequency determination based on major minor network

  # get node flexible primary cells
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountinteger]};

  $cell_index=1;
  foreach $Cell (@primarycells) {
    # check cell type
    # CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $Cell)) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
      $TYPE="EUtranCellFDD";
    }# end if
    else{
      $TYPE="EUtranCellTDD";
    }# end else

    local $fre_counter=0;
    @InterEUtranCellRelations = &getInterEUtranCellRelations($Cell, $ref_to_CellRelations);
    @cells_in_our_node = @{$PRIMARY_NODECELLS[$nodecountinteger]};
    @related_cells = (@InterEUtranCellRelations, @cells_in_our_node);
    @Frequencies = &getCellsFrequencies($ref_to_Cell_to_Freq, @related_cells);

    # Frequencies covered by those cells
    local @Frequencies = &getCellsFrequencies($ref_to_Cell_to_Freq, @related_cells);
    @Frequencies_tmp = @Frequencies;
    # Removing blank elements in @Frequencies array.
    @Frequencies = grep($_,@Frequencies_tmp);

    # Counter to check if $NumOfFreqAllowed is satisfied 
    local $counter=0;

    foreach $Frequency (@Frequencies) {

    $counter=$counter+1;
    
    # CXP 903 0491-135-1
    if($TYPE eq "EUtranCellTDD") {
      if($Frequency<36005){$Frequency=$Frequency+36004;}
    }
		if ($feature eq "NPCI"){
		$NETSIMMOSCRIPT=&implementNPCI($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
		}
		elsif($feature eq "CSG"){
		$NETSIMMOSCRIPT=&implementCSG($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
		}
		elsif($feature eq "hybridCSG"){
		$NETSIMMOSCRIPT=&implementhybridCSG($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
		}
		else {
		print "There is no implementation for the requested feature : $feature\n";
		}
    if($counter eq $NumOfFreqAllowed) {last;}
    }
    $cell_index++;
  }
  &buildMMLScript($LTENAME,$NETSIMMOSCRIPT);
 }
}

#---------------------------------------------------------------
#  Name : implementNPCI
#  Description : implemets feature
#			-> Non-Planned PCI cells
#
#  Params : $TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount
#  Example : &implementNPCI($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
#  Return : NETSIMMOSCRIPT name
#
#---------------------------------------------------------------
sub implementNPCI{
local($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount)=@_;
#========================================
# Non-Planned PCI MO sets START
#========================================
 @MOCmds=();
 @MOCmds=qq( SET
     (
     mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index,EUtranFreqRelation=$Frequency"
     exception none
     nrOfAttributes 2
     nonPlannedPhysCellIdRange Integer $nonPlannedPCIRange
     nonPlannedPhysCellId Integer $nonPlannedPCIId
    );
   );# end @MO
#========================================
# Non-Planned PCI MO sets END
#========================================
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$nodeCount,@MOCmds);
 push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
 return $NETSIMMOSCRIPT;
}

#---------------------------------------------------------------
#  Name : implementCSG
#  Description : implemets feature
#			-> CSG cells
#
#  Params : $TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount
#  Example : &implementCSG($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
#  Return : NETSIMMOSCRIPT name
#
#---------------------------------------------------------------
sub implementCSG{
local($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount)=@_;
#========================================
# CSG PCI MO sets START
#========================================
 @MOCmds=();
 @MOCmds=qq( SET
     (
     mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index,EUtranFreqRelation=$Frequency"
     exception none
     nrOfAttributes 2
     csgPhysCellIdRange Integer $csgPhysCellIdRange
     csgPhysCellId Integer $csgPhysCellId
    );
   );# end @MO
#========================================
# CSG PCI MO sets END
#========================================
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$nodeCount,@MOCmds);
 push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
 return $NETSIMMOSCRIPT;
}

#---------------------------------------------------------------
#  Name : implementhybridCSG
#  Description : implemets feature
#			-> CSG cells
#
#  Params : $TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount
#  Example : &implementhybridCSG($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount);
#  Return : NETSIMMOSCRIPT name
#
#---------------------------------------------------------------
sub implementhybridCSG{
local($TYPE,$LTENAME,$cell_index,$Frequency,$nodeCount)=@_;
#========================================
# hybrid CSG PCI MO sets START
#========================================
 @MOCmds=();
 @MOCmds=qq( SET
     (
     mo "ManagedElement=1,ENodeBFunction=1,$TYPE=$LTENAME-$cell_index,EUtranFreqRelation=$Frequency"
     exception none
     nrOfAttributes 2
     hybridCsgPhysCellIdRange Integer $hybridCsgPhysCellIdRange
     hybridCsgPhysCellId Integer $hybridCsgPhysCellId
    );
   );# end @MO
#========================================
# hybrid CSG PCI MO sets END
#========================================
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$nodeCount,@MOCmds);
 push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
 return $NETSIMMOSCRIPT;
}

#---------------------------------------------------------------
#  Name : buildMMLScript
#  Description : To write kertayle commands into mml
#
#  Params : $LTENAME,$NETSIMMOSCRIPT
#  Example : &buildMMLScript($LTENAME,$NETSIMMOSCRIPT);
#  Return : nothing
#
#---------------------------------------------------------------
sub buildMMLScript{
local ($LTENAME,$NETSIMMOSCRIPT)= @_;
 @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds

  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
}
#---------------------------------------------------------------
#  Name : removeArrayFrmArray
#  Description : removes Array1 from Array2
#
#  Params : $refToArray1,$refToArray2
#  Example : &removeArrayFrmArray(\@nonPlannedPCINodes,\@featureNodes);
#  Return : array1 without elements of array2
#
#---------------------------------------------------------------
sub removeArrayFrmArray{
local ($refToArray1,$refToArray2)=@_;
local @array1=@{$refToArray1};
local @array2=@{$refToArray2};

foreach my $arrelemet (@array1){
	my $idx = 0;
	foreach (@array2) {
		if ($arrelemet == $_) {
			splice (@array2, $idx, 1);
		}
		$idx++;
	}
}
return @array2;
}
################################
#End subroutines
################################
################################
# END
################################
