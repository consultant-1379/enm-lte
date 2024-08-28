#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : LTE 15.15
# Revision    : CXP 903 0491-176-1
# Jira        : NETSUP-3270
# Purpose     : Set sftp as file_dl and set user name/password as
#               netsim
# Description : Set setswinstallvariables:fileDl=sftp and set netsim
#               user and password for all node types
# Date        : Sept 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version2    : LTE 15.16
# Revision    : CXP 903 0491-181-1
# Jira        : NSS-320
# Purpose     : remove setswinstallvariables:fileDl=sftp for COM/ECIM
# Description : setswinstallvariables presently not supported in 
#               COM/ECIM nodes
# Date        : Oct 2015
# Who         : ejamfur
####################################################################
####################################################################
# Version3    : LTE 16.11
# Revision    : CXP 903 0491-230-1
# Jira        : NSS-4524
# Purpose     : To resolve LTE build error
# Description : Changing the filename to change the scripts
#               running order
# Date        : June 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version4    : LTE 19.05
# Revision    : CXP 903 0491-350-1
# Jira        : NSS-23445
# Purpose     : Setting user as netsim 
# Description : LTE Design Change: Netsim user setting is missing
#               on few Simulations while building              
# Date        : Feb 2019
# Who         : xmitsin
####################################################################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_General;
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
#----------------------------------------------------------------
local $date=`date`, $NETSIMMMLSCRIPT, $MMLSCRIPT;
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local @MMLCmds, @netsim_output;
local $dir=cwd,$currentdir=$dir."/";
local $MMLSCRIPT=$currentdir.${0}.".mml";
local $setSFTP="setswinstallvariables:fileDl=sftp;";

if((&isSimDG2($SIMNAME)=~m/YES/) || (&isSimPICO($SIMNAME)=~m/YES/)) { 
    $setSFTP=" ";
}

# build mml script
@MMLCmds=(".open ".${SIMNAME},
          ".select network",
          ".start ",
           $setSFTP
          
);# end @MMLCmds
$NETSIMMMLSCRIPT=&makeMMLscript("append",$MMLSCRIPT,@MMLCmds);
@netsim_output=`$NETSIM_INSTALL_PIPE < $NETSIMMMLSCRIPT`;

# output mml script execution
print "@netsim_output\n";

################################
# CLEANUP
################################
$date=`date`;
# remove mo script
unlink "$NETSIMMMLSCRIPT";
#------------------------------------------
# end determine External CDMA cell number
#------------------------------------------
print "... ${0} ended running at $date\n";
################################
# END
################################
