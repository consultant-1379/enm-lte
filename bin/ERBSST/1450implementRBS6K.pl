#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 11.2.8 ST Simulations 
# purpose     : implements LTE RBS6K 
# description : implements LTE RBS6K
# cdm         : lmi-11:0179  
# date        : MAR 2011
# who         : epatdal
####################################################################
####################################################################
# Version2    : LTE 13A
# Purpose     : Speed up sim creation
# Description : Script altered to use single MML script, single pipe
# Date        : Sep 2012
# Who         : lmieody
####################################################################
####################################################################
# Version3    : LTE 13B_EU
# Revision    : CXP 903 0491-27
# Jira        : NETSUP-708
# Purpose     : Support for SON
# Description : added 2 OptionalFeatureLicense MOs to enable support 
#               for SON and the options can be chosen via CEX in 13B_EU
#               -> ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatureLicense=InterRatOffloadToUtran
#               -> ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatureLicense=ServiceSpecificLoadMgmt
# Date        : Aug 2013
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 14A
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
# Version5    : LTE 14B.1
# Revision    : CXP 903 0491-87-1	
# Purpose     : SMO/SHM equipment information integrated into the
#               LTE build script
# Description : SMO/SHM equipment information integrated into the
#               LTE build script with agreed information
# Date        : 28 Aug 2014
# Who         : ebildun
####################################################################
####################################################################
# Version6    : LTE 14B
# Revision    : CXP 903 0491-89-1
# Jira        : NETSUP-1173 
# Purpose     : Set MO attributes
# Description : Set MO attributes for simulations, updated for
#               Cabinet attribute data.
# Date        : Sept 2014 (Oct 2014)
# Who         : ebildun (edalrey)
####################################################################
####################################################################
# Version7    : LTE 15B
# Revision    : CXP 903 0491-124-1
# Jira        : OSS-55899,OSS-55904
# Purpose     : ensure this script fires for only LTE simulations
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version8    : LTE 16A
# Revision    : CXP 903 0491-162-1
# Jira        : CIS-11151
# Purpose     : ENM Support for SHM            
# Description : ENM Support for SHM
# Date        : June 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version9    : LTE 18.10
# Revision    : CXP 903 0491-340-1
# Jira        : NSS-18647
# Purpose     : OptionalFeature Mo Setting is not doing
# Description : ERBSJ Versions do not have OptionalFeature MO, so
#               we are not setting OptionalFeature attribute
# Date        : May 2018
# Who         : zyamkan
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
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local $element,$secequipnum;
local $nodenum,$sharingcabinetid,$ismanaged,$mixedmoderadio,$licensestatemixedmode;
local @RBS6KDATA=&createRBS6Kdata($NETWORKCELLSIZE,$STATICCELLNUM);
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
# MIM specific query for OptionalFeatureLicense non support
local $MIMVERSION=&queryMIM($SIMNAME);
# update for LTE14.2 support for D144-lim
local $MIMCdma2K1xRttSupport="D145";
local $mimsupport=&isgreaterthanMIM($MIMVERSION,$MIMCdma2K1xRttSupport);
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
if (@RBS6KDATA<2){
    print "ERROR : there is no RBS6K data generated\n";exit; 
}# end if
################################
# MAIN
################################
print "... ${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){
# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
# nasty workaround for error in &getLTESimStringNodeName
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
################################
# start setSharingCabinetId
################################
# find RBS6KDATA per node
# ordered as nodenum..sharingcabinetid..ismanaged..MixedModeRadio..licenseStateMixedMode
 foreach $element(@RBS6KDATA){
       ($nodenum,$sharingcabinetid,$ismanaged,$MixedModeRadio,$licenseStateMixedMode)=split(/\.\./,$element);
        if($nodenum==$nodecountfornodestringname){
            last;
        }# end if
 }# end foreach element

