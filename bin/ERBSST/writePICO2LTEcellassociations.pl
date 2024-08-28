#!/usr/bin/perl
### VERSION HISTORY
######################################################################################
#
#     Author : SimNet/epatdal
#
#     Description : writes a bi-direction relationship between LTE and PICO
#     nodes and outputs to a file 
#     eg. ~/customdata/pico/LTE28000PICO2000networkcellrelations.csv
#      this is a bi-directional association between PICO and LTE nodes
#      in a LTE28K and PICO2K network
#      the PICO PO Anuj Sethi has created the following LTE PICO relationship
#      configuration which is used to generate the relationships file for
#      LTE14.1
# 
#      FOR 80% of the PICO network
#  
#      PICO 1,2,3 are related to :
#       LTE1=3 cells
#       LTE2=3 cells
#       LTE3=2 cells
#       LTE4,5,6,7 = 1 cell
#
#      PICO 4,5,6 are related to :
#       LTE2=3 cells
#       LTE3=3 cells
#       LTE4=2 cells
#       LTE1,5,6,7 = 1 cell
# 
#      PICO 7,8  are related to :
#       LTE1,2,3,4,5=2 cells
#       LTE6,7=1 cell
# 
#      FOR 20% of the PICO network
# 
#      PICO 1,2,3,4 are related to :
#       LTE1,2,3,4,5,6=4 cells
#       LTE7,8,9,10,11=3 cells
#       LTE12,13,14=1 cell
# 
#      PICO 5,6,7,8 are related to :
#       LTE2,3,4,5,6,7=4 cells
#       LTE8,9,10,11,12=3 cells
#       LTE13,14,1=1 cell
# 
#      PICO 9,10 are related to :
#       LTE4,5,6,7,8,9=4 cells
#       LTE10,11,12,13,14,1=3 cells
#       LTE2,3=1 cell
#
#       Syntax : ./writePICO2LTEcellassociations.pl LTE node minimumcellsize
#       Example : ./writePICO2LTEcellassociations.pl 6
#
#     Date : 18th February 2014
####################################################################
# Ver2        : LTE 14B.1
# Purpose     : check cellnum increment does not become 0 valued
# Description : CXP 903 0491-90-1
# Date        : September 2014
# Who         : edalrey
####################################################################            
# Ver3        : LTE 15B         
# Revision    : CXP 903 0491-117-1              
# Purpose     : Change the max cell sizes from 4 to 3. 
# Description : Allows for the decrease in the size of the cell pattern. 
# Date        : 06 Jan 2015             
# Who         : edalrey         
#################################################################### 
# Ver3        : LTE 16.08
# Revision    : CXP 903 0491-214-1
# Purpose     : Fix the condition to stop halting of code.
# Description : To give fix to resolve halting of code when node cell
#               size equals the NETWORKCELLSIZE
# Date        : 05 May 2016
# Who         : xkatmri
####################################################################
# Ver3        : LTE 16.08
# Revision    : CXP 903 0491-216-1
# Purpose     : Fix the condition to stop halting of code.
# Description : To resolve the bug after CXP 903 0491-214-1 code push
# Date        : 11 May 2016
# Who         : xkatmri
####################################################################
########################
#  Environment
########################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use POSIX;
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS12;
use LTE_OSS13;
use LTE_OSS14;
########################
# Vars
########################
local @helpinfo=qq(Usage : ${0} LTE node minimumcellsize
Example: $0 6

Meaning : the param minimumcellsize means that equal to or greater than the minimumcellsize 
          will only be written ex: a LTE node with a cell size of less than 6 will not be written);

local $dir=cwd;my $currentdir=$dir."/";
local $scriptpath="$currentdir";
#------------------------
# verify CONFIG.env file
#------------------------
local $CONFIG="CONFIG.env"; # script base CONFIG.env
$ENV=$CONFIG;
local $MINCELLSIZE; 
$MINCELLSIZE=$ARGV[0];
local $linepattern= "#" x 100;
local $inputfilesize,$arrelement,$element;
local $tempcounter,$inputfileposition=0;
local $startdate=`date`;
local $netsimserver=`hostname`;
local $username=`/usr/bin/whoami`;
$username=~s/^\s+//;$username=~s/\s+$//;
$netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
local $TEPDIR="/var/tmp/tep/";
local $NETWORKCONFIGDIR=$scriptpath;
$NETWORKCONFIGDIR=~s/bin.*/customdata\/pico\//;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
local $PICONETWORKCELLSIZE=&getENVfilevalue($ENV,"PICONETWORKCELLSIZE");

