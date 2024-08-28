#!/usr/bin/perl
### VERSION HISTORY
############################################################################################################################################
# Version1    : 28K LTE Test Hotel Network SNAG List - Issue 22/NETSUP708 
# Link : https://confluence-oss.lmera.ericsson.se/display/PDUCD/14B.1+28K+LTE+Test+Hotel+Network+SNAG+List
# Purpose     : sets Licensing.OptionalFeatures MOs             
# Description : sets the following values :
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Anr=1",attributes="serviceStateAnr=1";
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,AdvCellSup=1",attributes="serviceStateAdvCellSup=1";
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Pci=1",attributes="serviceStatePci=1";
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Rps=1",attributes="serviceStateRps=1";
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,HoOscCtrlRel=1",attributes="serviceStateHoOscCtrlRel=1";
#               "ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,HoOscCtrlUE=1",attributes="serviceStateHoOscCtrlUE=1";             
# Date        : July 2014
# Who         : epatdal
############################################################################################################################################
####################################################################
# Version2    : LTE 15B
# Revision    : CXP 903 0491-124-1
# Jira        : NETSUP-1019
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version3    : LTE 15B
# Revision    : CXP 903 0491-124-1
# Jira	      : OSS-67768 
# Purpose     : deprecate support for HoOscCtrlRel 
# Description : deprecate support for attribute HoOscCtrlRel in
#	        node MIMs > F180
# Date        : Feb 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version4    : LTE 15B
# Revision    : CXP 903 0491-125-1
# Jira	      : NETSUP-2330
# Purpose     : set fingerprint MO attribute under ManagedElement,
#		SystemFunctions, Licensing               
# Description : fingerprint = LTENAME_fp i.e. LTE01ERBS00001_fp 
# Date        : Feb 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version5    : LTE 15B
# Revision    : CXP 903 0491-131-1
# Jira        : NETSUP-2330
# Purpose     : serviceStateAdvCellSup not supported for mim <= C1127
#	        under ManagedElement, SystemFunctions, OptionalFeatures               
# Description : modified CXP 903 0491-84-1, 29/08/2014 to exclude
#		serviceStateAdvCellSup support without exiting script  
# Date        : March 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version6    : LTE 15.14
# Revision    : CXP 903 0491-170-1
# Jira        : NETSUP-3322
# Purpose     : set Licensing attributes under ManagedElement=1,
#		SystemFunctions=1,Licensing=1
# Description : set LicensingId, licenceFileUrl and UserLabel under
#               ManagedElement=1,SystemFunctions=1,Licensing=1
# Date        : Sept 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version7    : LTE 18.10
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
local $MIMOptionalFeatures="C1128";
# CXP 903 0491-131-1, 10/03/2015
local $serviceStateAdvCellSupEnabled=&isgreaterthanMIM($MIMVERSION,$MIMOptionalFeatures);
# CXP 903 0491-124-1, 19/02/2015 
local $disableHoOscCtrlRelSupport="F180";
local $HoOscCtrlRelSupport=&isgreaterthanMIM($disableHoOscCtrlRelSuppor,$MIMVERSION);
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
print "... ${0} ended running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){
# get node name
$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

$nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
# nasty workaround for error in &getLTESimStringNodeName
if(substr($MIMVERSION, 0, 1) le "H")
{
if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
}# end if
else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
################################
# set serviceStateAnr
################################
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Anr=1""
       exception none
       nrOfAttributes 1
       serviceStateAnr Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end serviceStateAnr
################################
################################
# set serviceStateAdvCellSup
################################
# CXP 903 0491-131-1, 10/03/2015
if($serviceStateAdvCellSupEnabled eq "yes"){
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,AdvCellSup=1""
       exception none
       nrOfAttributes 1
       serviceStateAdvCellSup Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
} # end if
################################
# end serviceStateAdvCellSup
################################
################################
# set serviceStatePci
################################
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Pci=1""
       exception none
       nrOfAttributes 1
       serviceStatePci Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end serviceStatePci
################################

################################
# set serviceStateRps
################################
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,Rps=1""
       exception none
       nrOfAttributes 1
       serviceStateRps Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end serviceStateRps
################################

################################
# set serviceStateHoOscCtrlRel
################################
# CXP 903 0491-124-1, 19/02/2015 
if($HoOscCtrlRelSupport eq "yes") {
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,HoOscCtrlRel=1""
       exception none
       nrOfAttributes 1
       serviceStateHoOscCtrlRel Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
}# end if
################################
# end serviceStateHoOscCtrlRel
################################

################################
# set serviceStateHoOscCtrlUE
################################
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1,OptionalFeatures=1,HoOscCtrlUE=1""
       exception none
       nrOfAttributes 1
       serviceStateHoOscCtrlUE Integer 1
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
}
################################
# end serviceStateHoOscCtrlUE
################################
################################
# set fingerprint    
# CXP 903 0491-125-1
################################
$fingerprint=$LTENAME."_fp";
@MOCmds=();
@MOCmds=qq^ SET
      (
      mo ""ManagedElement=1,SystemFunctions=1,Licensing=1""
       exception none
       nrOfAttributes 8
       fingerprint String $fingerprint
       LicensingId String "30Q"
       licenseFileUrl String '\"http://10.128.163.227:80/cello/licensing/\"' 
       userLabel String "ENM14BLICENSEING"
      )
    ^;# end @MO
$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
################################
# end fingerprint
################################

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
