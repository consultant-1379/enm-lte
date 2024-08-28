#!/usr/bin/perl
# VERSION HISTORY
##########################################################################
# Version1    : LTE 17.09
# Revision    : CXP 903 0491-295-1
# Jira        : NSS-11244
# Purpose     : Support for Twamp Attributes in Radio Node
# Description : To set Twamp Attributes
# Date        : May 2017
# Who         : xkatmri
##########################################################################
# Version1    : LTE 17.12
# Revision    : CXP 903 0491-301-1
# Jira        : NSS-13212
# Purpose     : TWAMP Initiator and Responder configuration on LTE nodes
# Description : To set Twamp Attributes
# Date        : July 2017
# Who         : xmitsin
##########################################################################

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
use LTE_OSS14;
use LTE_OSS15;
####################
# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
#----------------------------------------------------------------
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTE15B-v6x160-RVDG2-FDD-LTE01 CONFIG.env 1);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}

# check if SIMNAME is of type PICO or DG2
if (&isSimPICO($SIMNAME)=~m/NO/ && &isSimDG2($SIMNAME)=~m/NO/)
{exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1;
local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS"); 

print "... ${0} started running at $date\n";

while ($NODECOUNT<=$DG2NUMOFRBS){

$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

# build mml script
	@MOCmds=();
	@MOCmds=qq^

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:Transport=1"
    identity "1"
    moType RtnL3Router:Router
    exception none
    nrOfAttributes 1
    "routerId" String "1"
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:Transport=1,RtnL3Router:Router=1"
    identity "1"
    moType RtnTwampInitiator:TwampInitiator
    exception none
    nrOfAttributes 1
    "twampInitiatorId" String "1"
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:Transport=1,RtnL3Router:Router=1,RtnTwampInitiator:TwampInitiator=1"
    identity "1"
    moType RtnTwampInitiator:TwampTestSession
    exception none
    nrOfAttributes 1
    "twampTestSessionId" String "1"
)

CREATE
(
    parent "ComTop:ManagedElement=$LTENAME,ComTop:Transport=1,RtnL3Router:Router=1"
    identity "1"
    moType RtnTwampResponder:TwampResponder
    nrOfAttributes 1
    "twampResponderId" String "1"
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
	$NODECOUNT++;

}# end outer while DG2NUMOFRBS

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