local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");

local $SIMSTART=&getENVfilevalue($ENV,"SIMSTART");
local $SIMEND=&getENVfilevalue($ENV,"SIMEND");
local $PICOSIMSTART=&getENVfilevalue($ENV,"PICOSIMSTART");
local $PICOSIMEND=&getENVfilevalue($ENV,"PICOSIMEND");
local $PICONUMOFRBS=&getENVfilevalue($ENV,"PICONUMOFRBS");

# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
local $NODECOUNT=1,$LTE,$PICOLTE;
local $match=0;
local ($cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype);
local $LTENetworkOutput="$NETWORKCONFIGDIR/LTE".$NETWORKCELLSIZE."PICO".$PICONETWORKCELLSIZE."networkcellrelations.csv";
local $nodecounter=1;
local @LTEnetworknodes=();
local @PICOnetworknodes=();
local $LTEnetworkcounter=0;
local $PICOnetworkcounter=0;
local $MAXPICONETWORKPERCENT=80;
local $MINPICONETWORKPERCENT=20;
local $PICOnodenetworkpercentage;
local $PICOnodenetworkstatus; # either MAX or MIN network dependent on $PICOnodenetworkpercentage
local $maxPICOnetworknodes=int(($PICONETWORKCELLSIZE/100)*$MAXPICONETWORKPERCENT);
local $TotalPICOrelatednodes;
local $TotalLTErelatednodes;
local @PICOLTEcellrelations=();
#########################
# verification
#########################
#-----------------------------------------
# ensure script being executed by netsim
#-----------------------------------------
if ($username ne "netsim"){
   print "FATAL ERROR : ${0} needs to be executed as user : netsim and NOT user : $username\n";exit(1);
}# end if
#-----------------------------------------
# ensure params are as expected
#-----------------------------------------
if (!( @ARGV==1)){
print "@helpinfo\n";exit(1);}

if (-e "$NETSIMMOSCRIPT"){
    unlink "$NETSIMMOSCRIPT";}
#-----------------------------------------
# ensure PICO2LTE cellrelations file created
#-----------------------------------------
open FH1, "> $LTENetworkOutput" or die $!;

#########################
# main
##########################
local $csvinputfileline;

print FH1 "$linepattern\n";
print FH1 "... ${0} started running at $startdate";
print FH1 "$linepattern\n";
print FH1 "# LTE14.1 PICO2LTE relations created as per PICO PO Anuj Sethi algorithm\n";
print FH1 "$linepattern\n\n";
#-----------------------------------
# start build PICO2LTE associations
#-----------------------------------
$ttlcellcounter=0;$LTE=0;
################################
# start get LTE network by cell 
################################
while($ttlcellcounter<=$NETWORKCELLSIZE){ # start outer while NETWORKCELLSIZE

 $NODECOUNT=1;$LTE++;

 while ($NODECOUNT<=$NUMOFRBS){ # start while NUMOFRBS
   # get node name
   $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
    
   # get the node eutran frequency id
   $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
   $NODESIM=&getLTESimNum($nodecountinteger,$NUMOFRBS);

   # nasty workaround for error in &getLTESimStringNodeName
   if($nodecountinteger>$NUMOFRBS){
     $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
   }# end if
   else{$nodecountfornodestringname=$nodecountinteger;}# end workaround

   # get node flexible primary cells
   @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
   $CELLNUM=@primarycells;

   # check node cell size does not exceed NETWORKCELLSIZE
   # CXP 903 0491-90-1, 24/09/2014
   # check cellnum increment does not become 0 valued
   if(($ttlcellcounter>=$NETWORKCELLSIZE)||($CELLNUM==0)){last;}

   ######################
   # start go thru cells
   ######################
   $CID=1;$TACID=1;$CELLCOUNT=1;
   foreach $Cell (@primarycells) {
    $Frequency = getCellFrequency($Cell, $ref_to_Cell_to_Freq);
    # check cell type
    if (&isCellFDD($ref_to_Cell_to_Freq, $Cell)) {
      $TYPE="EUtranCellFDD";
      $UL_Frequency = $Frequency + 18000;
    }# end if
    else{
      $TYPE="EUtranCellTDD";
    }# end else
   $CELLCOUNT++;$CID++;
   last;
   }# end foreach
   ####################
   # end go thru cells
   ####################

   # check that we are looking at relevant LTE node cellsizes
     if($CELLNUM<$MINCELLSIZE){
         $NODECOUNT++;
         $ttlcellcounter=$CELLNUM+$ttlcellcounter;
         next;
     }# end if

   # check that cells are only FDD as PICO does not support TDD associations
    if($TYPE=~m/EUtranCellTDD/){
      $NODECOUNT++;
      $ttlcellcounter=$CELLNUM+$ttlcellcounter;
      next;
    }# end if  

   $CELLCOUNT=1;

   # cycle thru the LTE network and get LTE nodes
   $LTEnetworknodes[$LTEnetworkcounter]="$LTENAME;$CELLNUM;$UL_Frequency";
   $LTEnetworkcounter++;

  $NODECOUNT++;
  $ttlcellcounter=$CELLNUM+$ttlcellcounter;

 }# end while NUMOFRBS

  # check node cell size does not exceed NETWORKCELLSIZE
      # CXP 903 0491-216-1
  if($ttlcellcounter>=$NETWORKCELLSIZE){last;}

}# end outer while NETWORKCELLSIZE
################################
# end get LTE network by cell 
################################
################################
# start get PICO network by cell
################################
$CELLCOUNT=1;
$ttlcellcounter=0;
$PICOLTE=$PICOSIMSTART;

