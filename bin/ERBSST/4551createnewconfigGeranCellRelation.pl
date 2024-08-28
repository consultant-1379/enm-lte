#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-152-1
# Jira        : OSS-77886
# Purpose     : Support to establish DG2toGSM handover for new GSM
#               configuration
# Comment     : updated to enable DG2toGSM configuration
# Date        : May 2015
# Who         : xkamvat
####################################################################
####################################################################
# Version2    : LTE16A
# Revision    : CXP 903 0491-156-1
# User Story  : NETSUP-3065
# Purpose     : To sync DG2 Nodes on OSS
# Description : setting attributes geranFreqGroupRelationId
# Date        : June 2015
# Who         : xsrilek
####################################################################
####################################################################
# Version3    : LTE 17A
# Revision    : CXP 903 0491-264-1
# Jira        : NSS-5736
# Purpose     : Increase the number of GeranFrequency per cell
# Description : To increase GeranFrequency
# Date        : Sep 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : Create a topology file from build scripts
# Description : Opening a file to store the MOs created during the
#               running of the script
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version5    : LTE 18B
# Revision    : CXP 903 0491-322-1
# Jira        : NSS-16469
# Purpose     : Increase the number of GeranFrequency per cell
# Description : To increase GeranFrequency
# Date        : Dec 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version6    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               GeranCellRelation MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version7    : LTE 19.15
# Revision    : CXP 903 0491-365-1
# Jira        : NSS-32241
# Purpose     : NRM6.2 80K LTE 35K Design for Geran relations
# Description : Design change to meet specific counts mentioned in
#               above JIRA.
# Date        : Sep 2020
# Who         : xmitsin
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
 use LTE_OSS14;
 use LTE_Relations;
 use LTE_OSS15;
 ####################
 # Vars
 ####################
 local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$DG2=$ARGV[2];
 #---------------------------------------------------------------
 # start verify params and sim node type
 local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
 Example:  $0 LTE17A-V10x10-5K-DG2-FDD-LTE01 CONFIG.env 1);
 if (!( @ARGV==3)){
    print "@helpinfo\n";exit(1);}
 # check if SIMNAME is of type PICO or DG2
 if(&isSimDG2($SIMNAME)=~m/NO/){exit;}
 # end verify params and sim node type
 #---------------------------------------------------------------
 local $date=`date`,$LTENAME;
 local $dir=cwd,$currentdir=$dir."/";
 local $scriptpath="$currentdir";
 local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
