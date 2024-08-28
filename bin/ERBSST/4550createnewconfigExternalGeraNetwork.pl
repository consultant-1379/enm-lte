#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : 16A
# Revision    : CXP 903 0491-152-1
# Jira        : OSS-77886
# Purpose     : Support to establish DG2toGSM handover
# Date        : May 2015
# Who         : xkamvat
####################################################################
####################################################################
# Version2    : LTE 17A
# Revision    : CXP 903 0491-264-1
# Jira        : NSS-5736
# Purpose     : Increase the number of GeranFrequency per cell
# Description : To increase GeranFrequency
# Date        : Sep 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version3    : LTE 18B
# Revision    : CXP 903 0491-322-1
# Jira        : NSS-16469
# Purpose     : Increase the number of GeranFrequency per cell
# Description : To increase GeranFrequency
# Date        : Dec 2017
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for DG2 node
# Description : Sets timeOfCreation attribute for 
#               ExternalGeranCell MO
# Date        : feb 2018
# Who         : zyamkan
####################################################################
####################################################################
# Version4    : LTE 19.15
# Revision    : CXP 903 0491-365-1
# Jira        : NSS-32241
# Purpose     : NRM6.2 80K LTE 35K Design for Geran relations	
# Description : Design change to meet specific counts mentioned in 	 
#               above JIRA.
# Date        : Sep 2020
# Who         : xmitsin
####################################################################
####################################################################
## Version4    : LTE 22.06
## Revision    : CXP 903 0491-381-1
## Jira        : NSS-38981
## Purpose     : Updating ENodeB to support IDUN Staging testing  
## Description : Design change by adding ENodeB MOs mentioned in      
##               above JIRA.
## Date        : March 2022
## Who         : znrvbia
#####################################################################
####################
# Env
####################
 use FindBin qw($Bin);
 use lib "$Bin/../../lib/cellconfig";
 use Cwd;
 use POSIX;
 use LTE_CellConfiguration;
 use LTE_General;
 use LTE_Relations;
 use LTE_OSS12;
 use LTE_OSS13;
 use LTE_OSS14;
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
 local $whilecounter;
 local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
 local $MOSCRIPT="$scriptpath".${0}.".mo";
 local $MMLSCRIPT="$scriptpath".${0}.".mml";
 local @MOCmds,@MMLCmds,@netsim_output;
 local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
 local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
 local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
 local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
 local $DG2NUMOFNODESPERSIM=&getENVfilevalue($ENV,"DG2NUMOFRBS");
 local $MIMVERSION=$SIMNAME;$MIMVERSION=~s/-.*//g;$MIMVERSION=~s/LTE//;
 local $nodecountinteger;
 local $nodecountfornodestringname;
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
 # 500 geranfrequencies across 16 groups
 # groups 1 - 15 has 18 frequencies
 # group 16 has 18 frequencies as per NSS-32241(NRM6.2)
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 local $maxGeranFreqGrp=16;
 local $freqtillGrp15=18;
 local $freqforGrp16=18;
 
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
 local $IrathomDataNewlyCreated=0;
 local $command1="createnewconfigLTE2GRANnetworkdata.pl";
 local @IRATHOMGRANDATA=();
 local $startIrathomGSMdatapospointer=7;# first value on 20K GSM attributes file
 local $IrathomGSMdatapospointer=7;
 local $IrathomGSMdatapospointer_counter=7;
 local $IrathomGSMdatainmemory=0;
 local $arrayelement,$line_count;
 
 ####################
 # Integrity Check
 ####################
 
 if (-e "$NETSIMMOSCRIPT"){
     unlink "$NETSIMMOSCRIPT";}
 
 ################################
 # MAIN
 ################################
 #print "... ${0} started running at $date\n";
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # start : NODECOUNT while
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 while ($NODECOUNT<=$DG2NUMOFNODESPERSIM){  
 
       # get node name
       $LTENAME=&getLTESimStringNodeName($DG2,$NODECOUNT); 
 
       $nodecountinteger=&getLTESimIntegerNodeNum($DG2,$NODECOUNT,$DG2NUMOFNODESPERSIM);
 
       # nasty workaround for error in &getLTESimStringNodeName
       if($nodecountinteger>$DG2NUMOFNODESPERSIM){
          $nodecountfornodestringname=(($DG2-1)*$DG2NUMOFNODESPERSIM)+$NODECOUNT;
       }# end if
       else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
           
       @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]}; 
       $CELLNUM=@primarycells; 
 
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # start : create GeraNetwork
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
      @MOCmds=();
      @MOCmds=qq^ CREATE
               (
               parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1"
               identity 1
               moType Lrat:GeraNetwork
               exception none
               nrOfAttributes 0
       )
       CREATE
       (
            parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1"
            identity "1"
            moType Lrat:GUtraNetwork
            exception none
            nrOfAttributes 1
            "gUtraNetworkId" String "1"
        )
        CREATE
        (
            parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GUtraNetwork=1"
            identity "1"
            moType Lrat:GUtranSyncSignalFrequency
            exception none
            nrOfAttributes 1
            "gUtranSyncSignalFrequencyId" String "1"
        )
        CREATE
        (
            parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GUtraNetwork=1"
            identity "1"
            moType Lrat:ExternalGNodeBFunction
            exception none
            nrOfAttributes 10
            "externalGNodeBFunctionId" String "1"
            "gNodeBPlmnId" Struct
                nrOfElements 3
                "mcc" Int32 352
                "mnc" Int32 57
                "mncLength" Int32 2

            "gNodeBId" Int64 1
        )
        CREATE
        (
            parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GUtraNetwork=1,Lrat:ExternalGNodeBFunction=1"
            identity "1"
            moType Lrat:TermPointToGNB
            exception none
            nrOfAttributes 1
            "termPointToGNBId" String "1"
        )
        CREATE
        (
            parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GUtraNetwork=1,Lrat:ExternalGNodeBFunction=1"
            identity "1"
            moType Lrat:ExternalGUtranCell
            exception none
            nrOfAttributes 4 
            "externalGUtranCellId" String "1"
            "physicalLayerCellIdGroup" Int32 1
            "physicalLayerSubCellId" Int32 1
            "localCellId" Int32 1
        )

     ^;# end @MO
 
     $NETSIMMOSCRIPT=&makeMOscript("write",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     # end : create GeraNetwork
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         
    $CELLCOUNT=1;
    $IrathomGSMdatapospointer=$startIrathomGSMdatapospointer;
    $IrathomGSMdatapospointer_counter=$startIrathomGSMdatapospointer; ###7
 
    while($CELLCOUNT<=$CELLNUM) {
 
         $ttlnodegerancellrelations=$freqtillGrp15;
 
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
              if($ltenodename eq "$LTENAME-$CELLCOUNT"){last;}
              $IrathomGSMdatapospointer++;
     }# end for
    }# end if IRATHOMGSMTTLCELLS
 
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   # end : check for Irathom
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
   @MOCmds=();
   $loopcounter=1;
   $IrathomGSMdatapospointer_counter=$IrathomGSMdatapospointer;

   while ($loopcounter<=$ttlnodegerancellrelations){# start while $ttlnodegerancellrelations
        ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup)=split(/;/,$IRATHOMGRANDATA[$IrathomGSMdatapospointer_counter]);
         
         $tempvar=$freqgroup;
         $tempvar=~s/\n//;
         $freqgroup=~s/\n//;
		 
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       # ensure frequency group distribution is as expected
       # 124 geranfrequencies across 16 groups
       # groups 1 - 15 has 30 frequencies
       # group 16 has 50 frequencies
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if($freqgroup==$maxGeranFreqGrp){
            $ttlnodegerancellrelations=$freqforGrp16;   
        }# end if
        if($freqgroup<$maxGeranFreqGrp){
            $ttlnodegerancellrelations=$freqtillGrp15; 
        }# end if
 
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # start : create GERANFREQGROUPS
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
         @MOCmds=qq^ CREATE
               (
               parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GeraNetwork=1"
               identity $tempvar
               moType Lrat:GeranFreqGroup
               exception none
               nrOfAttributes 2
               geranFreqGroupId String $tempvar
               frequencyGroupId Int32 $tempvar
               )
               ^;# end @MO
		
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # end : create GERANFREQGROUPS
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # start : create GERANFREQUENCY
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       
        @MOCmds=qq^ CREATE
        (
        parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GeraNetwork=1"
        identity $ci
        moType Lrat:GeranFrequency
        exception none
        nrOfAttributes 2
        arfcnValueGeranDl Int32 $ci
        bandIndicator Integer 0
        "userLabel" String "Irathom enabled"
        geranFreqGroupRef Array Ref 1
        "ManagedElement=$LTENAME,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$freqgroup"
        )
        ^;# end @MO
		
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # end : create GERANFREQUENCY
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		
		    ##################### NRM6_2 #####################
             if ($loopcounter<=15)
             {
              push (@Array , "$ci");
             }
             else
             {
              $ci=$Array[$loopcounter-15-1];
             }

		
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # start : create ExternalGeraCell
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		
        @MOCmds=qq^ CREATE
        (
        parent "ComTop:ManagedElement=$LTENAME,Lrat:ENodeBFunction=1,Lrat:GeraNetwork=1"
        identity "$ci"
        moType Lrat:ExternalGeranCell
        exception none
        nrOfAttributes 11
        "externalGeranCellId" String "$ci"
        "bcc" Int32 $bcc
        "cellIdentity" Int32 $ci
        "createdBy" Integer 0
        "lac" Int32 $lac
        "masterGeranCellId" String "$ci"
        "ncc" Int32 $ncc
        "plmnIdentity" Struct
          nrOfElements 3
           "mcc" Int32 $mcc
           "mnc" Int32 $mnc
           "mncLength" Int32 $bscmncdigithand
        "reservedBy" Array Ref 0
        "timeOfCreation" String "2017-11-29T09:32:56"
        "userLabel" String "Irathom enabled"
        "geranFrequencyRef" Ref "ManagedElement=$LTENAME,ENodeBFunction=1,GeraNetwork=1,GeranFrequency=$ci"
        )
       ^;# end @MO
		
			$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
              #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
              # end : create ExternalGeraCell
              #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                
				 
                 $loopcounter++;
                 $IrathomGSMdatapospointer_counter++;
	             
                  if($cellname eq $lastGSMcellname)
		          { 
		            last;
		          }#end loop if maximum gsm cells to be related is achieved
                        
        }# end while $ttlnodegerancellrelations
          @Array=(); 
         $IrathomGSMdatapospointer=$IrathomGSMdatapospointer_counter;
         $CELLCOUNT++;
     }# end while for cell
 
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
 }
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
 # unlink @NETSIMMOSCRIPTS;
 # unlink "$NETSIMMMLSCRIPT";
 print "... ${0} ended running at $date\n";
 ################################
 # END
 ################################
