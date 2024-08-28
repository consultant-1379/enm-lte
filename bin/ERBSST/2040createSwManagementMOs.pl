#!/usr/bin/perl
### VERSION HISTORY
###############################################################################
# Version1    : LTE 16A
# Revision    : CXP 903 0491-1-1
# Purpose     : Creates the following Managed objects,ReliableProgramUniter,
#               and  PiuType.
# Description : Create ReliableProgramUniter and PiuType under ManagedElement=1,
#		SwManagement=1
# Date        : May 2015
# Who         : ejamfur
###############################################################################
###############################################################################
# Version2    : LTE 16A
# Revision    : CXP 903 0491-160-1
# Jira        : CIS-11151
# Purpose     : Create UpgradePackage CXP(NODE NAME),LoadModules 
#		aal0_dynamic, equipmp and etm4v2atm              
# Description : Create UpgradePackage CXP(NODE NAME),LoadModules 
#		aal0_dynamic,equipmp and etm4v2atm under ManagedElement=1,
#		SwManagement=1 and set productData attribute.
# Date        : June 2015
# Who         : ejamfur
###############################################################################
###############################################################################
# Version3    : LTE 15.14
# Revision    : CXP 903 0491-169-1
# Jira        : CIS-13722
# Purpose     : Create loadModule=1, SwAllocation, ReliableProgramUniter and 
#               Repertoire.
# Description : Create loadModule=1, SwAllocation, ReliableProgramUniter and
#               Repertoire under ManagedElement=1, SwManagement=1. 
# Date        : Sept 2015
# Who         : ejamfur
###############################################################################
###############################################################################
# Version4    : LTE 15.14
# Revision    : CXP 903 0491-170-1
# Jira        : NETSUP-3322
# Purpose     : set attributes under ManagedElement=$managedElement,SwManagement=1,
#               ConfigurationVersion=1  
# Description : set attributes under ManagedElement=$managedElement,SwManagement=1,
#               ConfigurationVersion=1 for SHM support.                
# Date        : Sept 2015
# Who         : ejamfur
###############################################################################
###############################################################################
# Version5    : LTE 15.15
# Revision    : CXP 903 0491-173-1
# Jira        : CIS-13246
# Purpose     : set SHM MO attributes
# Description : append load module count to load Module productdata values and
#               set loadModuleFilePath to node name under
#               ManagedElement=$managedElement,SwManagement=1,
# Date        : Sept 2015
# Who         : ejamfur
###############################################################################
###############################################################################
# Version6    : LTE 15.16
# Revision    : CXP 903 0491-179-1
# Jira        : NETSUP-3162
# Purpose     : create additional PiuTypes, LoadModules, UpgradePackages
# Description : create additional 25 PiuTypes, 400 LoadModules,
#		6 UpgradePackages each mapping to 100 LoadModules.
# Date        : Oct 2015
# Who         : edalrey
###############################################################################
###############################################################################
# Version7    : LTE 15.16
# Revision    : CXP 903 0491-180-1
# Jira        : NSS-290
# Purpose     : Add 6 additional CVs to storedConfigiurationVersions
# Description : Add 6 additional CVs to storedConfigiurationVersions to make RV
#		data consistent with SHM feature team requirements.
# Date        : Oct 2015
# Who         : edalrey
###############################################################################
###############################################################################
# Version8    : LTE 16.2
# Revision    : CXP 903 0491-194-1
# Jira        : NSS-1008,TORF-97603
# Purpose     : Support for updating Product Revision for CPP based node,sync Issue
# Description : NETSim provided a patch for updating ProductData for CPP Node
#               but it will be set on attributes only if they are empty. So, 
#               not assigning attribute values while creating UpgradePackage=1
# Date        : Feb 2016
# Who         : xsrilek
###############################################################################
###############################################################################
# Version9    : LTE 16.5
# Revision    : CXP 903 0491-201-1
# Jira        : NSS-2272
# Purpose     : Reducing the SHM MO count
# Description : To reduce the Load on the simulation ,deleting the SHM Mo's as these are
#		not being used.
# Date        : Mar 2016
# Who         : xyemvam
###############################################################################
###############################################################################
# Version10    : LTE 16.15
# Revision    : CXP 903 0491-262-1
# User Story  : NSS-5920
# Purpose     : To Change default Date Format
# Description : Sets Date Format in StoredConfigurationVersions attribute of
#               ConfigurationVersion MO
# Date        : Sep 2016
# Who         : xmitsin
###############################################################################
###############################################################################
# Version11   : LTE 17.3
# Revision    : CXP 903 0491-281-1
# User Story  : NSS-8862
# Purpose     : To update Default CVs present on ERBS Nodes
# Description : Sets UpgradePackageId in Default CVs
# Date        : Jan 2017
# Who         : xkatmri
###############################################################################
###############################################################################
# Version11   : LTE 18.05
# Revision    : CXP 903 0491-326-1
# User Story  : NSS-16577
# Purpose     : To update upgradePackageDocumentId attribute on ERBS Nodes
# Description : Sets upgradePackageDocumentId in Default CVs
# Date        : Feb 2018
# Who         : zyamkan
###############################################################################
###############################################################################
# Version11   : LTE 20.06
# Revision    : CXP 903 0491-359-1
# User Story  : NSS-28822
# Purpose     : To update UpgradePackage Production Date
# Description : Sets productionDate attribute to a valid value in UpgradePackage mo
# Date        : Mar 2020
# Who         : xharidu
###############################################################################
###############################################################################
# Version11   : LTE 20.06
# Revision    : CXP 903 0491-360-1
# User Story  : NSS-28822
# Purpose     : To update UpgradePackage Production Date (PART-2)
# Description : Sets productionDate attribute to 8digit format
# Date        : Mar 2020
# Who         : xharidu
###############################################################################
###############################################################################
# Version11   : LTE 20.16
# Revision    : CXP 903 0491-369-1
# User Story  : NSS-32192
# Purpose     : Provide values for hardware type, name and number for basebandNodes
# Description : Provide values for hardware type, name and number for baseband 
# Date        : Sep 2020
# Who         : xmitsin
###############################################################################

