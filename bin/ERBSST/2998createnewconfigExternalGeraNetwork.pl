#!/usr/bin/perl
 ### VERSION HISTORY
 ####################################################################
 # Version1    : LTE 14B.1
 # Revision    : CXP 903 0491-74-1
 # Jira        : NETSUP-1674/NETSUP-1673
 # Purpose     : Support to establish LTE2GSM handover for new GSM
 #               configuration for MIM >= E1180
 # Comment     : updated to enable LTE2GSM configuration (>= E1180) handover 2 GSM network
 # SNID        : LMI-14:001028
 # Date        : July 2014
 # Who         : epatdal
 ####################################################################
 ####################################################################
 # Version2    : LTE 15B
 # Revision    : CXP 903 0491-122-1
 # Jira        : OSS-55899,OSS-55904
 # Purpose     : ensure this script fires for only LTE simulations
 #               and not DG2 or PICO
 # Description : verify that $SIMNAME is not of type DG2 or PICO
 # Date        : Feb 2015
 # Who         : epatdal
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
 # Version4    : LTE 18B
 # Revision    : CXP 903 0491-322-1
 # Jira        : NSS-16469
 # Purpose     : Increase the number of GeranFrequency per cell
 # Description : To increase GeranFrequency
 # Date        : Dec 2017
 # Who         : xkatmri
 ####################################################################
