#!/usr/bin/perl
####################################################################
# version1    : LTE 16A
# Revision    : CXP 903 0491-161-1
# Jira        : NETSUP-3085
# purpose     : Test script for cell pattern derivation algorithm
# description : implements Test script for cell pattern derivation algorithm
# date        : June 2015
# who         : Ercan O'Grady
####################################################################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use LTE_General;
use LTE_CellConfiguration;
use strict;



my $CELLRATIOS = &getENVfilevalue("CONFIG.env","CELLRATIOS");
my @CELLPATTERN = &getCellPattern($CELLRATIOS);

my %cellPatternHash = ();
foreach (@CELLPATTERN) {
    $cellPatternHash{$_}++;
}

print "@CELLPATTERN\n";

for my $key (sort {$b <=> $a} keys %cellPatternHash) {
    print "$key => $cellPatternHash{$key}\n";
}
