#!/usr/bin/perl
#VERSION HISTORY
####################################################################
# Version1    : LTE 17.14
# Revision    : CXP 903 0491-308-1
# Purpose     : Update site/siteLocation in ERBS/RadioNode nodes
# Description : Update site/siteLocation in ERBS/RadioNode nodes of
#               LTE sims for carrier Aggregation
# Jira        : NSS-13992
# Date        : Aug 2017
# Who         : zyamkan
####################################################################
# Version2    : LTE 17.16
# Revision    : CXP 903 0491-312-1
# Purpose     : Update scripts to avoid XML validation error
# Description : Update scripts to avoid XML validation error of
#               LTE sims for carrier Aggregation
# Jira        : NSS-15000
# Date        : Oct 2017
# Who         : xkatmri
####################################################################
# Version3    : LTE 18.02
# Revision    : CXP 903 0491-317-1
# Purpose     : Dakka Test suite fix
# Description : Update site in ERBS nodes of LTE sims for carrier
#               Aggregation
# Jira        : NSS-16118
# Date        : Nov 2017
# Who         : zyamkan
####################################################################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS14;
####################

# Vars
####################
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
# start verify params and sim node type
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEE119-V2x160-RV-FDD-LTE10 CONFIG.env 10);
if (!( @ARGV==3)){
   print "@helpinfo\n";exit(1);}
# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local @NETSIMMOSCRIPTS=();
local $Site1=";Dublin${LTE}";
local $Site2=";;Athlone${LTE}";
local $Site3="London:Athlone;Galway${LTE}";
local $Site4="Athlone;;;;London${LTE}";
local $Site5="London:Dublin;Limerick${LTE}";
local $Site6="North;Belfast${LTE}";
local $InvalidSite1="Dublin";
local $InvalidSite2="London:Dublin";
local $InvalidSite3="London:Athlone;";
local $InvalidSite4="Invalid";
local $InvalidSite5="Athlone;;;;";
local $InvalidSite6=":;";
local $InvalidSite="London:Manchester";
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
    
   @MOCmds=();

  if($NODECOUNT <= 5){
    $Site=$Site1;
  } elsif(($NODECOUNT >= 25)&&($NODECOUNT < 30)){
    $Site=$Site2;
  } elsif(($NODECOUNT >= 65)&&($NODECOUNT < 70)){
    $Site=$Site3;
  } elsif(($NODECOUNT >= 100)&&($NODECOUNT < 105)){
    $Site=$Site4;
  } elsif(($NODECOUNT >= 125)&&($NODECOUNT < 130)){
    $Site=$Site5;
  } elsif(($NODECOUNT >= 155)&&($NODECOUNT < 160)){
    $Site=$Site6;
  } elsif(($NODECOUNT >= 10)&&($NODECOUNT < 20)){
    $Site=$InvalidSite1;
  } elsif(($NODECOUNT >= 30)&&($NODECOUNT < 40)){
    $Site=$InvalidSite2;
  } elsif(($NODECOUNT >= 70)&&($NODECOUNT < 80)){
    $Site=$InvalidSite3;
  } elsif(($NODECOUNT >= 90)&&($NODECOUNT < 100)){
    $Site=$InvalidSite4;
  } elsif(($NODECOUNT >= 110)&&($NODECOUNT < 120)){
    $Site=$InvalidSite5;
  } elsif(($NODECOUNT >= 140)&&($NODECOUNT < 150)){
    $Site=$InvalidSite6;
  } else{
    $Site=$InvalidSite;
  }
    @MOCmds=qq( SET
(
    mo "ManagedElement=1"
    exception none
    nrOfAttributes 1
    "site" String "$Site"
));#end @MO
    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
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
}# end while condition 
 #execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution
  print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo scripts
#unlink @NETSIMMOSCRIPTS;
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################

