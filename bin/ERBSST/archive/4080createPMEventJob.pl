#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version     : LTE15B
# Revision    : CXP 903 0491-
# User Story  : OSS-65459
# Purpose     : Create pre-defined EventM jobs in MSRBS-V2 simulations.
# Description : Creates 6 pre-defined EventJobs to be used by ENM
#		Feature Test and RV.
# Date        : 09 Feb 2015
# Who         : SimNet/edalrey
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
use LTE_OSS13;
use LTE_Relations;
use LTE_OSS15;
####################
# Vars
####################
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEMSRBS-V415Bv6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# end verify params
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
local $PRESETPMJOBCOUNT=6;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}
# check if SIMNAME is of type DG2
if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$DG2NUMOFRBS){

	$LTENAME=&getDG2SimStringNodeName($LTE,$NODECOUNT);
	@MMLCmds=(
		".open ".$SIMNAME,
		".select ".$LTENAME,
		".start",
		"useattributecharacteristics:switch=\"off\";",
	);# end @MMLCmds
	$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

	local $pmJobCounter=1;
	while ($pmJobCounter<=$PRESETPMJOBCOUNT){
		local $eventJobId=9999+$pmJobCounter;
		local $description="normal priority cell trace event job";
		local $jobControl=0;
		local $eventGroupRef="";
		if ($pmJobCounter==5){
			$description="high priority cell trace event job";
		}
		if ($pmJobCounter==6){
			$description="continuous cell trace event job";
			$jobControl=1;
			$eventGroupRef="setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=10005\",attributes=\"eventGroupRef (moRef)=ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventGroup=CCTR\";";
		}
		# build mml script 
		@MMLCmds=(
			"createmo:parentid=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat\",type=\"EventJob\",name=\"$eventJobId\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"eventJobId(str)=$eventJobId\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"description (str)=$description\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"reportingPeriod (enum, TimePeriod)=5\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"jobControl (enum, JobControl)=$jobControl\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"fileOutputEnabled (Boolean)=true\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"fileCompressionType (enum, CompressionTypes)=0\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"streamOutputEnabled (Boolean)=false\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"streamCompressionType (enum, CompressionTypes)=0\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"requestedJobState (enum, JobState)=2\";",
			"setmoattribute:mo=\"ManagedElement=$LTENAME,SystemFunctions=1,PmEventM=1,EventProducer=Lrat,EventJob=$eventJobId\",attributes=\"currentJobState (enum, SessionState)=2\";",
			"$eventGroupRef"
		);# end @MMLCmds
		$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
		$pmJobCounter++;
	}# end PM Job Count loop

	$NODECOUNT++;
}# end outer while DG2NUMOFRBS

# execute mml script
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
# output mml script execution 
print "@netsim_output\n";
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