while($ttlcellcounter<=$PICONETWORKCELLSIZE){ # start outer while PICONETWORKCELLSIZE

# check PICO node percentage position in the network
# either MAX (largest portion of the network) or MIN (smallest portion of the network)
if($maxPICOnetworknodes>$ttlcellcounter){
   $PICOnodenetworkpercentage=$MAXPICONETWORKPERCENT;
   $PICOnodenwtorkstatus="MAX";  
} 
else{$PICOnodenetworkpercentage=$MINPICONETWORKPERCENT;
     $PICOnodenwtorkstatus="MIN";} # end else

$NODECOUNT=1;

 while ($NODECOUNT<=$PICONUMOFRBS){ # start while PICONUMOFRBS

      # get node name
      $LTENAME=&getPICOSimStringNodeName($PICOLTE,$NODECOUNT);

      # get current node count number
      $nodecountinteger=&getPICOSimIntegerNodeNum($PICOSIMSTART,$PICOLTE,$NODECOUNT,$PICONUMOFRBS);

      # check node cell size does not exceed NETWORKCELLSIZE
      if($ttlcellcounter>$PICONETWORKCELLSIZE){last;}
 
      $PICOnetworknodes[$PICOnetworkcounter]="$PICOnodenwtorkstatus;$LTENAME-$CELLCOUNT";

      $NODECOUNT++;
      $ttlcellcounter++;$PICOnetworkcounter++;
 
 }# end while PICONUMOFRBS
 $PICOLTE++;
}# end outer while PICONETWORKCELLSIZE
################################
# end get PICO network by cell
################################

####################################
# start build PICO2LTE associations
####################################
# PICO2LTE node relation configuration table
# details CA PICO2LTE node relations of
# MAX % of the PICO network configuration
# laid out by columns seperated by a semicolon
# PICO network percentage;PICO relationsmodel;LTE nodenumber; LTE cellnumber

# CXP 903 0491-117-1 : For "w;x;y;z", change z to 3 when equal to 4.

# PICO Node 1,2,3 to LTE relations model
$PICOLTEcellrelations[0]="MAX;A;1;3";
$PICOLTEcellrelations[1]="MAX;A;2;3";
$PICOLTEcellrelations[2]="MAX;A;3;2";
$PICOLTEcellrelations[3]="MAX;A;4;1";
$PICOLTEcellrelations[4]="MAX;A;5;1";
$PICOLTEcellrelations[5]="MAX;A;6;1";
$PICOLTEcellrelations[6]="MAX;A;7;1";

# PICO Node 4,5,6 to LTE relations model
$PICOLTEcellrelations[7]="MAX;B;1;1";
$PICOLTEcellrelations[8]="MAX;B;2;3";
$PICOLTEcellrelations[9]="MAX;B;3;3";
$PICOLTEcellrelations[10]="MAX;B;4;2";
$PICOLTEcellrelations[11]="MAX;B;5;1";
$PICOLTEcellrelations[12]="MAX;B;6;1";
$PICOLTEcellrelations[13]="MAX;B;7;1";

