#!/usr/bin/perl 
### VERSION HISTORY
########################################################################
########################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-151-1
# User Story  : OSS-77951
# Purpose     : Create & Set EnodeB MO for DG2
# Description : support for DG2 nodes to create & set DG2 
# Date        : May 2015
# Who         : xsrilek
########################################################################
# Version2    : LTE 16A
# Revision    : CXP 903 0491-165-1
# User Story  : NETSUP-3258
# Purpose     : set eNBId's correctly
# Description : To resolve Multiple Master state of EUtranCellFDD MOs in DG2
# Date        : August 2015
# Who         : xsrilek
########################################################################
####################################################################
# Version3    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               TermPointToSGW MO
# Date        : feb 2018
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

# check if SIMNAME is of type PICO
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
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
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $FTPDIR=&getENVfilevalue($ENV,"FTPDIR");
local $TOTALNETWORKNODES=$LTE*$NUMOFRBS;
local $ENBID_offset=($LTE*$DG2NUMOFRBS)-($DG2NUMOFRBS);
local $ENBID;
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

while ($NODECOUNT<=$DG2NUMOFRBS){# start outer while

# get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
 # local $managedElement=&getManagedElement($LTENAME);
#create EnodeBFunction
	@MOCmds=();
	@MOCmds=qq( CREATE
      (
      parent "ManagedElement=$LTENAME"
       identity 1
       moType ENodeBFunction
       exception none
       nrOfAttributes 3
     );
    );# end @MO   
       
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
#CXP 903 0491-165-1
$ENBID=$NODECOUNT+$ENBID_offset;

	#set EnodeBFunction	
	@MOCmds=qq^ SET
	(
	  mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1" 
	   identity "1" 
	   exception none 
	   nrOfAttributes 2 
	   eNodeBPlmnId Struct  
	   nrOfElements 3 
	   mcc Int32 353 
	   mnc Int32 57 
	   mncLength Int32 2 
	   eNBId Int32 $ENBID 
	   userLabel String $FTPDIR 
	)
    SET
    (
       mo "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:TermPointToSGW=1"
       exception none
       nrOfAttributes 1
       "timeOfCreation" String "2017-11-29T09:32:56" 
    )
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds); 
 
   push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT); 

  ################################################ 
  # build mml script 
  ################################################
  @MMLCmds=(".open ".$SIMNAME,
            ".select ".$LTENAME,
            ".start ",
            "useattributecharacteristics:switch=\"off\"; ",
            "kertayle:file=\"$NETSIMMOSCRIPT\";"         
  );# end @MMLCmds
  
  $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
  
  $ENBID++;
  $NODECOUNT++;
}# end outer while

  # execute mml script
 #  @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

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
