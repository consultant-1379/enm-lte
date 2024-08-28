#!/usr/bin/perl
  ### VERSION HISTORY
  ######################################################################################
  #
  #     Author : LTE Agile team (epatdal)
  #
  #     Description : Irathom enabled functionality (OSS 13B 0.7 Sprint) to create
  #                   LTE to WRAN relations based on real UtranCell data as supplied
  #                   by the simulated WRAN network deployment team.
  #                   builds and outputs files :
  #                    ~/customdata/irathom/PublicIrathomLTE2WRAN.csv
  #                     - this file is transferred from the LTE to the WRAN
  #                       team and is used by WRAN to build WRAN to LTE network
  #                       to enable IRATHOM
  #
  #                    ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv
  #                     - this file is used to build the LTE utran network
  #                       and is used as input to the LTE script base utran scripts
  #                       1276createUtranFreqRelation.pl
  #                       1277createUtranCellRelations.pl
  #                       1278setUtranCellRelations.pl
  #                       2133structsetEUtranGeranUtranRelations.pl
  #
  #                    The data items below are read from the below CONFIG.env
  #                    ~/dat/CONFIG.env
  #                      IRATHOMENABLED=YES
  #                      IRATHOMTTLUTRANCELLS=10000
  #                      IRATHOMWRAN2LTEFILENAME=UtranData13B_For_LTE.csv
  #
  #                    This script follows the procedure
  #                      1. IRATHOMENABLED variable is read from the CONFIG.env
  #                         by a LTE script base utran script
  #                      2. if IRATHOMENABLED=NO continue as normal
  #                      3. if IRATHOMENABLED=YES then execute script ./createLTE2WRANrelations.pl
  #                         and create files PrivateIrathomLTE2WRAN.csv and PublicIrathomLTE2WRAN.csv
  #                      4. pass the PublicIrathomLTE2WRAN.csv to the WRAN network team as required
  #                      5. 1273createUtranFrequency.pl executes only once ./createLTE2WRANrelations.pl
  #                         and outputs two files PublicIrathomLTE2WRAN.csv for the WRAN team
  #                         and PrivateIrathomLTE2WRAN.csv to be used by 1273createUtranFrequency.pl
  #                         to get Irathom enabled online external Utran cell data to be used in the
  #                         LTE network as opposed to simulated external utran cell dat
  #                      6. PrivateIrathomLTE2WRAN.csv contains the following format
  #                         Plmnidentity=MCC=46;MNC=6;MNCLENGTH=2
  #
  #         ROWID=1;EUtranCellFDD=LTE01ERBS00001-1;UTRANFREQREL=1;UTRANFREQ=1;EXTUCFDDID=RNC01-1-1;MUCID=RNC01-1-1;USERLABEL=RNC01-1-1;LAC=1;PCID=1;CID=1;RAC=1;ARFCNVDL=1;EARFCNDL=1;RNCID=1;UARFCNUL=12
  #
  #
  #     Dependencies : WRANtoLTE input file as supplied by the WRAN network deployment team
  #                    eg. UtranData13B_For_LTE.csv
  #
  #     Syntax : ./createLTE2WRANrelations.pl
  #
  #     Date : May 2014
  ######################################################################################
  ######################################################################################
  # Verion2     : LTE 14B.1
  # Purpose     : updated support for LTE2WRAN for IRATHOM
  #               to include new 10K UtranData14B_For_LTE.csv file
  #               and extra values RNCID and UARFCNUL
  # Description : implement LTE2WRAN for IRATHOM
  # User Story  : NETSUP-1672
  # SNID        : LMI-14:001028
  # Date        : Juy 2014
  # Who         : epatdal
  #######################################################################################
  ####################################################################
  # Version3    : LTE 15B
  # Revision    : CXP 903 0491-135-1
  # Purpose     : resolves an issue where TDD cells are represented
  #               incorrectly as FDD cells in EUtran master and
  #               proxy cells
  # Jira        : NETSUP-2748
  # Description : ensure TDD and FDD cells are not represented
  #               incorrectly
  # Date        : Mar 2015
  # Who         : epatdal
  ####################################################################
  ####################################################################
  # Version4    : LTE 17A
  # Revision    : CXP 903 0491-249-1
  # Purpose     : Increase the number of UtranCellRelations
  # Jira        : NSS-2160
  # Description : Setting UtranCellRelations to 6 per UtranFreqRelation
  # Date        : Aug 2016
  # Who         : xkatmri
  ####################################################################
  ####################################################################