# PICO Node 7,8 to LTE relations model
$PICOLTEcellrelations[14]="MAX;C;1;2";
$PICOLTEcellrelations[15]="MAX;C;2;2";
$PICOLTEcellrelations[16]="MAX;C;3;2";
$PICOLTEcellrelations[17]="MAX;C;4;2";
$PICOLTEcellrelations[18]="MAX;C;5;2";
$PICOLTEcellrelations[19]="MAX;C;6;1";
$PICOLTEcellrelations[20]="MAX;C;7;1";

# PICO2LTE node relation configuration table
# details CA PICO2LTE node relations of
# MIN % of the PICO network configuration
# laid out by columns seperated by a semicolon
# PICO network percentage;PICO relationsmodel;LTE nodenumber; LTE cellnumber

# PICO Node 1,2,3,4 to LTE relations model
$PICOLTEcellrelations[21]="MIN;A;1;3";
$PICOLTEcellrelations[22]="MIN;A;2;3";
$PICOLTEcellrelations[23]="MIN;A;3;3";
$PICOLTEcellrelations[24]="MIN;A;4;3";
$PICOLTEcellrelations[25]="MIN;A;5;3";
$PICOLTEcellrelations[26]="MIN;A;6;3";
$PICOLTEcellrelations[27]="MIN;A;7;3";
$PICOLTEcellrelations[28]="MIN;A;8;3";
$PICOLTEcellrelations[29]="MIN;A;9;3";
$PICOLTEcellrelations[30]="MIN;A;10;3";
$PICOLTEcellrelations[31]="MIN;A;11;3";
$PICOLTEcellrelations[32]="MIN;A;12;2";
$PICOLTEcellrelations[33]="MIN;A;13;2";
$PICOLTEcellrelations[34]="MIN;A;14;2";

# PICO Node 5,6,7,8 to LTE relations model
$PICOLTEcellrelations[35]="MIN;B;1;2";
$PICOLTEcellrelations[36]="MIN;B;2;3";
$PICOLTEcellrelations[37]="MIN;B;3;3";
$PICOLTEcellrelations[38]="MIN;B;4;3";
$PICOLTEcellrelations[39]="MIN;B;5;3";
$PICOLTEcellrelations[40]="MIN;B;6;3";
$PICOLTEcellrelations[41]="MIN;B;7;3";
$PICOLTEcellrelations[42]="MIN;B;8;3";
$PICOLTEcellrelations[43]="MIN;B;9;3";
$PICOLTEcellrelations[44]="MIN;B;10;3";
$PICOLTEcellrelations[45]="MIN;B;11;3";
$PICOLTEcellrelations[46]="MIN;B;12;3";
$PICOLTEcellrelations[47]="MIN;B;13;2";
$PICOLTEcellrelations[48]="MIN;B;14;2";

# PICO Node 9,10 to LTE relations model
$PICOLTEcellrelations[49]="MIN;C;1;3";
$PICOLTEcellrelations[50]="MIN;C;2;2";
$PICOLTEcellrelations[51]="MIN;C;3;2";
$PICOLTEcellrelations[52]="MIN;C;4;3";
$PICOLTEcellrelations[53]="MIN;C;5;3";
$PICOLTEcellrelations[54]="MIN;C;6;3";
$PICOLTEcellrelations[55]="MIN;C;7;3";
$PICOLTEcellrelations[56]="MIN;C;8;3";
$PICOLTEcellrelations[57]="MIN;C;9;3";
$PICOLTEcellrelations[58]="MIN;C;10;3";
$PICOLTEcellrelations[59]="MIN;C;11;3";
$PICOLTEcellrelations[60]="MIN;C;12;3";
$PICOLTEcellrelations[61]="MIN;C;13;3";
$PICOLTEcellrelations[62]="MIN;C;14;3";

#---------------------------------------
# cycle thru the PICO nodes
#---------------------------------------
local ($element,$element2,$piconodename);
local $currPICOnodearrayposition=0;
local $currLTEnodearrayposition=0;
local $currPICOnodeboundary=1;
local $currLTEnodeboundary=1;
local $currPICOLTEcellrelationspointer=0;
local ($status,$picorelationalmodel,$ltenodenum,$ltenodecellnum);
local @LTEnodeworkingdataset=();
local $LTEnodeworkingdatasetcounter=0;
local $LTEnodeworkingdatasetcounter2=0;
local $templtecellnum=0;
local $templtenodecellnum;
local ($tltenodename,$tltecellnum);

