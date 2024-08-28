#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : LTE 13B
# Purpose     : Sprint 1.2 Configure the LTE simulations to be 
#               consistent with ICON
# Description : enable by setting ICON MO data as follows :
#               Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIP=1,GigabitEthernet=1,IpInterface=1
#               Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIP=1,GigabitEthernet=1,IpInterface=2
#               IpOam=1,Ip=1
#               IpOam=1,Ip=1,IpHostLink=1
#               IpSystem=1,IpAccessHostEt=1
#               IpSystem=1,IpAccessHostEt=1,IpSyncRef=1 .. 8
#               IpSystem=1,IpAccessSctp=1
#               ENodeBFunction=1,EUtraNetwork=1,TermPointToMme=0
# Date        : Feb 2013
# Who         : epatdal
####################################################################
# Ver 1.1     : LTE13B
# Purpose     : Fix up inconsistencies in ICON attribute setting mainly IpHostLink and Ip=1 and IpAccessHostLink as there were
#               always being set to the defaultrouter0 of IPInterface 2.
#               IpInterface1 corresponds to IpAccessHostEt
#               IpInterface2 correspionds to IpHostLink and Ip=1
#               Also the TermPointoMme has being taken out
# Date        : 20/03/2013
# Who         : QGORMOR 
####################################################################
####################################################################
# Ver2        : LTE 14A
# Purpose     : check sim type which is either of type PICO or LTE
#               node network
# Description : checks the type of simulation and if type PICO
#               then exits the script and continues on to the next
#               script
# Date        : Nov 2013
# Who         : epatdal
####################################################################
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
local $forcounter,$cellid;
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
local $TDDWORKAROUND=&getENVfilevalue($ENV,"TDDWORKAROUND");
local $nodenum,$nodenum2,$nodenum3,$nodecountfornodestringname,$nodecountfornodestringname2;
# for node cells/adjacent cells
local @nodecells=();
local $nodecountinteger,@primarycells=(),@adjacentcells=();
local $tempadjacentcellsize,$adjacentcellsize;
local $eNBId,$ExternalENodeBFunctionId;
local $EXTERNALNODESIM,$EXTERNALNODESTRING,$tempcellnum;
# ensure TDD and FDD cells are not related
local $TDDSIMNUM=&getENVfilevalue($ENV,"TDDSIMNUM");
local $TEMPNODESIM="",$TDDMATCH=0;
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);

