#!/usr/bin/perl
# VERSION HISTORY
####################################################################
# Version1    : ENM 17.2
# Revision    : CXP 903 0491-280-1
# Jira        : NSS-6295
# Purpose     : To create a Topology file
# Description : Creating a single txt file which contains information
#               of the LTE network topology
# Date        : Dec 2016
# Who         : xkatmri
####################################################################
####################################################################
# Version2    : ENM 18.09
# Revision    : CXP 903 0491-336-1
# Jira        : NSS-18370
# Purpose     : To modify Topology file creation logic
# Description : The already present code for topology file creation
#               is static in nature.Changes are made to make it
#               dynamic and run accordingly
# Date        : May 2018
# Who         : xravlat
####################################################################
####################################################################
# Version3    : ENM 19.12
# Revision    : CXP 903 0491-357-1
# Jira        : NSS-26165
# Description : Merge  EUtranCellRelation files into one
# Date        : July 2019
# Who         : xmitsin
####################################################################
####################################################################
## Version3    : ENM 19.12
## Revision    : CXP 903 0491-363-1
## Jira        : NSS-32043
## Description : TermPoinToMME Creation in Topology File
## Date        : Aug 2020
## Who         : xharidu
#####################################################################


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
local $date=`date`;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $topologyDirPath="$scriptpath";
$topologyDirPath=~s/bin.*/customdata\/topology\//;
local $topologyData = "$topologyDirPath/TopologyData.txt";
local $EUtranCell = "$topologyDirPath/EUtranCell.txt";
print "Merging both EUtranCellRelation files into one";
system ("cat $topologyDirPath/EUtranCellRelation*.txt > $topologyDirPath/EUtranCellRelation.txt");
local $EUtranCellRelation = "$topologyDirPath/EUtranCellRelation.txt";
local $UtranCellRelation = "$topologyDirPath/UtranCellRelation.txt";
local $TermPointToEnb = "$topologyDirPath/TermPointToEnb.txt";
local $TermPointToMme = "$topologyDirPath/TermPointToMme.txt";
local $GeranCellRelation = "$topologyDirPath/GeranCellRelation.txt";
local $tempFile = "$topologyDirPath/temp.txt";

#############
#Main
############
print "... ${0} started running at $date\n";


open(my $fh, '>', $topologyData);
print $fh "#########################################################\n";
print $fh "# TOPOLOGY DATA FOR $SIMNAME\n";
print $fh "#########################################################\n";

       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               EUtranCell Information\n";
       print $fh "#################################################################################################################\n";

arrange($EUtranCell);
#filter($EUtranCell);
       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               EUtranCellRelation Information\n";
       print $fh "#################################################################################################################\n";
arrange($EUtranCellRelation);
#filter($EUtranCellRelation);
       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               UtranCellRelation Information\n";
       print $fh "#################################################################################################################\n";
arrange($UtranCellRelation);
#filter($UtranCellRelation);
       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               TermPointToEnb Information\n";
       print $fh "#################################################################################################################\n";
arrange($TermPointToEnb);
#filter($TermPointToEnb);
       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               GeranCellRelation Information\n";
       print $fh "#################################################################################################################\n";
arrange($GeranCellRelation);
#filter($GeranCellRelation);

if(&isSimPICO($SIMNAME)=~m/NO/){ # runs only for DG2 and ERBS nodes
       print $fh "\n";
       print $fh "#################################################################################################################\n";
       print $fh "#                               TermPointToMme Information\n";
       print $fh "#################################################################################################################\n";
arrange($TermPointToMme);
#filter($TermPointToMme);
}

sub arrange {
my ($arrangefile) = @_;

open (INFILE, "$arrangefile") || die("Couldn't open file");;
       while (<INFILE>) {
         chomp $_; # removes \n chars from end of lines
         s/\s+//sg;
         s/\s+$//;
         if ( ($_=~m/parent/) || ($_=~m/identity/) || ($_=~m/moType/) ) { push(@copy,$_); }
       }
#      print"lets see the array @copy\n";
close (INFILE);

my $copySize = @copy;
my $loopcounter = $copySize / 3 ;
my $n = 0;

open(my $fh_temp, '>', $tempFile);

##For Grouping the required LDN of a Particular MO in form ManagedElement....<MO>..identity
while ($n < $loopcounter)
{
 print $fh_temp "$copy[3 * $n]$copy[(3 * $n ) + 2]$copy[(3 * $n) + 1]\n";
 $n = $n + 1;
}

close $fh_temp;
@copy = ();

filter($tempFile);
}


sub filter { #this will remove all the namspaces and unwanted kertayle data and copy it to Topology file

my ($file) = @_;

open (INFILE, "$file") || die("Couldn't open file");;




       while (<INFILE>) {
         chomp $_; # removes \n chars from end of lines
         s/^\s+//;  #removing starting spaces
         s/\s+$//;  #removing trailing spaces
         s/\s+//sg;  #removing spaces within
         s/"+//sg;  #removing quotes
         s/parent+//sg; #removing parent
         s/moType+/,/sg; #replacing moType with comma
         s/identity+/=/sg; #replacing identity with equalsto
         s/ComTop://sg;  #remove ComTop namespace
         s/Lrat://sg;  #remove Lrat namespace
         print $fh "$_\n"; # pushing data to topology file
      }
close (INFILE);

unlink "$tempFile";
}
close $fh;
print "... ${0} ended running at $date\n";
################################
# END
################################
