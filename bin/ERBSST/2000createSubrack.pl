#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# version1    : LTE 14A ST Simulations
# Revision    : CXP 903 0491-28
# Jira        : NETSUP-773 
# purpose     : implements LTE support for mRBS 
# description : implements LTE support for mRBS 
# date        : Sept 2013
# who         : ecasjim
####################################################################
####################################################################
# Version2    : LTE 14A
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
# Version3    : LTE 14B.1
# Revision    : CXP 903 0491-47-4
# Purpose     : workaround1 for removing Micro nodes from LTE14B.1
#               28K network  
# Description : workaround1 to supress Micro nodes
# Date        : May 2014
# Who         : epatdal
####################################################################
####################################################################
# Version4    : LTE 14B.1
# Revision    :	CXP 903 0491-87-1
# Purpose     : SMO/SHM equipment information integrated into the
#		LTE build script
# Description : SMO/SHM equipment information integrated into the
#		LTE build script with agreed information
# Date        : 28 Aug 2014
# Who         : ebildun
####################################################################
####################################################################
# Version5    : LTE 15B
# Revision    : 903 0491-102-1
# purpose     : suppress MICRO cells creation in LTE15B network
# Description : networked MICRO outside scope for LTE15B - LMI-14:003150 PA15
# Jira        : EriDoc LMI-14:003150 PA15 
# date        : Dec 2014
# who         : epatdal
####################################################################
####################################################################
# Version6    : LTE 15B
# Revision    : CXP 903 0491-122-1
# Jira        : NETSUP-1019
# Purpose     : ensure this script fires for only LTE simulations 
#               and not DG2 or PICO
# Description : verify that $SIMNAME is not of type DG2 or PICO
# Date        : Feb 2015
# Who         : epatdal
####################################################################
####################################################################
# Version7    : LTE 16A
# Revision    : CXP 903 0491-162-1 
# Jira        : CIS-11151
# Purpose     : ENM Support for SHM                
# Description : ENM Support for SHM
# Date        : June 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version8    : LTE 15.16
# Revision    : CXP 903 0491-179-1
# Jira        : NETSUP-3162
# Purpose     : create additional 8 subracks and 28 slots per subrack
# Description : create 8 subracks and 28 subrack slots under
#               ManagedElement=1,Equipment=1,Subrack=1
# Date        : Oct 2015
# Who         : edalrey
####################################################################
####################################################################
# Version9    : LTE 16.01
# Revision    : CXP 903 0491-188-1
# Jira        : NSS-979
# Purpose     : implement scalable MRBS node distribtion  
# Description : distribute MRBS node amongst 1 cell nodes based on
#               percentage defined in /dat/CONFIG.env               
# Date        : 08 Dec 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version10   : LTE 16.7
# Revision    : CXP 903 0491-209-1
# Jira        : NSS-2141
# Purpose     : Modification of attributes in 8th and 9th subrack
#               MO for SHM in ERBS simulations.
# Description : Setting attributes in 8th and 9th subrack.
# Date        : Apr 2016
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
use LTE_NodeConfigurability;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
	print "@helpinfo\n";
	exit(1);
}
# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){
	exit;
}
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
local $MRBSPERCENT=&getENVfilevalue($ENV,"MRBSPERCENT");
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $nodecountinteger,$tempcellnum,@primarycells;
local $nodecountfornodestringname;
local $TTLNODENUM=int($NETWORKCELLSIZE/$STATICCELLNUM);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
	unlink "$NETSIMMOSCRIPT";
}
################################
# MAIN
################################
print "... ${0} ended running at $date\n";
local $requiredSubracks=9;

# Subrack operationalProductData fields
local $subrackProductName='ERBS14B';
local $subrackProductNumber="E.1.120";
local $subrackProductRevision="CXP21";
local $subrackSerialNumber="lienb0635";
local $subrackProductionDate="5";