####################################################################
# Version5    : LTE 18.05
# Revision    : CXP 903 0491-328-1
# Jira        : NSS-13778
# Purpose     : Setting timeOfCreation attribute for ERBS node
# Description : Sets timeOfCreation attribute for 
#               ExternalGeranCell & TermPointToSGW MO
# Date        : feb 2018
# Who         : zyamkan
#################################################################### 
####################################################################
# Version5    : LTE 21.09
# Revision    : CXP 903 0491-373-1
# Jira        : NSS-34910
# Purpose     : To meet the count of GeranFreq and geranCells NRM5.1 config
# Description : NRM5.1: Design 30K LTE network in NSS
# Date        : May 2021
# Who         : xmitsin
####################################################################
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
 local $SIMNAME=$ARGV[0],$ENV=$ARGV[1],$LTE=$ARGV[2];
 #---------------------------------------------------------------
 # start verify params and sim node type
 local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
 Example: $0  LTEG1301-limx160-5K-FDD-LTE10 CONFIG.env 10);
 if (!( @ARGV==3)){
    print "@helpinfo\n";exit(1);}
 # check if SIMNAME is of type PICO or DG2
 if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
 # end verify params and sim node type
 #---------------------------------------------------------------
 local $date=`date`,$LTENAME;
 local $dir=cwd,$currentdir=$dir."/";
 local $scriptpath="$currentdir";
 local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
 local $MOSCRIPT="$scriptpath".${0}.".mo";
 local $MMLSCRIPT="$scriptpath".${0}.".mml";
 local @MOCmds,@MMLCmds,@netsim_output;
 local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
 local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
 local $CELLNUM=&getENVfilevalue($ENV,"CELLNUM"),$CELLCOUNT;
 local $CELLNUM28K=&getENVfilevalue($ENV,"CELLNUM28K");
 local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
 local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
 local $MIMVERSION=$SIMNAME;$MIMVERSION=~s/-.*//g;$MIMVERSION=~s/LTE//;
 local $nodecountinteger;
 local $nodecountfornodestringname;
 local $arrayelement;
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
 # groups 1 - 15 has 30 frequencies
 # group 16 has 50 frequencies
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 local $maxGeranFreqGrp=16;
 local $freqtillGrp15=18; #nrm5_1
 local $freqforGrp16=18; #nrm5_1
 
 # Irathom data
 local $IRATHOMDIR=$scriptpath;
 $IRATHOMDIR=~s/bin.*/customdata\/irathom\//;
 local ($ltenodename,$cellname,$mcc,$mnc,$bscmncdigithand,$lac,$ci,$ncc,$bcc,$bccno,$csystype,$freqgroup);
 local $IrathomInputFile=&getENVfilevalue($ENV,"IRATHOMGSMLTEFILENAME");
 $IrathomInputFile="$IRATHOMDIR/$IrathomInputFile";
 local $IrathomRelationFile="$IRATHOMDIR/PrivateNewConfigIrathomLTE2GRAN.csv";
 local $IRATHOMGSMTTLCELLS=&getENVfilevalue($ENV,"IRATHOMGSMTTLCELLS");
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
 # Check support for updated GSM configuration
 $mimcomparisonstatus=&isgreaterthanMIM($MIMVERSION,$MIMsupportforupdatedGSMconfiguration);
 if($mimcomparisonstatus eq "no"){
   print "GSM configuration not supported for MIM $MIMVERSION in script ${0}\n";
   exit;
 }# end if
 
 ################################
 # MAIN
 ################################
 print "... ${0} started running at $date\n";
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # start : NODECOUNT while
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 while ($NODECOUNT<=$NUMOFRBS){
 
       # get node name
       $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
 
       $nodecountinteger=&getLTESimIntegerNodeNum($LTE,$NODECOUNT,$NUMOFRBS);
 
       # nasty workaround for error in &getLTESimStringNodeName
       if($nodecountinteger>$NUMOFRBS){
          $nodecountfornodestringname=(($LTE-1)*$NUMOFRBS)+$NODECOUNT;
       }# end if
       else{$nodecountfornodestringname=$nodecountinteger;}# end workaround
           
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # flexible CELLNUM allocation
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @primarycells=@{$PRIMARY_NODECELLS[$nodecountfornodestringname]};
    $CELLNUM=@primarycells;
 
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # start : create GeraNetwork
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
      @MOCmds=();
      @MOCmds=qq^ CREATE
               (
               parent "ManagedElement=1,ENodeBFunction=1"
               identity 1
               moType GeraNetwork
               exception none
               nrOfAttributes 0
       )
       SET
       (
        mo "ManagedElement=1,ENodeBFunction=1,TermPointToSGW=1"
        exception none
        nrOfAttributes 1
        "timeOfCreation" String "2017-11-29T09:32:56"
        )

     ^;# end @MO
 
     $NETSIMMOSCRIPT=&makeMOscript("write",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     # end : create GeraNetwork
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    $CELLCOUNT=1;
    $IrathomGSMdatapospointer=$startIrathomGSMdatapospointer;
    $IrathomGSMdatapospointer_counter=$startIrathomGSMdatapospointer;
 
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
 
     for( $arrayelement=$startIrathomGSMdatapospointer;$arrayelement<=$line_count;$arrayelement++ ){
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
       # 500 geranfrequencies across 16 groups
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
               parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1"
               identity $tempvar
               moType GeranFreqGroup
               exception none
               nrOfAttributes 2
               GeranFreqGroupId String $tempvar
               frequencyGroupId Integer $tempvar
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
        parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1"
        identity $ci
        moType GeranFrequency
        exception none
        nrOfAttributes 2
        arfcnValueGeranDl Integer $ci
        bandIndicator Integer 0
        "userLabel" String "Irathom enabled"
        geranFreqGroupRef Array Ref 1
        "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFreqGroup=$freqgroup"
        )
        ^;# end @MO
        $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # end : create GERANFREQUENCY
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
        parent "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1"
        identity "$ci"
        moType ExternalGeranCell
        exception none
        nrOfAttributes 11
        "ExternalGeranCellId" String "$ci"
        "bcc" Integer $bcc
        "cellIdentity" Integer $ci
        "createdBy" Integer 0
        "lac" Integer $lac
        "masterGeranCellId" String "$ci"
        "ncc" Integer $ncc
        "plmnIdentity" Struct
          nrOfElements 3
           "mcc" Integer $mcc
           "mnc" Integer $mnc
           "mncLength" Integer $bscmncdigithand
        "reservedBy" Array Ref 0
        "timeOfCreation" String "2017-11-29T09:32:56"
        "userLabel" String "Irathom enabled"
        "geranFrequencyRef" Ref "ManagedElement=1,ENodeBFunction=1,GeraNetwork=1,GeranFrequency=$ci"
        )
       ^;# end @MO
 
       $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
 
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       # end : create ExternalGeraCell
       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
          $loopcounter++;
          $IrathomGSMdatapospointer_counter++;
 
     if($cellname eq $lastGSMcellname){last;}#end loop if maximum gsm cells to be related is achieved
 
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
 # @netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;
 
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