# Version4    : ENM 19.15
# Revision    : CXP 903 0491-367-1
# Jira        : NSS-32034
# Purpose     : 80K LTE 35K Design for Utran relations
# Description : Design change to meet specific counts mentioned in 
#               above JIRA.       
# Date        : Sep 2017
# Who         : xmitsin
####################################################################
  ########################
  #  Environment
  ########################
  use FindBin qw($Bin);
  use lib "$Bin/../../lib/cellconfig";
  use Cwd;
  use LTE_CellConfiguration;
  use LTE_General;
  use LTE_Relations;
  use LTE_OSS12;
  use LTE_OSS13;
  ########################
  # Vars
  ########################
  local $dir=cwd;my $currentdir=$dir."/";
  local $scriptpath="$currentdir";
  #------------------------
  # verify CONFIG.env file
  #------------------------
  local $CONFIG="CONFIG.env"; # script base CONFIG.env
  $ENV=$CONFIG;
  local $linepattern= "#" x 100;
  local $inputfilesize,$arrelement;
  local $startdate=`date`;
  local $netsimserver=`hostname`;
  local $username=`/usr/bin/whoami`;
  $username=~s/^\s+//;$username=~s/\s+$//;
  $netsimserver=~s/^\s+//;$netsimserver=~s/\s+$//;
  local $TEPDIR="/var/tmp/tep/";
  local $IRATHOMDIR=$scriptpath;
  $IRATHOMDIR=~s/bin.*/customdata\/irathom\//;

  local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
  local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
  local $NUMOF_FDDNODES=&getENVfilevalue($env,"NUMOF_FDDNODES");
  # get cell configuration ex: 6,3,3,1 etc.....
  local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
  local @CELLPATTERN=split(/\,/,$CELLPATTERN);
  local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
  local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
  local $FREQCOUNT,$TOTALFREQCOUNT=6;
  local $NODECOUNT=1,$LTE;
  local $CELLCOUNT,$EUTRANCELLCOUNT;
  local $DownlinkFrequency;
  local $match=0;
  #-------------------------------------------
  # Irathom Vars
  # $IrathomInputFile : csv file as supplied
  # containing WRAN network Utrancell data
  #
  # $IrathomOutputFile : csv file as supplied
  # containing LTE freq data
  #
  # $IrathomRelationFile : used in building
  # Irathom Utrancell data in LTE network
  #------------------------------------------
  local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMWRAN2LTEFILENAME");
  $IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";
  local $IrathomOutputFile="$IRATHOMDIR/PublicIrathomLTE2WRAN.csv";
  local $IrathomRelationFile="$IRATHOMDIR/PrivateIrathomLTE2WRAN.csv";
  local $IRATHOMTTLUTRANCELLS=&getENVfilevalue($ENV,"IRATHOMTTLUTRANCELLS");
  local $IRATHOMENABLED=&getENVfilevalue($ENV,"IRATHOMENABLED");
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
  # ensure $IrathomInputFile in place
  #-----------------------------------------
  if (!(-e "$IrathomInputFile")){
       print "FATAL ERROR : $IrathomInputFile does not exist\n";exit;
  }# end if

  # open csv WRAN to LTE relations input file for reading
  local @IRATHOMWRAN2LTEFILENAME=();
  open FH, "$IrathomInputFile" or die $!;
       @IRATHOMWRAN2LTEFILENAME=<FH>;
  close(FH);

  $inputfilesize=@IRATHOMWRAN2LTEFILENAME;

  if($inputfilesize<$IRATHOMTTLUTRANCELLS){
      print "FATAL ERROR : in file $IrathomInputFile\n";
      print "FATAL ERROR : file row size $inputfilesize is less than the required total Utrancell size of $IRATHOMTTLUTRANCELLS\n";
  }# end if

  # open private csv output LTE to WRAN relations file for writing
  open FH2, "> $IrathomRelationFile" or die $!;

  # open public csv output LTE to WRAN relations file for writing
  # this file is transferred to WRAN for their network build
  open FH3, "> $IrathomOutputFile" or die $!;

  #########################
  # main
  ##########################
  local $IrathomInputFileDate,$plmnIdentity;
  local ($rowid,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$rncid,$uarfcnul);
  local $csvinputfileline;
  local ($mcc,$mnc,$mncLength);
  local $tempcounter=0,$startrowidfilepos;
  local $ttlcellcounter=0;

  foreach $element(@IRATHOMWRAN2LTEFILENAME){
                  if($element=~/script ended/){# WRAN to LTE input file date
                      $IrathomInputFileDate=&getIRATHOMcsvfiledate($element);
                  }# end if

                  if($element=~/MCC=/){# WRAN to LTE input file plmnIdentity
                      $plmnIdentity=&getIRATHOMcsvfilerawvalue($element);
                  }# end if
  }# end foreach

  foreach $element(@IRATHOMWRAN2LTEFILENAME){

                  if($element=~/ROWID=1/){# WRAN to LTE input file ROWID=1 array position
                     $startrowidfilepos=$tempcounter;
                     last;
                  }# end if

                  $tempcounter++;
  }# end foreach

  ($mcc,$mnc,$mncLength)=split(/;/,$plmnIdentity);

  # write to file ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv
  print FH2 "$linepattern\n";
  print FH2 "... ${0} started running at $startdate";
  print FH2 "$linepattern\n";
  print FH2 "# This file is generated from the WRAN to LTE Input File\n";
  print FH2 "# Location is $IrathomInputFile\n";
  print FH2 "# Input File generation date is $IrathomInputFileDate\n";
  print FH2 "$linepattern\n\n";
  print FH2 "plmnIdentity=MCC=$mcc;MNC=$mnc;MNCLENGTH=$mncLength\n\n";
  $date=`date`;

  # write to file ~/customdata/irathom/PublicIrathomLTE2WRAN.csv
  print FH3 "$linepattern\n";
  print FH3 "... ${0} started running at $date";
  print FH3 "$linepattern\n";
  print FH3 "# This file is generated from the LTE Input File\n";
  print FH3 "# Location is $IrathomRelationFile\n";
  print FH3 "# Input File generation date is $startdate";
  print FH3 "$linepattern\n\n";
  #--------------------------------
  # start build ttl utan cell data
  #--------------------------------
  $ttlcellcounter=0;$LTE=1;$rowid=1;

  while ($rowid<$IRATHOMTTLUTRANCELLS){# start while file ROWID value

   $NODECOUNT=1;

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

     # check cell type
     # checking one cell on the node in this instance and then assuming all other cells are the same
     # this is a good assumption but would have been future proof to do per cell
     # SJ NETSUP-2748 - CXP 903 0491-135-1
     if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))){
        $TYPE="EUtranCellFDD";
     }# end if
     else{
       $TYPE="EUtranCellTDD";
     }# end else

     # central downlink frequency attribute earfcndl on cell
     foreach $Cell (@primarycells) {# start foreach primarycells
           $DownlinkFrequency=&getCellFrequency($Cell,$ref_to_Cell_to_Freq);
           # frequency the same for all ERBS node cells
           last;
     }# end foreach primarycells

     $CELLCOUNT=1;
     while($CELLCOUNT<=$CELLNUM){ # start while EUTRAN CELLNUM

       # Utran freq count
       $FREQCOUNT=1;
       while ($FREQCOUNT<=$TOTALFREQCOUNT){# start while $TOTALFREQCOUNT

          $csvinputfileline=&getIRATHOMcsvfilerawvalue($IRATHOMWRAN2LTEFILENAME[$startrowidfilepos]);
          if($rowid>=$IRATHOMTTLUTRANCELLS){last;}# exceeded IRATHOMTTLUTRANCELLS
          $startrowidfilepos++;
          ($rowid,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$rncid,$uarfcnul)=split(/;/,$csvinputfileline);
          #----------------------------------------------------
          # start check for non ROWID data from WRAN input file
          #----------------------------------------------------
          if(($rowid =~m/ /)||($rowid =~m/\#/)){$match=1;};
          while ($match==1){# start while match
                $startrowidfilepos++;
                $csvinputfileline=&getIRATHOMcsvfilerawvalue($IRATHOMWRAN2LTEFILENAME[$startrowidfilepos]);
                ($rowid,$extucFDDid,$mucid,$userlabel,$lac,$pcid,$cid,$rac,$arfcnvdl,$rncid,$uarfcnul)=split(/;/,$csvinputfileline);
                 if(($rowid =~m/ /)||($rowid =~m/\#/)){$match=1;}
                   else {$match=0;}
          }# end while match
          $ttlcellcounter++;
          #--------------------------------------------------
          # end check for non ROWID data from WRAN input file
          #--------------------------------------------------
          #----------------------------------------------------
          # start write out csv data files
          #----------------------------------------------------
          # write to file ~/customdata/irathom/PrivateIrathomLTE2WRAN.csv

          $FREQCOUNTER=$FREQCOUNT;
          $TOTALUTRANFREQREL=($TOTALFREQCOUNT*$CELLNUM);
          while ($FREQCOUNTER<=$TOTALUTRANFREQREL) {
          print FH2 "ROWID=$rowid;$TYPE=$LTENAME-$CELLCOUNT;UTRANFREQREL=$FREQCOUNTER;UTRANFREQ=$arfcnvdl;EXTUCFDDID=$extucFDDid;MUCID=$mucid;USERLABEL=$userlabel;LAC=$lac;PCID=$pcid;CID=$cid;RAC=$rac;ARFCNVDL=$arfcnvdl;EARFCNDL=$DownlinkFrequency;RNCID=$rncid;UARFCNUL=$uarfcnul\n";
         
          $FREQCOUNTER=($FREQCOUNTER+6);
          }
          # write to file ~/customdata/irathom/PublicIrathomLTE2WRAN.csv
          # print FH3 "ROWID=$rowid;$TYPE=$LTENAME-$CELLCOUNT;DOWNLINKFREQ=$DownlinkFrequency;WRANROWIDRELATION=$rowid\n";
          # print FH3 "WRROWID=$rowid;EXTEURANFREQID=$LTENAME-$CELLCOUNT;EARFCNDL=$DownlinkFrequency\n";
          # change requested by Fatih Onur 5/3/13
          print FH3 "WRROWID=$rowid;EUTRANFREQRELATIONID=$DownlinkFrequency;EARFCNDL=$DownlinkFrequency\n";
          #----------------------------------------------------
          # end write out csv data files
          #----------------------------------------------------

          $FREQCOUNT++;

       }# end while FREQCOUNT

       $CELLCOUNT++;
     }# end while CELLNUM

    $NODECOUNT++;
   }# end while NUMOFRBS

   $LTE++;
  }# end outer while file ROWID value
  #--------------------------------
  # end build ttl utan cell data
  #--------------------------------
  #########################
  # cleanup
  #########################
  $date=`date`;
  print FH2 "$linepattern\n";
  print FH2 "... ${0} ended running at $date";
  print FH2 "$linepattern\n";
  close(FH2);

  print FH3 "$linepattern\n";
  print FH3 "... ${0} ended running at $date";
  print FH3 "$linepattern\n";
  close(FH3);
  #########################
  # EOS
  #########################

