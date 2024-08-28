#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 14.1.7
# Revision    : CXP 903 0491-42-19
# Purpose     : set PICO2PICO ExternalENodeBFunction.eNBId              
# Description : creates support for the creation of PICO cell relations 
#               amongst PICO nodes
# Jira        : NETSUP-1019
# Date        : Nov 2013
# Who         : epatdal
####################################################################
####################################################################            
# Ver2        : LTE 15B         
# Revision    : CXP 903 0491-114-1              
# Purpose     : Emergency workaround.
# Description : Hardcodes the ERBS/PICO threshold at LTE51.
# Date        : 16 Dec 2014             
# Who         : edalrey         
#################################################################### 
####################################################################            
# Version3    : LTE 16A         
# Revision    : CXP 903 0491-155-1
# Jira        : NETSUP-3047    
# Purpose     : To offset PICO eNBId by number of preceding nodes in the network
# Description : Changed the offset for PICO eNBId by number of preceding nodes in the network i.e 5760(36*160)
# Date        : 05-June-2015             
# Who         : xkamvat         
####################################################################
####################################################################
# Version4    : LTE 17A
# Revision    : CXP 903 0491-229-1
# Jira        : NSS-4526
# Purpose     : Pico Network design as per the 17A SNID layout
# Description : Modify the codebase to build pico sims at any simulation
#               number
# Date        : 20-June-2015
# Who         : xsrilek
####################################################################
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
# start verify params
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0  LTEMSRBSV1x160-RVPICO-FDD-LTE36 CONFIG.env 36);
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
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $STATICCELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
local $CELLNUM;
local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");
local $PICOCELLNUM=&getENVfilevalue($ENV,"PICOCELLNUM");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
local $PICOSIMEND=&getENVfilevalue($ENV,"PICOSIMEND");
local $PICONETWORKCELLSIZE=&getENVfilevalue($ENV,"PICONETWORKCELLSIZE");
local $PICOMAJORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMAJORPERCENTNETWORK");
local $PICOMINORPERCENTNETWORK=&getENVfilevalue($ENV,"PICOMINORPERCENTNETWORK");
local $TOTALPICONODES=int($PICONETWORKCELLSIZE/$PICOCELLNUM);
# 80% of the nodes in the network
local $MAJORPICONETWORKNODES=int($TOTALPICONODES/100)*$PICOMAJORPERCENTNETWORK;
local $MINORPICONETWORKNODES=$TOTALPICONODES-$MAJORPICONETWORKNODES;
local $MAJORPICORELATIONSNUMBER=8;
local $MINORPICORELATIONSNUMBER=10;
local $PICORELATIONSNUMBER=0;
local $maxrelatednodes;
local @relatednodes=();
local $element,$arrcounter,$arrcounter2,$tempnum,$tempstringnode;
local $networkblockflag=0;
local $outercounter;
local $counter;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
   unlink "$NETSIMMOSCRIPT";}

# check if SIMNAME is of type PICO
if(&isSimPICO($SIMNAME)=~m/NO/){exit;}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
local $picotype="ExternalENodeBFunction";
local $cellcount=1;
$outercounter=0;

# CXP 903 0491-155-1 : offset PICO eNBId by number of preceding nodes in the network (36*160=5760)
#local $nodecountoffset=5760;	#int($NETWORKCELLSIZE / $CELLNUM28K) + 10;

while ($NODECOUNT<=$PICONUMOFRBS){

    # get node name
    $LTENAME=&getPICOSimStringNodeName($LTE,$NODECOUNT);

    # get node current nodecountnumber
    $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$LTE,$NODECOUNT,$PICONUMOFRBS);
    
    # check for current node's position in the network breakdown
    if($nodecountinteger<=$MAJORPICONETWORKNODES){
       $PICORELATIONSNUMBER=$MAJORPICORELATIONSNUMBER;}
    else{$PICORELATIONSNUMBER=$MINORPICORELATIONSNUMBER;}

    $maxrelatednodes=$PICORELATIONSNUMBER;

    if($outercounter>=$maxrelatednodes){$outercounter=0;$networkblockflag=0;}
     
    if($networkblockflag==0){
       $networkblockflag=1;

       # populate the related nodes
       $tempnum=$nodecountinteger;
       $arrcounter=0;$arrcounter2=0;

       while($arrcounter<$maxrelatednodes){
             # exclude current nodecounterintger from the relations
             $relatednodes[$arrcounter2]=$tempnum;
             $tempnum++;$arrcounter++;$arrcounter2++; 
       }# end inner while
    }# end networkblockflag
    
    ##################################
    # start set PICO2PICO cellrelations
    ##################################  
    $counter=1;$arrcounter=0;

    while($counter<=$PICORELATIONSNUMBER){
      
       $tempstringnode=&getPICOStringNodeName($PICOSIMSTART,$relatednodes[$arrcounter],$PICONUMOFRBS);

       $temppicosimnum=$tempstringnode;
       $temppicosimnum=~s/pERBS.*//;
       $temppicosimnum=~s/LTE0//;
       $temppicosimnum=~s/LTE//;
      
       $temppiconodenum=$tempstringnode;
       $temppiconodenum=~s/.*ERBS0000//;
       $temppiconodenum=~s/.*ERBS000//;
       $temppiconodenum=~s/.*ERBS00//;
       
       $tempnodecounter=&getPICOSimIntegerNodeNum($PICOSIMSTART,$temppicosimnum,$temppiconodenum,$PICONUMOFRBS);
       
        #add offset due to clash with macro lte
#	$tempnodecounter += $nodecountoffset;	
       # print "DEBUG $tempnodecounter \n"; 
          
	# exclude current node relation to itself
          if($LTENAME=~m/$tempstringnode/){$arrcounter++;$counter++;next;}  

          # build mml script 
          @MMLCmds=(".open ".$SIMNAME,
                    ".select ".$LTENAME,
                    ".start ",
          "useattributecharacteristics:switch=\"off\";",
"setmoattribute:mo=\"ManagedElement=$LTENAME,ENodeBFunction=1,EUtraNetwork=1,$picotype=$tempstringnode\",attributes=\"eNBId (int32)=$tempnodecounter\";"
    );# end @MMLCmds

    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
    $counter++;$arrcounter++;

   }# end inner while

  $outercounter++;
  $NODECOUNT++;
}# end outer while PICONUMOFRBS

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