####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_CellConfiguration;
use LTE_General;
use LTE_Relations;
use LTE_OSS13;
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
	print "@helpinfo\n";exit(1);
}
# check if SIMNAME is of type PICO or DG2
if(&isSimLTE($SIMNAME)=~m/NO/){
	exit;
}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$pdkdate=`date +'%Y%m%d'`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}."toFetchUPGid.mml";
local $MMLSCRIPTtoFetchUPGid="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $MMLtoFetchUPGid,@netsim_output_toFetchUPGid,$NETSIMMMLtoFetchUPGid;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
local @upgradePackageNames=(1, "CXP102051/19_R35EH", "CXP102051/22_R51CU", "CXP102051/21_R38ES");
local $nodeSpecificUpgradePackagesCount=2;
local @piuTypeIdentitys=("1", "KRC11866/2_*", "KRC161262/3_*", "KRC161380/1_*", "KRC131144/1_*", "KRC161453/1_*", "KRC161513/1_*", "KRC161327/2_*", "KRC11871/2_*", "KRC11876/1_*", "KRC161332/2_*", "INITIALRBSRU_*", "KDU137624/1_*", "KRC161298/1_*", "INITIALRBSIRU_*", "KRC161282/1_*", "IRUpreInstalledSW_*", "PDU00000_*", "KRC161436/1_*", "KRC161326/3_*", "KRC11870/3_*", "KRC161473/2_*", "KRC161457/1_*", "KRC118041/1_*", "KRC11875/2_*", "KRC11859/1_*", "KRC161255/2_*", "KRC161331/3_*", "KRC161501/1_*", "KRC118159/1_*", "SUP00000_*", "KRC161462/1_*", "KRC161276/2_*", "KRC161483/1_*", "KRC161297/2_*", "KRC161286/1_*", "KRC161419/1_*", "KRC11890/1_*", "KRC118003/1_*", "KRC161383/2_*", "KRC161330/1_*", "KRC161291/1_*", "KRC161330/4_*", "KRC118008/3_*", "KRC118050/1_*", "KRC161308/1_*", "KRC161285/2_*", "KRC161329/1_*", "KRC11873/1_*", "KRC161253/1_*", "SCU00000_*", "KRC161329/4_*", "KRC11894/1_*", "KRC161334/1_*", "KRC118028/1_*", "KRC161381/1_*", "KRC131145/1_*", "RULpreInstalledSW_*", "KRC161328/2_*", "KRC11856/1_*", "KRC161349/2_*", "KRC11877/1_*", "KRC11898/1_*", "KRC161241/1_*", "RUSpreInstalledSW_*", "KRC161283/1_*", "KRC161469/2_*", "KRC161327/3_*", "KRC118058/1_*", "KRC161332/3_*", "KRC161502/1_*", "KRC161463/1_*", "KRC11865/1_*", "KRC161484/1_*", "KRC161321/2_*", "KRC118165/1_*", "KRC161282/2_*", "KRC161326/1_*", "KRC131143/3_*", "KRC161287/1_*", "KDU137949/1_*", "KRC161326/4_*", "KRC11891/1_*", "KRC118004/1_*", "KRC161331/1_*", "KRC118041/2_*", "KRC11859/2_*", "KRC161292/1_*", "KRC161331/4_*", "KRC11864/2_*", "KRC131142/1_*", "KRC161325/2_*", "BGM1361006/1_*", "KRC161309/1_*", "KRC118072/1_*", "KRC11890/2_*", "KRC11874/1_*", "INITIALRBSRRU_*", "KRC161254/1_*", "KRC161330/2_*", "KRC11895/1_*", "KRC161408/1_*", "RRUSpreInstalledSW_*", "KRC161296/1_*", "KRC161280/1_*", "KDU137533/3_*", "KRC161377/1_*", "KRC161466/2_*", "KRC118034/1_*", "KRC161434/1_*", "KRC161382/1_*", "KDU137745/1_*", "KRC131146/1_*", "KRC161455/1_*", "KRC161329/2_*", "KRC11873/2_*", "KRC161460/1_*", "KRC161520/1_*", "KRC11862/1_*", "KRC11899/1_*", "KRC161481/1_*", "KDU137624/31_*", "PSU00000_*", "KRC161263/1_*", "KRC161284/1_*", "KRC118001/1_*", "KDU137930/1_*", "KRC161401/1_*", "KRC161328/3_*", "KDU127189/2_*", "KRC161503/1_*", "KRC161241/2_*", "KRC161464/1_*", "KRC11866/1_*", "BFU00000_*", "KRC161262/2_*", "KRC161485/1_*", "KRC161299/2_*", "KDU137624/11_*", "KRC161306/1_*", "KRC118166/1_*", "KRC161327/1_*", "KRC11871/1_*", "KRC161327/4_*", "KRC118005/1_*", "KRC161332/1_*", "KRC161293/1_*", "KRC161332/4_*", "KRC161479/2_*", "KRC118047/1_*", "KRC161410/1_*", "KRC161507/1_*", "KRC118031/1_*", "KRC11865/2_*", "KDU137624/3_*", "KRC131143/1_*", "KRC161282/3_*", "KRC161512/1_*", "KRC161326/2_*", "KRC11870/2_*", "KRC161287/2_*", "KRC11891/2_*", "KRC11875/1_*", "KRC161255/1_*", "KRC161331/2_*", "KRC161276/1_*", "EMU00000_*", "KRC161260/1_*", "KRC161320/1_*", "KRC161462/3_*", "KRC11864/3_*", "KRC118035/1_*", "INITIALRBSXMU_*", "KRC161451/2_*", "KRC161456/1_*", "KRC11874/2_*", "KRC161254/2_*", "KRC161330/3_*", "KRC161461/1_*", "KRC161275/2_*", "KRC11863/1_*", "KRC161243/1_*", "KRC118163/1_*", "KDU137533/4_*", "KRC161264/1_*", "SAU00000_*", "KRC161466/3_*", "KRC161285/1_*", "KRC118002/1_*", "KRC118039/1_*", "KRC161402/1_*", "KRC161329/3_*", "KRC161290/1_*", "KRC161423/1_*", "KRC161444/1_*", "ZHY60117/1_*", "KRC11862/2_*", "KRC161525/1_*", "KRC11830/1_*", "KRC118167/1_*", "KRC161470/1_*", "INITIALRBSXMU03_*", "KRC161328/1_*", "KRC11872/1_*", "KRC118038/2_*", "KRC161328/4_*", "KRC118006/1_*");
local @LoadModuleList=("1","aal0_dynamic","equipmp","etm4v2atm", "CXC1725872_R87B01", "CXC1727220_R87C11", "CXC1735548/22_R51AA", "CXP102066/5_R87C01", "CXC1731083/21_R38BV", "CXC1725059/21_R18D", "CXC1731080_R84E07", "CXC1732204_R82E21", "CXC1725422/5_R84E27", "CXC1321344_R84E07", "CXC1725037/19_R19E", "CXC1721176_R87C08", "CXC1721883_R82E15", "CXC1723373_R82C01", "CXC1721555_R82E151", "CXC1329573_R84E09", "CXC1732823/22_R51T", "CXC1730438_R82E151", "CXC1730871/19_R35CC", "CXC1734943/3_R85B01", "CXC1733444_R82E33", "CXC1732167_R84E12", "CXC1324324_R82E04", "CXC1725049/19_R19D", "CXC1728445_R84D01", "CXC1721212_R82E150", "CXC1729858_R82E150", "CXC1730719/22_R51F", "CXC1320960_R82E151", "CXC1322601/19_R19F", "CXC1730720/19_R13C", "CXC1735219_R19E", "CXC1732407/21_R38AL", "CXC1732821_R87C08", "CXC1723340_R82E150", "CXP9023351/21_R38BS", "CXC1734949_R84E02", "CXC1734179/22_R51K", "CXC1320787_R82E17", "CXC1321315_R84E19", "CXC1323464_R87C08", "CXC1327582/2_R83D01", "CXC1725686/19_R19E", "CXC1723340_R83D01", "CXC1725638/19_R19D", "CXC1725027/21_R18D", "CXC1322458/22_R13BL", "CXC1734322/19_R35AZ", "CXC1730015/22_R25A", "CXC1734470_R82E150", "CXC1733150_R84E73", "CXC1732749/19_R35AZ", "CXC1726033_R85H01", "CXP9023351/22_R51AA", "CXC1730719/21_R38Z", "CXC1728228/22_R51J", "CXC1726723_R85B02", "CXC1321341_R84E11", "CXC1733266_R86F01", "CXC1725482/1_R20G/10", "CXC1732733/19_R35AZ", "CXC1725616/21_R18D", "CXP102066/3_R82E06", "CXC1734943/5_R83D01", "CXC1721554_R83E11", "CXP9013268/13_R57MA", "CXP9020692/21_R38BV", "CXC1734156_R82E150", "CXC1734486/19_R1A", "CXC1733306/22_R51V", "CXC1731602_R87C45", "CXC1321314_R87C07", "CXC1724637_R83D01", "CXC1729990_R82E150", "CXC1733149_R82E76", "CXC1732289/1_R84E26", "CXC1726213_R84E99", "CXC1734470_R84E01", "CXC1325240/1_R84E08", "CXP9020294/22_R51AC", "CXC1732768/22_R51S", "CXC1731080_R82E16", "CXC1323891/6_R82E42", "CXC1725059/22_R13BL", "CXC1325601_R82E04", "CXC1321344_R82E15", "CXC1731354_R87C09", "CXC1325792_R87C08", "CXC1735492_R84E12", "CXP9020692/22_R51AC", "CXC1329573_R82E19", "CXC1323911_R87C10", "CXC1328917_R82E151", "CXC1734037/21_R38AD", "CXC1729066/19_R19D", "CXC1734322/22_R51H", "CXC1721203_R84E01", "CXC1728447_R85B01", "CXC1732167_R82E22", "CXC1725874_R82E150", "CXC1737122_R13BL", "CXC1730620/22_R25B", "CXC1326608_R83D01", "CXC1327705_R87C07", "CXP9024836/1_R55XC", "CXC1734949_R82E04", "CXC1734944/3_R82E04", "CXC1730135/22_R51G", "CXC1723333_R86G03", "CXC1726067_R85D02", "CXC1724447/19_R19L", "CXC1725790/10_R87C07", "CXC1721558_R84E02", "CXC1321315_R82E27", "CXC1723350_R83D01", "CXC1725482/1_R21E/8", "CXC1721203_R87A01", "CXP9019797/2_R4G", "CXC1731000/19_R13C", "CXC1731539/21_R38AF", "CXC1725482/1_R22F/18", "CXC1733962/19_R35BA", "CXP9019797/2_R5F", "CXC1730627_R84E02", "CXP9013268/12_R59BK", "CXC1321341_R82E21", "CXC1725398/21_R38AL", "CXC1729957_R87C09", "CXC1721282_R87C14", "CXC1729068/21_R18D", "CXC1733150_R82E97", "CXC1731012/19_R13C", "CXP9019797/2_R6H", "CXC1734179/19_R35BG", "CXC1734943/1_R82E04", "CXC1735326_R85H01", "CXC1729153/22_R25A", "CXC1734950_R82E04", "CXC1727396/22_R51F", "CXC1727246/21_R38AD", "CXC1320783_R84E10", "CXC1725872_R83E11", "CXC1724100_R83D01", "CXC1326054_R87C07", "CXC1725866_R82E150", "CXC1325240/1_R82E18", "CXC1732408/19_R35CC", "CXC1730627_R87A01", "CXC1734943/2_R85B01", "CXP9017076/1_R3L01", "CXC1734036/22_R51G", "CXC1736537/1_R1C", "CXC1735798_R86G01", "CXC1736079/19_R1B", "CXC1735492_R82E22", "CXP102066/3_R83D02", "CXP9013268/12_R59FM", "CXC1729858_R86A01", "CXC1726246_R85B01", "CXC1721489_R82E04", "CXC1728186_R87C07", "CXC1729047/21_R21F", "CXC1721208_R84D01", "CXC1723335_R83D01", "CXC1725046/19_R19D", "CXC1725870_R82E150", "CXC1728447_R83E11", "CXC1728446_R83D01", "CXC1730716/22_R51E", "CXC1322506_R87C07", "CXC1325601_R83D01", "CXC1734177/19_R35BG", "CXC1725060/21_R18D", "CXC1736233_R87C07", "CXC1322459/19_R19E", "CXC1732406/19_R35BB", "CXC1732768/21_R38AL", "CXC1320782_R87C12", "CXC1731602_R82E108", "CXC1729125/9_R87C07", "CXC1725190/21_R38BF", "CXC1735763_R87C07", "CXC1726213_R82E150", "CXC1725444_R84E09", "CXC1736076/19_R1B", "CXC1728281_R87C08", "CXC1732823/21_R38BT", "CXC1721206_R84E02", "CXC1736539/2_R1A", "CXC1730720/22_R51G", "CXC1727219_R84E13", "CXC1725871_R85B01", "CXC1723378_R83D01", "CXC1721210_R84E03", "CXC1729176/21_R18D", "CXC1732406/22_R51J", "CXP9020294/21_R38BV", "CXC1730716/21_R38Z", "CXC1725193/22_R51N", "CXC1728332/22_R51M", "CXC1729153/19_R23A", "CXC1734484/22_R1A", "CXC1723373_R84A02", "CXC1320783_R82E19", "CXC1723374_R84E06", "CXP9013268/6_R59GC", "CXC1732443/19_R35AZ", "CXC1730720/21_R38AF", "CXC1736540/2_R1C", "CXC1728228/21_R38AE", "CXC1730717/19_R13C", "CXC1735251/22_R51L", "CXC1729105/6_R84E10", "CXC1723048_R85B01", "CXC1723337_R82E150", "CXC1736068/19_R1C", "CXC1736068/19_R1E", "CXC1721192_R83G01", "CXC1721218_R85E03", "CXC1329000/5_R87C08", "CXC1725038/19_R19D", "CXC1726246_R82E150", "CXC1721556_R82E150", "CXP9023090/1_R82E07", "CXC1322458/21_R18D", "CXC1727357/19_R35BA", "CXC1734943/1_R83D01", "CXC1726201/12_R82E17", "CXC1734948_R82E04", "CXC1734944/2_R82E04", "CXC1327582/2_R85B01", "CXC1734950_R83D01", "CXC1723340_R85B01", "CXC1730607/22_R51AC", "CXC1734943/4_R82E04", "CXC1327443_R87C02", "CXC1727395/21_R38AG", "CXC1728445_R82E150", "CXC1726246_R83E11", "CXC1721176_R84E07", "CXC1727220_R84E24", "CXC1726609/19_R35BA", "CXC1734036/19_R35BA", "CXC1729125/7_R82E16", "CXC1726723_R82E150", "CXC1725639/19_R19D", "CXC1729990_R87C07", "CXC1730015/19_R23A", "CXC1730626_R82E150", "CXC1734943/5_R85B01", "CXC1320960_R87C04", "CXC1721489_R83D01", "CXC1723356_R85D02", "CXC1725193/19_R35CD", "CXC1724637_R85B01", "CXC1730438_R83D01", "CXC1730709/19_R13C", "CXC1732821_R84E11", "CXC1721216_R84E01", "CXC1734945_R82E04", "CXC1727219_R82E24", "CXC1725444_R82E21", "CXC1725482/2_R20G/10", "CXC1323464_R84E09", "CXC1723491_R83D01", "CXP102145/1_R85B01", "CXC1736541_R1A", "CXC1735478_R87C07", "CXC1721553_R85H01", "CXC1730871/21_R38BV", "CXC1736725/22_R51L", "CXC1723342_R83D01", "CXC1725871_R83E11", "CXC1723374_R82E10", "CXC1729046/22_R25B", "CXC1324872/5_R86G01", "CXC1726067_R82E150", "CXC1724231_R85B01", "CXC1733266_R83H01", "CXC1731081_R87C08", "CXC1326608_R85B01", "CXC1731219_R86B01", "CXC1731000/22_R51E", "CXC1735309_R82E05", "CXC1733334_R83D01", "CXC1723333_R82E150", "CXC1730871/22_R51AC", "CXC1730709/22_R51E", "CXC1725686/21_R18D", "CXP102066/5_R82E06", "CXC1725191/19_R35BS", "CXC1737741/22_R51F", "CXC1725605_R85B01", "CXC1726231/21_R38AC", "CXC1731012/22_R51G", "CXC1727357/22_R51J", "CXC1723346_R85B01", "CXC1725874_R85B01", "CXC1721555_R83D01", "CXC1725034/19_R19D", "CXC1723350_R85B01", "CXC1721552_R82E150", "CXC1730620/19_R23A", "CXC1727220_R82E29", "CXC1321314_R84E10", "CXC1321316_R87C07", "CXC1730136/22_R51G", "CXC1320781_R87C07", "CXC1721176_R82E15", "CXC1325792_R84E08", "CXC1732733/21_R38AE", "CXC1732953/22_R13BL", "CXC1726230/19_R35AZ", "CXC1723356_R83D01", "CXC1731354_R84E13", "CXC1732263_R87C07", "CXC1731000/21_R38Z", "CXP9023090/1_R83D02", "CXP9013268/10_R59FM", "CXC1730709/21_R38Z", "CXC1734948_R83D01", "CXC1323911_R84E23", "CXP9025194/1_R2L", "CXC1327705_R84E07", "CXC1732821_R82E18", "CXC1732749/22_R51G", "CXC1731001/19_R13C", "CXC1322456/19_R19E", "CXC1728332/21_R38BX", "CXC1725482/2_R22F/18", "CXC1731602_R84E80", "CXC1731539/19_R13C", "CXC1734943/4_R83D01", "CXC1730062/19_R35CC", "CXC1734944/5_R82E04", "CXC1720482_R83D01", "CXC1723378_R82E150", "CXC1323464_R82E19", "CXC1736665/21_R18D", "CXP9025219/2_R1S", "CXC1732289/2_R87C14", "CXC1721212_R87C01", "CXC1732469_R87C07", "CXC1729046/19_R23A", "CXC1327582/2_R82E150", "CXC1721282_R84E08", "CXP9025220/2_R1G", "CXC1727396/19_R35BA", "CXC1725190/22_R51Z", "CXC1720772_R82E01", "CXC1725045/21_R18D", "CXC1721206_R82E150", "CXC1724447/21_R18C", "CXC1720327_R87C01", "CXC1730607/21_R38BV", "CXC1734037/22_R51G", "CXC1734945_R83D01", "CXC1723335_R85B01", "CXC1736537/2_R1C", "CXC1728446_R85B01", "CXC1730715/21_R38AB", "CXC1724231_R83E11", "CXC1730137/19_R35AZ", "CXC1736089/19_R1D", "CXC1721218_R82E150", "CXC1325608_R87C07", "CXC1328917_R83D01", "CXC1325601_R85B01", "CXC1725083/19_R19D", "CXC1725422/4_R82E52", "CXC1732029_R87C07", "CXC1725035/19_R19D", "CXC1729957_R84E24", "CXC1723346_R82E150", "CXC1321314_R82E21", "CXC1721208_R86H01", "CXC1725605_R83E11");
local $LoadModule;
local $tempUpgradePackageName;
local @storedConfigVersionAttributes;
local @storedConfigVersionAttributeNamesForRV;
local $rvSwitchOfStoredConfigVersions=8;
local $numOfStoredConfigVersions=14;
local $loadModuleCounter;
local $productDataValue;
####################
# Integrity Check
####################
if (-e "$NETSIMMOSCRIPT"){
	unlink "$NETSIMMOSCRIPT";
}
################################
# MAIN
################################
print "...${0} started running at $date\n";
################################
# Make MO & MML Scripts
################################
while ($NODECOUNT<=$NUMOFRBS){# start outer while

	# get node name
	$LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT,$SIMNAME);
        $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);
        $ProductDatafile="ProductData.env";
        $ProductData=&getENVfilevalue($ProductDatafile,"$MIMVERSION");
        @productData = split( /:/, $ProductData );
        $productNumber=$productData[0];
        $productRevision=$productData[1];
        chomp $pdkdate;

        #Check for Product Data information
         if (($productNumber eq "ERROR")||($productRevision eq "")) {#start if
             print "ERROR : Product data information missing, the script will exit\n\n";
             exit;
          }#end if


	local $managedElement=&getManagedElement($LTENAME);
	for my $i ( 1 .. $nodeSpecificUpgradePackagesCount ) {
		$tempUpgradePackageName="CXP".$LTENAME."_".$i;
		push @upgradePackageNames, $tempUpgradePackageName;
	}

	@MOCmds=();
	@MOCmds=qq^ CREATE
	(
		parent "ManagedElement=$managedElement,SwManagement=1"
		identity "1"
		moType ReliableProgramUniter
		exception none
		nrOfAttributes 0
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

	@MOCmds=();
	@MOCmds=qq^ CREATE
	(
		parent "ManagedElement=$managedElement,SwManagement=1"
		identity "sctp"
		moType ReliableProgramUniter
		exception none
		nrOfAttributes 0
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

	foreach $piuTypeIdentity (@piuTypeIdentitys) {
		@MOCmds=();
		@MOCmds=qq^ CREATE 
		(
			parent "ManagedElement=$managedElement,SwManagement=1"
			identity "$piuTypeIdentity"
			moType PiuType
			exception none
			nrOfAttributes 0
		)
	 	    
		^;# end @MO

		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

	}#end foreach

	    @MOCmds=();
		@MOCmds=qq^ SET 
		(
                 mo "ManagedElement=1,SwManagement=1,PiuType=1"
                 exception none
                 nrOfAttributes 1
                 "productData" Struct
                 nrOfElements 5
                      "productNumber" String "$productNumber"
                      "productRevision" String "$productRevision"
                      "productName" String "DUS"
                      "productInfo" String "ERBS"
                      "productionDate" String "$pdkdate"
 
		)
		^;# end @MO

		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	
	
	
	
	@MOCmds=();
	@MOCmds=qq^ CREATE
	(
		parent "ManagedElement=$managedElement,SwManagement=1"
		identity "1"
		moType SwAllocation
		exception none
		nrOfAttributes 0
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);


	@MOCmds=();
	@MOCmds=qq^ CREATE
	(
		parent "ManagedElement=$managedElement,SwManagement=1"
		identity "1"
		moType Repertoire
		exception none
		nrOfAttributes 0
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);


	# CXP 903 0491-160-1 
	$loadModuleCounter=0;
	foreach $LoadModule (@LoadModuleList) {
		$productDataValue=$LTENAME."_".$loadModuleCounter; 		
		@MOCmds=();
		@MOCmds=qq^ CREATE
		(
			parent "ManagedElement=$managedElement,SwManagement=1"
			identity "$LoadModule"
			moType LoadModule
			exception none
			nrOfAttributes 1
			"productData" Struct
				nrOfElements 5
				"productNumber" String $productDataValue
				"productRevision" String $productDataValue
				"productName" String $productDataValue
				"productInfo" String $productDataValue
				"productionDate" String $productDataValue
			"loadModuleFilePath" String $LTENAME
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$loadModuleCounter++;
	}

	foreach $upgradePackageName (@upgradePackageNames) {
		@MOCmds=();
                #CXP 903 0491-194-1
		if($upgradePackageName==1){
                        @MOCmds=qq^ CREATE
			(
			parent "ManagedElement=$managedElement,SwManagement=1"
			identity "$upgradePackageName"
			moType UpgradePackage
			exception none
			nrOfAttributes 1
			"loadModuleList" Array Ref 3
				"ManagedElement=$managedElement,SwManagement=1,LoadModule=aal0_dynamic"
				"ManagedElement=$managedElement,SwManagement=1,LoadModule=equipmp"
				"ManagedElement=$managedElement,SwManagement=1,LoadModule=etm4v2atm"^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                }
                else {
                my @upgradePackageFields = split /_/, $upgradePackageName; 
                @MOCmds=qq^ CREATE
                        (
                        parent "ManagedElement=$managedElement,SwManagement=1"
                        identity "$upgradePackageName"
                        moType UpgradePackage
                        exception none
                        nrOfAttributes 2
                        "upgradePackageDocumentId" String $upgradePackageName
                        "administrativeData" Struct
                                nrOfElements 5
                                "productNumber" String $upgradePackageFields[0]
                                "productRevision" String $upgradePackageFields[1]
                                "productName" String $upgradePackageName
                                "productInfo" String $upgradePackageName
                                "productionDate" String $pdkdate
                         "loadModuleList" Array Ref 3
                                "ManagedElement=$managedElement,SwManagement=1,LoadModule=aal0_dynamic"
                                "ManagedElement=$managedElement,SwManagement=1,LoadModule=equipmp"
                                "ManagedElement=$managedElement,SwManagement=1,LoadModule=etm4v2atm"^;# end @MO
                $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
                }
		for my $i ( 0 .. 100 ) {
			my $loadModuleIndex = 5 + $i;
			@MOCmds=();
			@MOCmds=qq^
				"ManagedElement=$managedElement,SwManagement=1,LoadModule=$LoadModuleList[$loadModuleIndex]"^;# end @MO
			$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		}
		@MOCmds=();
		@MOCmds=qq^
			"state" Integer 7
			userLabel String "$upgradePackageName"
		)
		^;# end @MO
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
	}
	# Remove the UpgradePackages that are specific to this node, so that the count remains constant when the new node's UpgradePackages are added.
	for my $i ( 0 .. ($nodeSpecificUpgradePackagesCount-1) ) {
		pop @upgradePackageNames;
	}

	@MOCmds=();
	@MOCmds=qq^ SET
	(
		mo "ManagedElement=$managedElement,SwManagement=1,ConfigurationVersion=1"
		identity "1"
		exception none
		"currentUpgradePackage" Ref "ManagedElement=$managedElement,SwManagement=1,UpgradePackage=1"
		"ConfigurationVersionId" String "007"
		"configAdmCountdown" Integer 130
		"configOpCountdown" Integer 10
		"currentLoadedConfigurationVersion" String "CXPENM1201Loaded"
		"executingCv" String "CXPENM1201executing"
		"lastCreatedCv" String "CXPENM1201Yesterday"
		"listOfHtmlResultFiles" Array String "CXPENM120130S"
		"restoreConfirmationDeadline" String "CXPENM1201"
		"rollbackInitCounterValue" Integer 5
		"rollbackInitTimerValue" Integer 30
		"rollbackList" Array String CXPENM101
		"startableConfigurationVersion" String "CXPENM100"
		"timeForAutoCreatedCV" String "10:00"
		"userLabel" String "BakupInventoryforENM"
		"storedConfigurationVersions" Array Struct $numOfStoredConfigVersions

	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   #CXP 903 0491-281-1
   @MMLtoFetchUPGid=();
   @MMLtoFetchUPGid=(".open ".$SIMNAME,
                     ".select ".$LTENAME,
                     ".start ",
                     "e: csmo:ldn_to_mo_id(null,[\"ManagedElement=1\",\"SwManagement=1\",\"UpgradePackage=1\"])."
                     );# end @MMLtoFetchUPGid
                     $NETSIMMMLtoFetchUPGid=&makeMMLscript("append",$MMLSCRIPTtoFetchUPGid,@MMLtoFetchUPGid);

           # execute mml script
           @netsim_output_toFetchUPGid=`$NETSIM_INSTALL_PIPE < $NETSIMMMLtoFetchUPGid`;
           chomp($netsim_output_toFetchUPGid[-1]);

        @storedConfigVersionAttributes=("backuptest","someidentity","STANDARD","$netsim_output_toFetchUPGid[-1]","shmtest","someComment","Thu Jun 21 17:32:05 2007","OK");

	@MOCmds=();
	local $storedConfigVersioncounter=1;

	while ($storedConfigVersioncounter<=$numOfStoredConfigVersions) {

		my $storedConfigVersionName;
		if ($storedConfigVersioncounter == $rvSwitchOfStoredConfigVersions) {
			@storedConfigVersionAttributes=("1","someidentity","STANDARD","$netsim_output_toFetchUPGid[-1]","shmtest","someComment","Thu Jun 21 17:32:05 2007","OK");
		}

		@storedConfigVersionAttributeNamesForRV = ("","","","","","","","", "CXPENM100", "CXPENM101", "CXPENM1201", "CXPENM1201Yesterday", "CXPENM1201executing", "CXPENM1201Loaded");
		$storedConfigVersionName = $storedConfigVersionAttributes[0];

		if ($storedConfigVersionAttributes[0] == "backuptest") {
			$storedConfigVersionName = "$storedConfigVersionAttributes[0]$storedConfigVersioncounter";
		}

		if ($storedConfigVersioncounter > $rvSwitchOfStoredConfigVersions) {
			$storedConfigVersionName = $storedConfigVersionAttributeNamesForRV[$storedConfigVersioncounter-1];
		}

		@MOCmds=();
		# build mo script
		@MOCmds=qq^        nrOfElements 8
			"name" String '$storedConfigVersionName'
			"identity" String '$storedConfigVersionAttributes[1]'
			"type" String '$storedConfigVersionAttributes[2]'
			"upgradePackageId" String '$storedConfigVersionAttributes[3]'
			"operatorName" String '$storedConfigVersionAttributes[4]'
			"operatorComment" String '$storedConfigVersionAttributes[5]'
			"date" String '$storedConfigVersionAttributes[6]'
			"status" String '$storedConfigVersionAttributes[7]'
		^;# end @MOCmds
		$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);
		$storedConfigVersioncounter++;
	}# end while

	@MOCmds=();
	@MOCmds=qq^
	)
	^;# end @MO
	$NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

	push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);


	################################################
	# build mml script
	################################################
	@MMLCmds=(
		".open ".$SIMNAME,
		".select ".$LTENAME,
		".start ",
		"useattributecharacteristics:switch=\"off\"; ",
		"kertayle:file=\"$NETSIMMOSCRIPT\";"
	);# end @MMLCmds
	$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);

	$NODECOUNT++;
}# end outer while

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
#unlink "$NETSIMMMLSCRIPT";
unlink "$NETSIMMMLtoFetchUPGid";
print "... ${0} ended running at $date\n";
################################
# END
################################
