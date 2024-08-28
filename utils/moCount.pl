#!/usr/bin/perl
####################################################################
# Version     : LTE 16.7
# Revision    : CXP 903 0491-206-1
# Jira        : NSS-1615
# Purpose     : Calculate the total number of MOs in LTE simulations
# Description : Creates a report that contains a count of every MO in
#               LTE simulations, the total MO count per each of the
#               simulations, and a grand total of MOs in the network.
# Date        : 13 Jan 2016
# Who         : edalrey
####################################################################
#####################
#   Imports         #
#####################
use strict;
use warnings;
use feature qw(say);
use FindBin qw($Bin);
use lib "$Bin/../lib/cellconfig";
use LTE_General;
#####################
#   Variables       #
#####################
my $netsimDir="/netsim/netsimdir/";
my $currentDir=`pwd`;
$currentDir=~s/^\s+|\s+$//g;
my $reportName="MoCountReport.txt";
#####################
#   Subroutines     #
#####################
sub removeMoReport {
    my $reportFullPath = "$currentDir/$reportName";
    if (-e $reportFullPath) {
        say "INFO: The report $reportFullPath already exists";
        unlink "$reportFullPath";
        say "INFO: The report $reportFullPath has been removed";
    }
}

sub getArrayOfSimulations {
    opendir(DIR, $netsimDir) or die $!;
    my @sims=();
    while (my $file = readdir(DIR)) {
        next unless (($file =~ m/^LTE/) && !($file =~ /zip/));
        push(@sims,$file);
    }
    return \@sims;
}

sub removeMml {
    my ($script)=@_;
    my $mmlFullPath="$currentDir/$script.mml";
    if (-e $mmlFullPath) {
        say "INFO: The file $mmlFullPath already exists";
        unlink "$mmlFullPath";
        say "INFO: The file $mmlFullPath has been removed";
    }
}

sub createSimMml {
    my ($sim)=@_;
    my $date=`date`;
    chomp $date;
    my @MMLCmds=(
        "# ".$date,
        ".open ".$sim,
        ".select network",
        ".start",
        "dumpmotree:count;"
    );
    my $simMmlName=$sim.".mml";
    my $NETSIMMMLSCRIPT=&makeMMLscript("append",$simMmlName,@MMLCmds);
    say "INFO: The file $simMmlName has been created";
    return $NETSIMMMLSCRIPT;
}

sub runMml {
    my ($NETSIMMMLSCRIPT) = @_;
    my @netsim_output=`/netsim/inst/netsim_pipe < $NETSIMMMLSCRIPT`;
    return \@netsim_output;
}

sub getTotalNodeCountPerSim {
    my ($simOutputRef)=@_;
    my @output=@{$simOutputRef};

    my $startKeyword = "dumpmotree:count";
    my $start=&getIndexOf($startKeyword, 0, @output);
    my $end=scalar(@output);

    my $totNodeCount=0;
    for my $node (++$start .. --$end) {
        my $nodeAndCount=$output[$node];
        $nodeAndCount=~ s/^\s+|\s+$//g;
        if( "" ne $nodeAndCount ) {
            &printToFile("\t\t\t\t\t\t".$nodeAndCount);
            my $count=&getCountFromDumpMoTreeCount($nodeAndCount);
            $totNodeCount+=( defined $count && $count ne "") ? $count : 0;
        }
    }
    return $totNodeCount;
}

sub getIndexOf {
    my ($searchTerm,$startIndex,@array)=@_;
    my $index=$startIndex;
    ++$index until $array[$index] =~ $searchTerm or $index > $#array;
    return $index;
}

sub getCountFromDumpMoTreeCount {
    my ($dumpMoTreeCount)=@_;
    my @tokens=split(':', $dumpMoTreeCount);
    return $tokens[1];
}

sub printToFile {
    my ($string)=@_;
    open(my $fh, '>>', $reportName) or die "Could not open file '$reportName' $!";
    say $fh "$string";
    close $fh;
}

sub addReportHeader {
    &printToFile("###################################################################");
    &printToFile("#                                                                 #");
    &printToFile("#                 MO COUNT FOR LTE SIMULATIONS                    #");
    &printToFile("#                                                                 #");
    &printToFile("###################################################################");
    &printToFile("");
    &printToFile("Simulation Name:\t\tNode Name:\t\tMO Count:");
}

sub addSummary {
    my (%simCounts)=@_;
    &printToFile("");
    &printToFile("###################################");
    &printToFile("#     Summary of LTE Simulations  #");
    &printToFile("###################################");
    &printToFile("Simulation Name:\t\t\tMO Count:");
    &printToFile("$_\n\t\t\t\t\t\t\t$simCounts{$_}\n") for (keys %simCounts);
    &printToFile("--------------------------------------------------");
    my $value=0;
    $value+=$simCounts{$_} for (keys %simCounts);
    &printToFile("NETWORK TOTAL:\t\t\t\t$value");
}

sub addReportFooter {
    &printToFile("###################################################################");
    &printToFile("#                     END                                         #");
    &printToFile("###################################################################");
}

sub generateReport {
    my @sims=@{&getArrayOfSimulations()};

    &addReportHeader();

    my %simCounts;
    foreach my $sim (@sims) {
        &removeMml($sim);
        my $NETSIMMMLSCRIPT=&createSimMml($sim);
        my $simOutputRef=&runMml($NETSIMMMLSCRIPT);
        &removeMml($sim);

        &printToFile($sim);
        my $simCount=&getTotalNodeCountPerSim($simOutputRef);
        $simCounts{$sim}=$simCount;
    }
    &addSummary(%simCounts);
    &addReportFooter();
}

sub stopAllNodesOnServer {
    my @MMLCmds=(
        ".server stop all"
    );
    my $stopMmlName="stopAllNodes.mml";
    my $NETSIMMMLSCRIPT=&makeMMLscript("append",$stopMmlName,@MMLCmds);
    say "INFO: The file $stopMmlName has been created";
    return $NETSIMMMLSCRIPT;
}
#####################
#   Main script     #
#####################
print "...${0} started running at ".`date`;
&removeMoReport();
&generateReport();
print "...${0} ended running at ".`date`;
#####################
#   End             #
#####################
