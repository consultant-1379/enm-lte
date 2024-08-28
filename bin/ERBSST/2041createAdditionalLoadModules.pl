#!/usr/bin/perl
### VERSION HISTORY
####################################################################
####################################################################
# version1    : LTE 15.14
# Revision    : CXP 903 0491-170-1
# Jira        : NETSUP-3227
# Purpose     : create load Modules
# Description : create load Modules for ENM SHM support 
# Date        : Sept 2015
# Who         : ejamfur
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
use LTE_OSS15;
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

# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
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
while ($NODECOUNT<=$NUMOFRBS) {

    # get node name
    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);

    # build mml script 
    @MMLCmds=(".open ".$SIMNAME,
          ".select ".$LTENAME,
          ".start ",
          "useattributecharacteristics:switch=\"off\";",
    
	"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM30111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM30111\", attributes=\"productData (struct(AdminProductData))=[CXPENM30111,ENM14B319,CXP124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM30111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM30111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111\", attributes=\"productData (struct(AdminProductData))=[CXPENM3111,ENM1B319,CXP12466523,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM311123\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM311123\", attributes=\"productData (struct(AdminProductData))=[CXPENM311123,ENM1B31923,CXP23124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM311123\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM011123\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"C23XPENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=C23XPENM3111\", attributes=\"productData (struct(AdminProductData))=[C23XPENM3111,E23NM1B319,CXP12466235,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=C23XPENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/C23XPENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXAABPENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXAABPENM3111\", attributes=\"productData (struct(AdminProductData))=[CXAABPENM3111,ENM1B319,CAABXP124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXAABPENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXAABPENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM3111AAB\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111AAB\", attributes=\"productData (struct(AdminProductData))=[CXPENM3111AAB,ENM1B319,CXP124665AAB,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111AAB\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM011AAB1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENQQQM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENQQQM3111\", attributes=\"productData (struct(AdminProductData))=[CXPENQQQM3111,ENQQQM1B319,CXPQQQ124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENQQQM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENQQQM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM3007111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3007111\", attributes=\"productData (struct(AdminProductData))=[CXPENM3007111,ENM0071B319,CXP120074665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3007111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM0070111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXPENM3111007\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111007\", attributes=\"productData (struct(AdminProductData))=[CXPENM3111007,ENM1B319007,CXP124665007,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXPENM3111007\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXPENM0111007\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM30111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM30111\", attributes=\"productData (struct(AdminProductData))=[CSPXENM30111,ENM14B319,CSPX124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM30111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM30111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111\", attributes=\"productData (struct(AdminProductData))=[CSPXENM3111,ENM1B319,CSPX12466523,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM311123\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM311123\", attributes=\"productData (struct(AdminProductData))=[CSPXENM311123,ENM1B31923,CSPX23124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM311123\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM011123\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CA23XPENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CA23XPENM3111\", attributes=\"productData (struct(AdminProductData))=[CA23XPENM3111,E23NM1B319,CSPX12466235,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CA23XPENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CA23XPENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CXAAABPENM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXAAABPENM3111\", attributes=\"productData (struct(AdminProductData))=[CXAAABPENM3111,ENM1B319,CAAABXP124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CXAAABPENM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CXAAABPENM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM3111AAB\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111AAB\", attributes=\"productData (struct(AdminProductData))=[CSPXENM3111AAB,ENM1B319,CSPX124665AAB,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111AAB\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM011AAB1\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENQQQM3111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENQQQM3111\", attributes=\"productData (struct(AdminProductData))=[CSPXENQQQM3111,ENQQQM1B319,CSPXQQQ124665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENQQQM3111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENQQQM0111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM3007111\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3007111\", attributes=\"productData (struct(AdminProductData))=[CSPXENM3007111,ENM0071B319,CSPX120074665,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3007111\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM0070111\";",
"createmo:parentid=\"ManagedElement=1,SwManagement=1\",type=\"LoadModule\",name=\"CSPXENM3111007\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111007\", attributes=\"productData (struct(AdminProductData))=[CSPXENM3111007,ENM1B319007,CSPX124665007,YYY,May,]\";",
"setmoattribute:mo=\"ManagedElement=1,SwManagement=1,LoadModule=CSPXENM3111007\", attributes=\"loadModuleFilePath (string)=/c/loadmodules/CSPXENM0111007\";",
	
    );# end @MMLCmds
    $NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

  $NODECOUNT++;
}# end outer while NUMOFRBS
  # execute mml script
  #@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

  # output mml script execution 
  print "@netsim_output\n";
  
################################
# CLEANUP
################################
$date=`date`;
# remove mo script
#unlink "$NETSIMMMLSCRIPT";
print "... ${0} ended running at $date\n";
################################
# END
################################