local $userLabel="";
local $requiredSlots=28;

# Slot productData fields
local $slotProdName="ERBS14B";
local $slotProdNumber="ENM14B";
local $slotSerialNumber="3oQ";
local $slotProductionDate="''";

local @netsup3162ProductRevisions=("CXP123","CXP124","3CXP125","4CXP1222","5CXPt24","6CXPe24","7CXP324","8CXP124y","9CXP334","10CX8P124","11CX9P124","12CXP1i024","13CXP1io924","14CXPi87124","15CXPi009124","16CXPi78124","17CXP13324","18CXP12w14","19CXP12we4","20CXP111124","21CXP122224","22CXP133324","23CXP124321","24CXP124123","25CXP12445","26CXP124424","27CXP124553","28CXP124665");
# Size of slotProductRevisions should be the same as requiredSlots
local @netsup3610ProductRevisions=();
local @slotProductRevisions=();
push @slotProductRevisions, @netsup3162ProductRevisions;
push @slotProductRevisions, @netsup3610ProductRevisions;
if ($requiredSlots ne scalar @slotProductRevisions) {
	print "ERROR: There is an incorrect number of Slot product revisions (".scalar @slotProductRevisions.") for the number of Slots given (".$requiredSlots.").\nNow exiting ${0}\n\n";
	exit;
}
local $MRBSPERCENT=&getENVfilevalue($ENV,"MRBSPERCENT");
local @microNodeRatio=&getNodeDistributionRatio($MRBSPERCENT);
local $distributionInterval=$microNodeRatio[1];
local $distributedNodes=$microNodeRatio[0];
local $microIntervalCounter=0;
local $distributedNodesCounter=0;
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
	else{
		$nodecountfornodestringname=$nodecountinteger;
	}# end workaround

    @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
    $CELLNUM=@primarycells;

    $subrackProductName = "ERBS14B";

    if ($CELLNUM == 1) {
        $microIntervalCounter++;
        #######################################################################
        # determine if productdata needs to be mRBS enabled
        # if it does then $productdata="RBS6501"
        # ie. ManagedElement>Equipment>Subrack:operationalProductData=RBS 6501
        #######################################################################
        if ($microIntervalCounter > $distributionInterval) {
            $subrackProductName = 'RBS 6501';
            $distributedNodesCounter++;
        }

        if ($distributedNodesCounter >= $distributedNodes) { 
            $microIntervalCounter = 0;
            $distributedNodesCounter = 0; 
        }
    }

	local $SMOENABLED=&getENVfilevalue($ENV,"SMOENABLED");
	if($SMOENABLED eq "YES"){
		#######################################################################
		#--------------------------------------------------------------------
		# CXP 903 0491-87-1 - create Subrack updated & set Slot added
		#--------------------------------------------------------------------
                #--------------------------------------------------------------------
                # CXP 903 0491-209-1 - Modify 8th and 9th Subrack
                #--------------------------------------------------------------------
		#################################
		# Start create Subrack
		#################################
		for ($subrack=1; $subrack <= $requiredSubracks; $subrack++) {
		    local $subrackPosition=$subrack."B";
                    if ($subrack == 8) {#CXP 903 0491-209-1
                        $subrackPosition="";
                        @MOCmds=();
                        @MOCmds=qq^ CREATE
                        (
                                parent "ManagedElement=1,Equipment=1"
                                identity "$subrack"
                                moType Subrack
                                exception none
                                        nrOfAttributes 4
                                        "operationalProductData" Struct
                                                nrOfElements 5
                                                "productName" String "$subrackProductName"
                                                "productNumber" String $subrackProductNumber
                                                "productRevision" String $subrackProductRevision
                                                "serialNumber" String $subrackSerialNumber
                                                "productionDate" String $subrackProductionDate
                                        "administrativeProductData" Struct
                                                nrOfElements 5
                                                "productNumber" String $LTENAME
                                                "productRevision" String $LTENAME
                                                "productName" String $LTENAME
                                                "productInfo" String $LTENAME
                                                "productionDate" String $LTENAME
                                        "userLabel" String "$subrackProductName"
                                        "subrackPosition" String "$subrackPosition"
                        )
                        ^;# end @MO
                        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                        }#end if for Subrack=8
                        if ($subrack == 9) {#CXP 903 0491-209-1
                        @MOCmds=();
                        @MOCmds=qq^ CREATE
                        (
                                parent "ManagedElement=1,Equipment=1"
                                identity "$subrack"
                                moType Subrack
                                exception none
                                        nrOfAttributes 4
                                        "operationalProductData" Struct
                                                nrOfElements 5
                                                "productName" String ""
                                                "productNumber" String $subrackProductNumber
                                                "productRevision" String $subrackProductRevision
                                                "serialNumber" String $subrackSerialNumber
                                                "productionDate" String $subrackProductionDate
                                        "administrativeProductData" Struct
                                                nrOfElements 5
                                                "productNumber" String $LTENAME
                                                "productRevision" String $LTENAME
                                                "productName" String ""
                                                "productInfo" String $LTENAME
                                                "productionDate" String $LTENAME
                                        "userLabel" String "$subrackProductName"
                                        "subrackPosition" String "$subrackPosition"
                        )
                        ^;# end @MO
                        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                        }#end if for Subrack=9
                        else {
			@MOCmds=();
			@MOCmds=qq^ CREATE
			(
				parent "ManagedElement=1,Equipment=1"
				identity "$subrack"
				moType Subrack
				exception none
					nrOfAttributes 4
					"operationalProductData" Struct
						nrOfElements 5
						"productName" String "$subrackProductName"
						"productNumber" String $subrackProductNumber
						"productRevision" String $subrackProductRevision
						"serialNumber" String $subrackSerialNumber
						"productionDate" String $subrackProductionDate
					"administrativeProductData" Struct
						nrOfElements 5
						"productNumber" String $LTENAME
						"productRevision" String $LTENAME
						"productName" String $LTENAME
						"productInfo" String $LTENAME
						"productionDate" String $LTENAME
					"userLabel" String "$subrackProductName"
					"subrackPosition" String "$subrackPosition"
			)
			^;# end @MO
			$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                        }#end else
			#################################
			# Start slots
			#################################
			local $slotIdentity=0;
			foreach $slotProdRevision (@slotProductRevisions) {
				$slotIdentity++;
				@MOCmds=();
				@MOCmds=qq^ SET
				(
					mo "ManagedElement=1,Equipment=1,Subrack=$subrack,Slot=$slotIdentity"
					identity "$slotIdentity"
					exception none
						nrOfAttributes 1
						"productData" Struct
							nrOfElements 5
							"productName" String $slotProdName
							"productNumber" String $slotProdNumber
							"productRevision" String $slotProdRevision
							"serialNumber" String $slotSerialNumber
							"productionDate" String $slotProductionDate
				)
				^;# end @MO
				$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
			}#end foreach
			push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
			#################################
			# End slots
			#################################
		}# end for loop
		#################################
		# End create Subrack
		#################################
	}
	else {
		#################################
		# Start create Subrack
		#################################
		@MOCmds=();
		@MOCmds=qq^ CREATE
		(
			parent "ManagedElement=1,Equipment=1"
			identity "1"
			moType Subrack
			exception none
			nrOfAttributes 2
				"operationalProductData" Struct
					nrOfElements 5
					"productName" String "$productdata"
					"productNumber" String ""
					"productRevision" String ""
					"serialNumber" String ""
					"productionDate" String ""
				"userLabel" String "$productdata"
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		#################################
		# End create Subrack
		#################################
	}
	################################
	# build MML script
	################################
	@MMLCmds=(
		".open ".$SIMNAME,
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
