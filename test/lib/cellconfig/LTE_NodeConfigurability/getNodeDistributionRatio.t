#!/usr/bin/perl
####################
# imports
####################
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Test::More tests => 22;
use LTE_NodeConfigurability;
####################
# set up
####################
local $percentage;
local @expectedRatio;
####################
$percentage = 90;
@expectedRatio = (9,1);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 80;
@expectedRatio = (4,1);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 75;
@expectedRatio = (3,1);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 70;
@expectedRatio = (7,3);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 60;
@expectedRatio = (3,2);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 50;
@expectedRatio = (1,1);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 40;
@expectedRatio = (2,3);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 30;
@expectedRatio = (3,7);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 25;
@expectedRatio = (1,3);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 20;
@expectedRatio = (1,4);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");

$percentage = 10;
@expectedRatio = (1,9);
@actualRatio = &getNodeDistributionRatio($percentage);
is($actualRatio[0],$expectedRatio[0],"left ratio for $percentage: $expectedRatio[0]");
is($actualRatio[1],$expectedRatio[1],"right ratio for $percentage: $expectedRatio[1]");
############################
# EOF
############################