# cycle thru PICO node network
foreach $element(@PICOnetworknodes){
                ($PICOnodenetworkstatus,$piconodename)=split(/\;/,$element);

                # set up PICO2LTE table node limits based on PICO network node position
                if($PICOnodenetworkstatus eq "MAX"){
                  $TotalPICOrelatednodes=8;
                  $TotalLTErelatednodes=7;

                  # determine $PICOLTEcellrelations starting array position
                  if($currPICOnodeboundary>0 && $currPICOnodeboundary<4){
                     $currPICOLTEcellrelationspointer=0;
                  }# end if
                  if($currPICOnodeboundary>3 && $currPICOnodeboundary<7){
                     $currPICOLTEcellrelationspointer=7;
                  }# end if
                   if($currPICOnodeboundary>6 && $currPICOnodeboundary<9){
                     $currPICOLTEcellrelationspointer=14;
                  }# end if
                  
                }# end outer if

                else{ # MIN part of the PICO network
                  $TotalPICOrelatednodes=10;
                  $TotalLTErelatednodes=14;

                  # determine $PICOLTEcellrelations starting array position
                  if($currPICOnodeboundary>0 && $currPICOnodeboundary<5){
                     $currPICOLTEcellrelationspointer=21;
                  }# end if
                  if($currPICOnodeboundary>4 && $currPICOnodeboundary<9){
                     $currPICOLTEcellrelationspointer=35;
                  }# end if
                   if($currPICOnodeboundary>8 && $currPICOnodeboundary<11){
                     $currPICOLTEcellrelationspointer=49;
                  }# end if
                }# end else

               #####################################################
               # start build PICO2LTE node relations working dataset
               #####################################################
               if($currPICOnodeboundary==1){
                  @LTEnodeworkingdataset=();
                  $LTEnodeworkingdatasetcounter=0;

                  while ($LTEnodeworkingdatasetcounter<$TotalLTErelatednodes){
                     $LTEnodeworkingdataset[$LTEnodeworkingdatasetcounter]=$LTEnetworknodes[$currLTEnodearrayposition];
                     
                     # check for blank LTE node name
                     if(!($LTEnodeworkingdataset[$LTEnodeworkingdatasetcounter]=~/LTE/)){
                        $LTEnodeworkingdataset[$LTEnodeworkingdatasetcounter]="BLANK";
                     }# end if                    

                     $currLTEnodearrayposition++;
                     $LTEnodeworkingdatasetcounter++; 
                  }# end inner while

               }# end if
               ####################################################
               # end build PICO2LTE node relations working dataset
               ####################################################

              #####################################################
              # start write PICO2LTE node relations
              #####################################################
              $LTEnodeworkingdatasetcounter2=0;
             
              while ($LTEnodeworkingdatasetcounter2<$TotalLTErelatednodes){
                     # PICO network percentage;PICO relationsmodel;LTE nodenumber; LTE cellnumber
                     ($status,$picorelationalmodel,$ltenodenum,$ltenodecellnum)=split(/\;/,$PICOLTEcellrelations[$currPICOLTEcellrelationspointer]);                    
     
                     # create unique $ltenodenum $ltecellnum
                     $templtenodenum=$ltenodenum;
                     $templtenodenum=$templtenodenum-1; # allow for array index
                     $templtenodecellnum=1;
             ($tltenodename,$tltecellnum,$UL_Frequency)=split(/\;/,$LTEnodeworkingdataset[$templtenodenum]);
                     # write PICO2LTE relations 
                     while ($templtenodecellnum<=$ltenodecellnum){
                            print FH1 "$piconodename;$tltenodename-$templtenodecellnum;$UL_Frequency\n";
                            $templtenodecellnum++;
                     }# end inner while

                     $currPICOLTEcellrelationspointer++;
                     $LTEnodeworkingdatasetcounter2++;  
              }# end while

             #####################################################
             # end write PICO2LTE node relations
             #####################################################
  
              $currPICOnodeboundary++;

              # reset PICO table relations counter
              if($currPICOnodeboundary>$TotalPICOrelatednodes){
                  $currPICOnodeboundary=1;
              }# end if
}# end foreach @PICOnetworknodes
####################################
# end build PICO2LTE associations
####################################
#----------------------------------
# end build PICO2LTE associations
#----------------------------------
#########################
# cleanup
#########################
$date=`date`;
print FH1 "$linepattern\n";
print FH1 "... ${0} ended running at $date";
print FH1 "$linepattern\n";
close(FH1);
#########################
# EOS
#########################
