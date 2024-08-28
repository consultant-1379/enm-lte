#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Version1    : LTE17.9
# Revision    : CXP 903 0491-293-1
# JIRA        : NSS-11918
# Purpose     : Cipher Support for ERBS nodes.
# Description : Sets Cipher Support on ERBS Nodes
# Date        : May 2017
# Who         : xmitsin
####################################################################
# Version2    : LTE17.13
# Revision    : CXP 903 0491-303-1
# JIRA        : NSS-13526
# Purpose     : Update RealTimeSecLog attribute for ERBS nodes.
# Description : Sets the RealTimeSecLog attributes to real node values
# Date        : July 2017
# Who         : xharidu
####################################################################

# Env
####################
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

# check if SIMNAME is of type PICO or DG2
if (&isSimPICO($SIMNAME)=~m/YES/ || &isSimDG2($SIMNAME)=~m/YES/){exit;}
# end verify params and sim node type
#----------------------------------------------------------------
local $date=`date`,$pdkdate=`date '+%FT%T'`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS",$SIMNAME);
local $FTPDIR=&getENVfilevalue($ENV,"FTPDIR");
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
while ($NODECOUNT<=$NUMOFRBS){# start outer while

    $LTENAME=&getLTESimStringNodeName($LTE,$NODECOUNT);
    $MIMVERSION=&queryMIM($SIMNAME,$NODECOUNT);

        @MOCmds=();
        @MOCmds=qq^ SET
(
    mo "ManagedElement=1,SystemFunctions=1,Security=1,RealTimeSecLog=1"
    exception none
    nrOfAttributes 2
    "extServerListInfo" Array Struct 1
        nrOfElements 5
        "connectionStatusInfo" String "[ 0..255 ]"
        "serverName" String "[ 0..255 ]"
        "extServerAddress" String "[ 0..255 ]"
        "extServProtocol" Integer 0
        "connectionStatus" Integer 2

    "extServerListConfig" Array Struct 1
        nrOfElements 3
        "serverName" String "[ 0..255 ]"
        "extServProtocol" Integer 0
        "extServerAddress" String "[ 0..255 ]"

)

SET
(
    mo "ManagedElement=1,SystemFunctions=1,Security=1,RealTimeSecLog=1"
    exception none
    nrOfAttributes 8
    "RealTimeSecLogId" String "1"
    "extServerListConfig" Array Struct 0
    "featureState" Integer 0
    "licenseState" Integer 1
    "connAttemptTimeOut" Integer 10
    "extServerListInfo" Array Struct 0
    "extServerAppName" String "Ericsson"
    "extServerLogLevel" Integer 7
)
SET
(
    mo "ManagedElement=1,SystemFunctions=1,Security=1,Ssh=1"
    // moid = 137
    exception none
    nrOfAttributes 6
    "supportedKeyExchange" Array String 10
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
        "ecdh-sha2-nistp256"
        "diffie-hellman-group-exchange-sha256"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group14-sha256"
        "diffie-hellman-group14-sha1"
        "diffie-hellman-group-exchange-sha1"
        "diffie-hellman-group1-sha1"
    "supportedCipher" Array String 9
        "aes256-gcm\@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-gcm\@openssh.com"
        "aes128-ctr"
        "AEAD_AES_256_GCM"
        "AEAD_AES_128_GCM"
        "aes128-cbc"
        "3des-cbc"
    "supportedMac" Array String 5
        "hmac-sha2-256"
        "hmac-sha2-512"
        "hmac-sha1"
        "AEAD_AES_128_GCM"
        "AEAD_AES_256_GCM"
    "selectedKeyExchange" Array String 10
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
        "ecdh-sha2-nistp256"
        "diffie-hellman-group-exchange-sha256"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group14-sha256"
        "diffie-hellman-group14-sha1"
        "diffie-hellman-group-exchange-sha1"
        "diffie-hellman-group1-sha1"
    "selectedCipher" Array String 9
        "aes256-gcm\@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-gcm\@openssh.com"
        "aes128-ctr"
        "AEAD_AES_256_GCM"
        "AEAD_AES_128_GCM"
        "aes128-cbc"
        "3des-cbc"
    "selectedMac" Array String 5
        "hmac-sha2-256"
        "hmac-sha2-512"
        "hmac-sha1"
        "AEAD_AES_128_GCM"
        "AEAD_AES_256_GCM"
)

SET
(
    mo "ManagedElement=1,SystemFunctions=1,Security=1,Tls=1"
    // moid = 136
    exception none
    nrOfAttributes 3
    "supportedCipher" Array Struct 49
        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-ECDSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA384"
        "name" String "ECDHE-RSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA384"
        "name" String "ECDHE-ECDSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-DSS-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-RSA-AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-DSS-AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-DSS-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "AEAD"
        "name" String "ECDH-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "AEAD"
        "name" String "ECDH-ECDSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA384"
        "name" String "ECDH-RSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA384"
        "name" String "ECDH-ECDSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "AEAD"
        "name" String "AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA256"
        "name" String "AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-ECDSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA256"
        "name" String "ECDHE-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA256"
        "name" String "ECDHE-ECDSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-DSS-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-DSS-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-DSS-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "AEAD"
        "name" String "ECDH-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "AEAD"
        "name" String "ECDH-ECDSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA256"
        "name" String "ECDH-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA256"
        "name" String "ECDH-ECDSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "AEAD"
        "name" String "AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA256"
        "name" String "AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "EDH-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "EDH-DSS-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

    "cipherFilter" String "DEFAULT"
    "enabledCipher" Array Struct 49
        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-ECDSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA384"
        "name" String "ECDHE-RSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA384"
        "name" String "ECDHE-ECDSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-DSS-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-RSA-AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-DSS-AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-DSS-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "AEAD"
        "name" String "ECDH-RSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "AEAD"
        "name" String "ECDH-ECDSA-AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA384"
        "name" String "ECDH-RSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA384"
        "name" String "ECDH-ECDSA-AES256-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "AEAD"
        "name" String "AES256-GCM-SHA384"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA256"
        "name" String "AES256-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "AES256-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "AEAD"
        "name" String "ECDHE-ECDSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA256"
        "name" String "ECDHE-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA256"
        "name" String "ECDHE-ECDSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-DSS-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "AEAD"
        "name" String "DHE-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA256"
        "name" String "DHE-DSS-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "DHE-DSS-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "AEAD"
        "name" String "ECDH-RSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "AEAD"
        "name" String "ECDH-ECDSA-AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA256"
        "name" String "ECDH-RSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA256"
        "name" String "ECDH-ECDSA-AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AESGCM"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "AEAD"
        "name" String "AES128-GCM-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA256"
        "name" String "AES128-SHA256"
        "protocolVersion" String "TLSv1.2"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "AES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "AES128-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH"
        "mac" String "SHA1"
        "name" String "ECDHE-ECDSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "EDH-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aDSS"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kDH"
        "mac" String "SHA1"
        "name" String "EDH-DSS-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH/RSA"
        "mac" String "SHA1"
        "name" String "ECDH-RSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aECDH"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kECDH/ECDSA"
        "mac" String "SHA1"
        "name" String "ECDH-ECDSA-DES-CBC3-SHA"
        "protocolVersion" String "SSLv3"

        nrOfElements 7
        "authentication" String "aRSA"
        "encryption" String "3DES"
        "export" String ""
        "keyExchange" String "kRSA"
        "mac" String "SHA1"
        "name" String "DES-CBC3-SHA"
        "protocolVersion" String "SSLv3" 
)

^;# end @MO
   $NETSIMMOSCRIPT=&makeMOscript("append",$MOSCRIPT.$NODECOUNT,@MOCmds);

   push(@NETSIMMOSCRIPTS, $NETSIMMOSCRIPT);

  ################################################
  # build mml script
  ################################################
  @MMLCmds=(".open ".$SIMNAME,
            ".select ".$LTENAME,
            ".start ",
            "useattributecharacteristics:switch=\"off\"; ",
            "kertayle:file=\"$NETSIMMOSCRIPT\";",
            ".sleep 5"
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
print "... ${0} ended running at $date\n";
################################
# END
################################