# for storing data to create topology file
 local $topologyDirPath=$scriptpath;
 $topologyDirPath=~s/bin.*/customdata\/topology\//;
 local $MOSCRIPT="$scriptpath".${0}.".mo";
 local $MMLSCRIPT="$scriptpath".${0}.".mml";
 local @MOCmds,@MMLCmds,@netsim_output;
 local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
 local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
 local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
 local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
 local $DG2NUMOFRBS=&getENVfilevalue($ENV,"DG2NUMOFRBS");
 local $MIMVERSION=$SIMNAME;$MIMVERSION=~s/-.*//g;$MIMVERSION=~s/LTE//;
 local $nodecountinteger;
 local $arrayelement,$line_count;
 local $freqgroup;
 local $ttlnodegerancellrelations;
 
 # get cell configuration ex: 6,3,3,1 etc.....
 local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
 local @CELLPATTERN=split(/\,/,$CELLPATTERN);
 local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);
 local $ref_to_Cell_to_Freq = &buildNodeFrequencies(\@PRIMARY_NODECELLS);
 local @primarycells;
 local $lastGSMcellname;
 
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Frequency group distribution
 # 124 geranfrequencies across 16 groups
 # groups 1 - 15 has 30 frequencies
 # group 16 has 50 frequencies
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 local $maxGeranFreqGrp=16;
 local $freqtillGrp15=30;### 18/Cell NRM6.2
 local $freqforGrp16=50;
 
 # Irathom data
 local $IRATHOMDIR=$scriptpath;
 $IRATHOMDIR=~s/bin.*/customdata\/irathom\//;
 local ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup,$multiplefreqgroup);
 local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMGSMLTEFILENAME");
 $IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";
 local $IrathomRelationFile="$IRATHOMDIR/PrivateNewConfigIrathomLTE2GRAN.csv";
 local $IRATHOMGSMTTLCELLS=&getENVfilevalue($ENV,"IRATHOMGSMTTLCELLS");
 local $DG2SIMSTART=&getENVfilevalue($ENV,"DG2SIMSTART");
 local $IRATHOMGSMENABLED=&getENVfilevalue($ENV,"IRATHOMGSMENABLED");
 local $IRATHOMGSMREUSELEGACYCUSTOMDATA=&getENVfilevalue($ENV,"IRATHOMGSMREUSELEGACYCUSTOMDATA");
 local $nodecountfornodestringname;
 local $IrathomDataNewlyCreated=0;
 local $command1="createnewconfigLTE2GRANnetworkdata.pl";
 local @IRATHOMGRANDATA=();
 local $startIrathomGSMdatapospointer=7;# first value on 20K GSM attributes file
 local $IrathomGSMdatapospointer=7;
 local $copyIrathomGSMdatapospointer=7;
 local $IrathomGSMdatapospointer_counter=7;
 local $IrathomGSMdatainmemory=0;
 local $creategeranfrequency;
 local $arraycounter=0;
 local $cellrelationid=0;
 local @uniquefreqgroups=();
 local @nonuniquefreqgroups=();
 local $nonuniquefreqgroupscounter=0;
 local $e1="";
 
 ####################
 # Integrity Check
 ####################
 
 if (-e "$NETSIMMOSCRIPT"){
     unlink "$NETSIMMOSCRIPT";}