# ICON 
#   DONE means the data is already set pre ICON requirements
#   ? means unsure as to the data assignment
# Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIP=1,GigabitEthernet=1,IpInterface=1&2
local ($vid,$vlan,$networkPrefixLength,$defaultRouter0,$defaultRouter1,$defaultRouter2,$subnet);
# IpOam=1,Ip=1
local ($nodeIpAddress,$nodeInterfaceName=lh0);
# IpOam=1,Ip=1,IpHostLink=1
local ($ipAddress1);
# IpSystem=1,IpAccessHostEt=1
local ($ipAddress2);
# DONE IpSystem=1,IpAccessHostEt=1,IpSyncRef=1..8
# IpSystem=1,IpAccessSctp=1 ? no data lsited
# ENodeBFunction=1,EUtraNetwork=1,TermPointToMme=0 ? attribute location
local @IPHostLink=(); # returns data from sub getuniqueLTEipv4interfaceset
local $address_space1=10;
local $counter1,$maxcounter1;
local $icounter,$maxicounter=8;
local $icounter2,$maxicounter2=10;

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
  
    # get node primary and adjacent cells
    $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);

    # nasty workaround for error in &getLTESimStringNodeName
    if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
    }# end if
    else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

    @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
    $CELLNUM=@primarycells;# flexible cellnum

    # get ICON data IPinterfaces
    @IPHostLink=&getuniqueLTEipv4interfaceset($address_space1,$nodecountfornodestringname);

    ##################################
    # start enable ICON
    ##################################

    #-------------------------------------------------------------------------------------------------------
    # Start Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIP=1,GigabitEthernet=1,IpInterface=1/2
    #-------------------------------------------------------------------------------------------------------

    $counter1=1;$maxcounter1=2;
   
    print "enable $LTENAME for ICON \n";

    while($counter1<=$maxcounter1){# start while 
# Added in the following in Version 1.1, this ensures IPInterface 1 and 2 are assigned different IPAddresses, Main fix below
    if($counter1==1){
       $vid=100;
       $vlan="true";
       $networkPrefixLength=30;
       $defaultRouter0=$IPHostLink[1];
       $defaultRouter1=$IPHostLink[2];
       $subnet=$IPHostLink[0];
    }# end if
    else{
       $vid=900;
       $vlan="true";
       $networkPrefixLength=30;
       $defaultRouter0=$IPHostLink[4];
       $defaultRouter1=$IPHostLink[5];
       $subnet=$IPHostLink[3];
    }# end else 

    # build mo script
    @MOCmds=qq( SET 
      (
        mo "ManagedElement=1,Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIp=1,GigaBitEthernet=1,IpInterface=$counter1"
        exception none
        nrOfAttributes 16
        "IpInterfaceId" String "$counter1"
        "defaultRouter0" String "$defaultRouter0"
        "defaultRouter0State" Integer 0
        "defaultRouter1" String "0.0.0.0"
        "defaultRouter1State" Integer 0
        "defaultRouter2" String "0.0.0.0"
        "defaultRouter2State" Integer 0
        "defaultRouterPingInterval" Integer 4
        "defaultRouterTraffic" Integer 0
        "networkPrefixLength" Integer $networkPrefixLength
        "ownIpAddressActive" String "0.0.0.0"
        "ownIpAddressPassive" String "0.0.0.0"
        "subnet" String "$subnet"
        "userLabel" String "icon enabled"
        "vLan" Boolean $vlan
        "vid" Integer $vid
     );
    );# end @MO

     $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

     $counter1++;
    }# end while

    #-------------------------------------------------------------------------------------------------------
    # End Equipment=1,Subrack=1,Slot=1,PlugInUnit=1,ExchangeTerminalIP=1,GigabitEthernet=1,IpInterface=1/2
    #-------------------------------------------------------------------------------------------------------
    #-------------------------------------------------------
    # Start IpOam=1,Ip=1
    #-------------------------------------------------------

    @MOCmds=();
    # build mo script
    @MOCmds=qq( SET
    ( 
       mo "ManagedElement=1,IpOam=1,Ip=1"
       exception none
       nrOfAttributes 2
       "nodeInterfaceName" String "lh0" 
       "nodeIpAddress" String "$IPHostLink[5]"
    );
    );# end @MO

   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);  

   #-------------------------------------------------------
   # End IpOam=1,Ip=1
   #-------------------------------------------------------
   #-------------------------------------------------------
   # Start IpOam=1,Ip=1,IpHostLink=1
   #-------------------------------------------------------
  
   @MOCmds=(); 
   # build mo script
   @MOCmds=qq( SET
     ( 
      mo "ManagedElement=1,IpOam=1,Ip=1,IpHostLink=1"
      exception none
      nrOfAttributes 1
      "ipAddress" String "$IPHostLink[5]"

     );
    );# end @MO

   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  
  #-------------------------------------------------------
  # End IpOam=1,Ip=1,IpHostLink=1
  #-------------------------------------------------------
  #-------------------------------------------------------
  # Start IpSystem=1,IpAccessHostEt=1
  #-------------------------------------------------------
  @MOCmds=();
  @MOCmds=qq( SET
          (
           mo "ManagedElement=1,IpSystem=1,IpAccessHostEt=1"
           exception none
           nrOfAttributes 1
           "ipAddress" String "$IPHostLink[2]"         
         
          );
         );# end @MO

  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);            

  #-------------------------------------------------------
  # End IpSystem=1,IpAccessHostEt=1
  #-------------------------------------------------------
  #-------------------------------------------------------
  # Start IpSystem=1,IpAccessHostEt=1,IpSyncRef=1 .. 8
  #-------------------------------------------------------
  @MOCmds=();
  $icounter=1;

  while($icounter<=$maxicounter){ 

   @MOCmds=qq( SET
          (
           mo "ManagedElement=1,IpSystem=1,IpAccessHostEt=1,IpSyncRef=$icounter"
           nrOfAttributes 9
           "IpSyncRefId" String "1"
           "administrativeState" Integer 0
           "availabilityStatus" Integer 0
           "cachedIpAddress" String ""
           "ntpServerIpAddress" String ""
           "operationalState" Integer 0
           "reservedBy" Array Ref 0
           "syncStatus" Integer 0
           "userLabel" String ""

          );
         );# end @MO

   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
   $icounter++;

  }# end while maxicounter  

  #-------------------------------------------------------
  # End IpSystem=1,IpAccessHostEt=1,IpSyncRef=1 .. 8
  #-------------------------------------------------------
  #-------------------------------------------------------
  # Start IpSystem=1,IpAccessSctp
  #-------------------------------------------------------
  @MOCmds=();
  @MOCmds=qq( SET
          (
           mo "ManagedElement=1,IpSystem=1,IpAccessSctp=1"
           nrOfAttributes 7
           "IpAccessSctpId" String "1"
           "availabilityStatus" Integer 0
           "ipAccessHostEtRef1" Ref "null"
           "ipAccessHostEtRef2" Ref "null"
           "operationalState" Integer 0
           "reservedBy" Array Ref 0
           "userLabel" String ""
          );
         );# end @MO

  $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

# QGORMOR I removed the following as it does not seem to be needed by ICON, I have left it here just in case it needs to be added back in
  

#-------------------------------------------------------
  # End IpSystem=1,IpAccessSctp
  #-------------------------------------------------------
  #------------------------------------------------------------------
  # Start ManagedElement=1,ENodeBFunction=1,TermPointToMme=$icounter2
  #------------------------------------------------------------------
  @MOCmds=();
  $icounter2=1;

  #while ($icounter2<=$maxicounter2){

  #@MOCmds=qq( SET
  #        (
  #         mo "ManagedElement=1,ENodeBFunction=1,TermPointToMme=$icounter2
  #         nrOfAttributes 20
  #         "mmeName" String "SGSNMME"
  #         "ipAddress1" String "30.30.30.1"
  #         );
  #       );# end @MO

  #$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
  #$icounter2++;
 
  #}# end while
  # QGORMOR REmoved as not needed...
  #------------------------------------------------------------------
  # End ManagedElement=1,ENodeBFunction=1,TermPointToMme=$icounter2
  #------------------------------------------------------------------  

   ##################################
   # end enable ICON
   ##################################

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
  @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
  print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink @NETSIMMOSCRIPTS;
unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
