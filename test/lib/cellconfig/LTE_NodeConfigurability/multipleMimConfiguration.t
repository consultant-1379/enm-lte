#!/usr/bin/perl
####################
# imports
####################
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Test::More tests => 21;
use LTE_NodeConfigurability;
####################
# set up
####################
my $simWithOneMim="LTE15B-V13x160-RV-DG2-FDD-LTE19";
my $simWithTwoMims="LTE15B-V13x120_15B-V9x40-RV-DG2-FDD-LTE19";
my $simWithThreeMims="LTE15B-V13x60_15B-V9x60_15B-V6-1x40-RV-DG2-FDD-LTE19";
my ($ref1,$ref2);
my (@arr1, @arr2);
####################

is(&verifyMimVersionSumToTotalNumberOfNodes($simWithOneMim,160),1,          "Sum of nodes in $simWithOneMim is 160");
is(&verifyMimVersionSumToTotalNumberOfNodes($simWithTwoMims,160),1,         "Sum of nodes in $simWithTwoMims is 160");
is(&verifyMimVersionSumToTotalNumberOfNodes($simWithThreeMims,160),1,       "Sum of nodes in $simWithThreeMims is 160");
is(@test=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithOneMim), 2,    "$simWithOneMim outputs 2 array refs");
is(@test=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithTwoMims), 2,   "$simWithTwoMims outputs 2 array refs");
is(@test=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithThreeMims), 2, "$simWithThreeMims outputs 2 array refs");

($ref1,$ref2)=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithOneMim);
@arr1=@$ref1, @arr2=@$ref2;
is((scalar @arr1)+(scalar @arr2) , 2,                                       "$simWithOneMim outputs 2 elements to arrays");
is($arr1[0] , "15B-V13",                                                    "element: $arr1[0] = \"15B-V13\"");
is($arr2[0] , "160",                                                        "element: $arr2[0] = \"160\"");


($ref1,$ref2)=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithTwoMims);
@arr1=@$ref1, @arr2=@$ref2;
is((scalar @arr1)+(scalar @arr2) , 4,                                       "$simWithTwoMims outputs 4 elements to arrays");
is($arr1[0] , "15B-V13",                                                    "element: $arr1[0] = \"15B-V13\"");
is($arr2[0] , "120",                                                        "element: $arr2[0] = \"120\"");
is($arr1[1] , "15B-V9",                                                     "element: $arr1[1] = \"15B-V9\"");
is($arr2[1] , "40",                                                         "element: $arr2[1] = \"40\"");

($ref1,$ref2)=&splitMimVersionsAndNodeCountsIntoTwoArrays($simWithThreeMims);
@arr1=@$ref1, @arr2=@$ref2;
is((scalar @arr1)+(scalar @arr2) , 6,                                       "$simWithThreeMims outputs 6 elements to arrays");
is($arr1[0] , "15B-V13",                                                    "element: $arr1[0] = \"15B-V13\"");
is($arr2[0] , "60",                                                         "element: $arr2[0] = \"60\"");
is($arr1[1] , "15B-V9",                                                     "element: $arr1[1] = \"15B-V9\"");
is($arr2[1] , "60",                                                         "element: $arr2[1] = \"60\"");
is($arr1[2] , "15B-V6-1",                                                   "element: $arr1[2] = \"15B-V6-1\"");
is($arr2[2] , "40",                                                         "element: $arr2[2] = \"40\"");
############################
# EOF
############################