#  CXP 903 0491-89-1 - set attributes for SMO/SHM based on ENABLESMOSUPPORT switch in CONFIG.env
local $SMOENABLED=&getENVfilevalue($ENV,"SMOENABLED");
@MOCmds=();
if($SMOENABLED ne "YES"){
	@MOCmds=qq^ CREATE
	      (
	      parent "ManagedElement=1,Equipment=1"
	       identity 1
	       moType Cabinet
	       exception none
	       nrOfAttributes 2
	       CabinetId String "$sharingcabinetid"
	       cabinetIdentifier String "ABC_$sharingcabinetid"
	      )
	^;# end @MO
}
else {
	#update for NETSUP-1173
	local $currentcabidentifier;
	$currentcabidentifier="CAB_$sharingcabinetid";
	@MOCmds=qq^ CREATE
		(
		  parent "ManagedElement=1,Equipment=1"
		   identity $currentcabidentifier
		   moType Cabinet
		   exception none
		   nrOfAttributes 3
		   CabinetId String "$currentcabidentifier"
		   cabinetIdentifier String "$currentcabidentifier"
		   productData Struct
		   nrOfElements 5
		   productionDate String "20111221"
		   productName String "RBS6201"
		   productNumber String "BFM901290/064"
		   productRevision String "R1A"
		   serialNumber String "CC48118333"
		)
	^;# end @MO
}
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end setSharingCabinetId
################################
################################
# start MixedModeradio
################################
@MOCmds=();
$secequipnum=1;
@primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
$CELLNUM=@primarycells;
while($secequipnum<=$CELLNUM){
@MOCmds=qq^ SET
      (
      mo "ManagedElement=1,SectorEquipmentFunction=$secequipnum"
       exception none
       nrOfAttributes 1
       mixedModeRadio Boolean $MixedModeRadio
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
$secequipnum++;
}# end while
################################
# end MixedModeRadio
################################
# CXP 903 0491-87-1 - set Licensing added
local $SMOENABLED=&getENVfilevalue($ENV,"SMOENABLED");
if($SMOENABLED eq YES){
	#################################
	# Start set Licensing
	#################################
	@MOCmds=();
	@MOCmds=qq^ SET
	      (
	       mo "ManagedElement=1,SystemFunctions=1,Licensing=1"
		exception none
		nrOfAttributes 3
		userLabel String "dfgg"
		LicensingId String "1"
		licenseFileUrl String "http://10.128.163.227:80/cello/licensing/CppAutoGuiRnc61Atclvm935_nss_tor/CppAutoGuiRnc61NetsimRbs01/CPPRBSREF01_090827_085012.xml" 
	      )
	    ^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	#################################
	# End set Licensing
	#################################
}
################################
# start licenseStateMixedMode
################################
if(substr($MIMVERSION, 0, 1) le "H")
{
@MOCmds=();
if($licenseStateMixedMode eq "enabled"){
   $licenseStateMixedMode=1;
}
if($licenseStateMixedMode eq "disabled"){
   $licenseStateMixedMode=0;
}
@MOCmds=qq^ SET
      (
       mo "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,MixedMode=1"
        exception none
        nrOfAttributes 1
        licenseStateMixedMode Integer $licenseStateMixedMode
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
}
################################
# end licenseStateMixedMode
################################
#################################
# Start 13B_EU support for SON
#################################
@MOCmds=();
# MIM specific query for OptionalFeatureLicense support
 if(($mimsupport eq "yes")){
@MOCmds=qq^ CREATE
   (
    parent "ManagedElement=1,SystemFunctions=1,Licensing=1"
    identity "InterRatOffloadToUtran"
    moType OptionalFeatureLicense
    exception none
    nrOfAttributes 2
    "OptionalFeatureLicenseId" String "InterRatOffloadToUtran"
    "keyId" String ""
   )
   CREATE
   (
    parent "ManagedElement=1,SystemFunctions=1,Licensing=1"
    identity "ServiceSpecificLoadMgmt"
    moType OptionalFeatureLicense
    exception none
    nrOfAttributes 2
    "OptionalFeatureLicenseId" String "ServiceSpecificLoadMgmt"
    "keyId" String ""
    )
    ^;# end @MO
 $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
}# end if mimsupport
#################################
# End 13B_EU support for SON
#################################

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
print "... ${0} ended running at $date\n";
################################
# END
################################