#####################
#Open file
#####################
local $filename = "$topologyDirPath/GeranCellRelation.txt";
open(local $fh, '>', $filename) or die "Could not open file '$filename' $!";        
 ################################
 # MAIN
 ################################
 print "... ${0} started running at $date\n";
 
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # start : NODECOUNT while
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 while ($NODECOUNT<=$DG2NUMOFRBS){
     
     # get node name
     $LTENAME=&getLTESimStringNodeName($DG2,$NODECOUNT);
     $nodecountinteger=&getLTESimIntegerNodeNum($DG2,$NODECOUNT,$DG2NUMOFRBS);
 
     # nasty workaround for error in &getLTESimStringNodeName
     if($nodecountinteger>$DG2NUMOFRBS){
        $nodecountfornodestringname=(($DG2-1)*$DG2NUMOFRBS)+$NODECOUNT;
     }# end if
     else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
 
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # flexible CELLNUM allocation
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
    $CELLNUM=@primarycells;
   
  
 
    # check cell type
    # SJ NETSUP-2748 - CXP 903 0491-135-1
    if((&isCellFDD($ref_to_Cell_to_Freq, $primarycells[0])) && (!(&isSimflaggedasTDDinCONFIG($ENV,"TDDSIMS",$LTE)))) {
        $TYPE="EUtranCellFDD";
    }# end if
    else{
        $TYPE="EUtranCellTDD";
    }# end else
    
    @MOCmds=();
    $CELLCOUNT=1;
    $IrathomGSMdatapospointer=$startIrathomGSMdatapospointer;
    $IrathomGSMdatapospointer_counter=$startIrathomGSMdatapospointer;
    $copyIrathomGSMdatapospointer=$startIrathomGSMdatapospointer;

	
    while ($CELLCOUNT<=$CELLNUM){# start cellcount
	
         $ttlnodegerancellrelations=$freqtillGrp15; ##30
    
         #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         # start : check for Irathom
         #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    $IrathomGSMdatainmemory=0;
 
    if((uc($IRATHOMGSMENABLED eq "YES"))&&($IrathomGSMdatainmemory==0)){
 
      if((uc($IRATHOMGSMREUSELEGACYCUSTOMDATA eq "NO"))&&($IrathomDataNewlyCreated==0)){
        print "Executing $command1 to create Irathom enabled GSM network data\n";
        $retval=system("$command1 >/dev/null 2>&1");
           if($retval!=0){
                print "FATAL ERROR : unable to create $IrathomRelationFile\n";
                $retval=0;
                exit;
           }# end inner if
        $IrathomDataNewlyCreated=1;
      }# end if

 
      if((uc($IRATHOMGSMREUSELEGACYCUSTOMDATA eq "YES"))){
         print "Re-reading GSM data in already created $IrathomRelationFile\n";
      }# end if
 
      open FH10, "$IrathomRelationFile" or die $!;
                @IRATHOMGRANDATA=<FH10>;
                $IrathomGSMdatainmemory=1;
      close(FH10);
 
     # find the array position of the lte cell in GSM data detail
     
     $line_count = `wc -l < $IrathomRelationFile`;
	 ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$IRATHOMGSMTTLCELLS+$startIrathomGSMdatapospointer-1]);
     $lastGSMcellname=$cellname;
 
     for( $arrayelement=1;$arrayelement<=$line_count;$arrayelement++ ){
             ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$arrayelement]);
              $IrathomGSMdatapospointer=$arrayelement;
              if("$ltenodename" eq "$LTENAME-$CELLCOUNT"){last;}
              $IrathomGSMdatapospointer++;
     }# end for
    }# end if IRATHOMGSMTTLCELLS
 
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # end : check for Irathom
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # start : get frequency group
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   $nonuniquefreqgroupscounter=0;
   @nonuniquefreqgroups=();
   @uniquefreqgroups=();
 
   $arraycounter=1;
   $ttlnodegerancellrelations=4; #NRM6.2
   $IrathomGSMdatapospointer_counter=$IrathomGSMdatapospointer;
   $copyIrathomGSMdatapospointer=$IrathomGSMdatapospointer_counter;
   
   while ($arraycounter<=$ttlnodegerancellrelations){# start while $ttlnodegerancellrelations
      ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$IrathomGSMdatapospointer_counter]);
	   
       $freqgroup=~s/\n//;
 
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       # ensure frequency group distribution is as expected
       # 124 geranfrequencies across 16 groups
       # groups 1 - 15 has 30 frequencies
       # group 16 has 50 frequencies
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     # if($freqgroup==$maxGeranFreqGrp){
     #       $ttlnodegerancellrelations=$freqforGrp16;
     #   }# end if
     #   if($freqgroup<$maxGeranFreqGrp){
     #       $ttlnodegerancellrelations=$freqtillGrp15;
     #   }# end if
 
       $nonuniquefreqgroups[$nonuniquefreqgroupscounter]=$freqgroup;
       $nonuniquefreqgroupscounter++;
 
       $arraycounter++;
       $IrathomGSMdatapospointer_counter++;
 
       if($cellname eq $lastGSMcellname){last;}#end loop if maximum gsm cells to be related is achieved
 
   }# end while $ttlnodegerancellrelations
 
   @uniquefreqgroups = uniq @nonuniquefreqgroups;
   #$size=@nonuniquefreqgroups;
 
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # end : get frequency group
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
       print "Creating frequencygrouprelation for $TYPE=$LTENAME-$CELLCOUNT\n";
 
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       # start : create GeranFreqGroupRelation
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       $size=@uniquefreqgroups;
	   $e1=$uniquefreqgroups[0];
       #foreach $e1(@uniquefreqgroups){# cycle thru unique freq groups
	   $GFGRarraycounter=1;
       $arraycounter=1;
       $IrathomGSMdatapospointer_counter=$IrathomGSMdatapospointer;
       $copyIrathomGSMdatapospointer=$IrathomGSMdatapospointer_counter;
       $ttlnodegeranFreqGrprelations=4;
    while ($GFGRarraycounter<=$ttlnodegeranFreqGrprelations){# start while $ttlnodegerancellrelations
			($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$IrathomGSMdatapospointer_counter]);
              @MOCmds=qq^ CREATE
              (
              parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT"
              identity "$bccno"
              moType Lrat:GeranFreqGroupRelation
              exception none
              nrOfAttributes 10
               "geranFreqGroupRelationId" String "$bccno"
               "allowedPlmnList" Array Struct 0
               "cellReselectionPriority" Int32 1
               "geranFreqGroupRef" Ref "null"
               "nccPermitted" String "11111111"
               "pMaxGeran" Int32 1000
               "qRxLevMin" Int32 -115
               "threshXHigh" Int32 4
               "threshXLow" Int32 0
               "userLabel" String "Irathom Enabled"
               "geranFreqGroupRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$e1"
               allowedPlmnList Array Struct 1
               nrOfElements 3
               mcc Int32 353
               mnc Int32 57
               mncLength Int32 2
              )
              ^;# end @MO
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
 #     }# end foreach cycle thru unique freq groups
 
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # end : create GeranFreqGroupRelation
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # start : create GeranCellRelation
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
            $arraycounter2=1;
            $cellrelationid=1;
            $ttlnodegerancellrelations2=9; # NRM6.2 - 9 GeranCellRelation/GeranFreqGroupRelation
            while ($arraycounter2<=$ttlnodegerancellrelations2){# start while $ttlnodegerancellrelations
 
             # ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno_temp,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$copyIrathomGSMdatapospointer]);
               
              $freqgroup=~s/\n//; 
              
              @MOCmds=qq^ CREATE
                 (
                 parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:$TYPE=$LTENAME-$CELLCOUNT,Lrat:GeranFreqGroupRelation=$bccno"
                 identity "$cellrelationid"
                 moType Lrat:GeranCellRelation
                 exception none
                 nrOfAttributes 4
                 "geranCellRelationId" String "$cellrelationid"
                 "createdBy" Integer 0
                "timeOfCreation" String "2017-11-29T09:32:56"
                 "extGeranCellRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,GeraNetwork=1,ExternalGeranCell=$ci"
              )
              ^;# end @MO
              print $fh "@MOCmds";
              
              $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              
              $cellrelationid++;
              $arraycounter2++;
              #$copyIrathomGSMdatapospointer++;
 
              if($cellname eq $lastGSMcellname){last;}#end loop if maximum gsm cells to be related is achieved
			 
 
    }# end while ttlnodegerancellrelations
        $copyIrathomGSMdatapospointer++;
	$IrathomGSMdatapospointer_counter=$copyIrathomGSMdatapospointer;
         $IrathomGSMdatapospointer=$IrathomGSMdatapospointer_counter;
     $GFGRarraycounter++;
	}
 
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # end : create GeranCellRelation
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~      
      $IrathomGSMdatapospointer_counter=$copyIrathomGSMdatapospointer;
      $IrathomGSMdatapospointer=$IrathomGSMdatapospointer_counter;
      $CELLCOUNT++;

    }# end while CELLCOUNT
 
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # end : CELLCOUNT
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);
 
 ################################
 # build MML script
 ################################
 @MMLCmds=(".open ".$SIMNAME,
           ".select ".$LTENAME,
           ".start ",
           "useattributecharacteristics:switch=\"off\"; ",
           "kertayle:file=\"$NETSIMMOSCRIPT\";"
 );# end @MMLCmds
 
 $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
 
 $NODECOUNT++;
 }# end outer NODECOUNT while
 
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # end : NODECOUNT while
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
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
# unlink "$NETSIMMMLSCRIPT";
 close $fh;
 print "... ${0} ended running at $date\n";
 ################################
 # END
 ################################
