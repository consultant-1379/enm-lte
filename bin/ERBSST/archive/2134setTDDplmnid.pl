#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : LTE 12.0 ST Simulations 
# Purpose     : Snag List 12.0 Issue 6/10 
# Description : Sets
#               ENodeBFunction>UtraNetwork>ExternalCellTDD->plmnIdentity mcc=353,mnc=33,mnclength=2
# Date        : Nov 2011
# Who         : epatdal
####################################################################
####################################################################
# Ver2        : LTE 12.2
# Purpose     : LTE 12.2 Sprint 0 Feature 7
# Description : enable flexible LTE EUtran cell numbering pattern
#               eg. in CONFIG.env the CELLPATTERN=6,3,3,6,3,3,6,3,1,6
#               the first ERBS has 6 cells, second has 3 cells etc.
# Date        : Jan 2012
# Who         : epatdal
####################################################################
####################################################################
# Ver3        : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use POSIX;
use LTE_OSS12;
use LTE_CellConfiguration;
use LTE_General;
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

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/YES/){exit;}
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
local $NETSIMMOSCRIPT=$MOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
$NETSIMMOSCRIPT=~s/\.\///;local $whilecounter;
local $TYPE,$TYPEID;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM");
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
local $nodecountinteger,$tempcellnum;
local $nodecountfornodestringname;
local @EXTUTRANCELLID=&getNetworkExtUtranCellID($NETWORKCELLSIZE,$CELLNUM);
local $temputranfrequency,$utranfrequency=6;
local $nodenum,$utranfrequency,$cellnum,$extutrancellid;
local $snodenum,$sutranfrequency,$scellnum;
local $element,$UtranCellRelationNum;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
###############
# struct vars
###############
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
while ($NODECOUNT<=$NUMOFRBS){
  # get node name
  $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);

  $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
  # nasty workaround for error in &getLTESimStringNodeName
  if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
  }# end if
  else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
  
  @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
  $CELLNUM=@primarycells;
  # WORKAROUND : ensure do not exceed the max number of MO children
  #if($CELLNUM==6){$CELLNUM=4;}

  # check cell type
  if (&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) {
      $TYPE="EUtranCellFDD";
    print  "INFO : ${0} TDD sim. fix only - sets ENodeBFunction>UtraNetwork>ExternalCellTDD->plmnIdentity mcc=353,mnc=33,mnclength=2\n\n";
      exit;
  }# end if
  else{
     $TYPE="EUtranCellTDD";
  }# end else

################################
# start ExternalUtranCellFDD
################################
$tempcellnum=1;$temputranfrequency=1;
while($temputranfrequency<=$utranfrequency){ # while utranfrequency
 $tempcellnum=1;
 while($tempcellnum<=$STATICCELLNUM){ # while CELLNUM

   # find ExternalUtranCellID from EXTUTRANCELLID
   # ordered as nodenum-utranfrequency-cellnum-extutrancellid
   foreach $element(@EXTUTRANCELLID){
         ($snodenum,$sutranfrequency,$scellnum,$extutrancellid)=split(/-/,$element);
          if(($snodenum==$nodecountfornodestringname)&&($sutranfrequency==$temputranfrequency)&&($scellnum==$tempcellnum)){
              last;
          }# end if
   }# end foreach element
   @MOCmds=();
   @MOCmds=qq^ SET
      (
       mo ManagedElement=1,ENodeBFunction=1,UtraNetwork=1,UtranFrequency=$temputranfrequency,ExternalUtranCellTDD=$extutrancellid
       exception none
       nrOfAttributes 3
       "plmnIdentity" Struct
        nrOfElements 3
        mcc Integer 353
        mnc Integer 33
        mncLength Integer 2
      )
    ^;# end @MO

    $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT,@MOCmds);
  $tempcellnum++;
 }# end while CELLNUM
 $temputranfrequency++;
}# end while utranfrequency
################################
# end ExternalUtranCellFDD
################################
###################
# build mml script 
################### 
@MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\"; ",
          "kertayle:file=\"$NETSIMMOSCRIPT\";"
  );# end @MMLCmds
 $NETSIMMMLSCRIPT=&makeMMLscript("write",$MMLSCRIPT,@MMLCmds);

 # execute mml script
 @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

 # output mml script execution 
 print "@netsim_output\n";
  
 # remove mo script
 #unlink "$NETSIMMOSCRIPT";
 $NODECOUNT++;
}# end outer NODECOUNT while
################################
# CLEANUP
################################
$date=`date`;
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
