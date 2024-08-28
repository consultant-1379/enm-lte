#!/usr/bin/perl
### VERSION HISTORY
####################################################################
# Ver1        : Created
# Purpose     :
# Description :
# Date        : 26 July 2012
# Who         : Ercan O'Grady
####################################################################

####################
# Env
####################
use FindBin qw($Bin);
use lib "$Bin/../../lib/cellconfig";
use Cwd;
use LTE_Relations;
use LTE_CellConfiguration;
use LTE_General;
#use diagnostics;
####################
# Vars
####################
local @helpinfo=qq(Usage  : ${0} <sim name> <env file> <sim num>
Example: $0 LTEA90-ST-LTE01 R7-ST-K-ERBSA90.env 1);
local $SIMNAME="LTEC1110-ST-LTE01",$ENV="CONFIG.env",$LTE="1";
local $date=`date`,$LTENAME;
local $dir=cwd,$currentdir=$dir."/";
local $scriptpath="$currentdir";
local $overlap_file="$currentdir/../../log/overlap.csv";
local $interrelations_file="$currentdir/../../log/interrelations.csv";
local $proxies_file="$currentdir/../../log/proxies.csv";
local $NETSIM_INSTALL_PIPE="/netsim/inst/netsim_pipe";
local $MOSCRIPT="$scriptpath".${0}.".mo";
local $MMLSCRIPT="$scriptpath".${0}.".mml";
local @MOCmds,@MMLCmds,@netsim_output;
local $NETSIMMOSCRIPT,$NETSIMMMLSCRIPT,$NODECOUNT=1,$TYPE;
local $NETWORKCELLSIZE=&getENVfilevalue($ENV,"NETWORKCELLSIZE");
# get cell configuration ex: 6,3,3,1 etc.....
local $CELLPATTERN=&getENVfilevalue($ENV,"CELLPATTERN");
local @CELLPATTERN=split(/\,/,$CELLPATTERN);
local $NUMOFRBS=&getENVfilevalue($ENV,"NUMOFRBS");
local $NUMOF_FDDNODES=&getENVfilevalue($ENV,"NUMOF_FDDNODES");
# populate network grid with all cell data
local (@FULLNETWORKGRID)=&getAllNodeCells(2,1,$NETWORKCELLSIZE);
local (@PRIMARY_NODECELLS)=&buildNodeCells(@CELLPATTERN,$NETWORKCELLSIZE);

################################
# MAIN
################################
&buildNodeFrequencies(\@PRIMARY_NODECELLS);
$ref_to_CellRelations = &buildAllRelations(@PRIMARY_NODECELLS);
@CellRelations = @{$ref_to_CellRelations};
print "Finished building relations\n";


#for ($originating_cell=1; $originating_cell<@CellRelations; $originating_cell++) {
for ($originating_cell=1; $originating_cell<1000; $originating_cell++) {
    $number_of_cells_relating_to_originating_cell = @{$CellRelations[$originating_cell]};
	foreach $related_cell (@{$CellRelations[$originating_cell]}) {
        $number_of_common_relations = 0;
        @common_relations = ();
		#$times=grep(/$originating_cell/, @{$CellRelations[$related_cell]}); 
        	$times = 0;
        	foreach (@{$CellRelations[$related_cell]}) {
        		if ($originating_cell == $_) {
        			$times++;
        		}
        	}
		if ($times == 1) {
			#print "$originating_cell relates to $related_cell and the feeling is mutual\n";
		} elsif ($times == 0) {
			print "$originating_cell relates to $related_cell but it does not relate back\n";
		} else {
			print "$originating_cell relates to $related_cell but it relates back $times times\n";
		}
        $number_of_cells_relating_to_destination_cell = @{$CellRelations[$related_cell]};
        @common_relations = &intersection($CellRelations[$originating_cell], $CellRelations[$related_cell]);
        $number_of_common_relations = @common_relations;
        $percentage_common_for_cell_pair = ($number_of_common_relations/$number_of_cells_relating_to_originating_cell)*100;
        $rounded_percentage = int($percentage_common_for_cell_pair);
        $overlap{$rounded_percentage}++;
	}
}

if (! open OVERLAP, "> $overlap_file") {
    die "Cannot create $overlap_file: $!";
}
print OVERLAP "Percentage Overlap, Frequency\n";
foreach (keys %overlap) {
    print OVERLAP "$_, $overlap{$_}\n";
}
close OVERLAP;


for ($node=1; $node<=@PRIMARY_NODECELLS-1; $node++) {
	@cells_in_node=@{$PRIMARY_NODECELLS[$node]};
	foreach (@cells_in_node) {
		$numrelations=@{$CellRelations[$_]};
        $intereutranrelations{$numrelations}++;
        #print "Cell $_ in node $node has $numrelations relations\n";
#		print "Those realtions are @{$CellRelations[$_]}\n";
		$total_numrelations=$total_numrelations+$numrelations;
	}
}

if (! open INTERRELATIONS, "> $interrelations_file") {
    die "Cannot create $interrelations_file: $!";
}
print INTERRELATIONS "Number of Relations, Frequency\n";
foreach (keys %intereutranrelations) {
    print INTERRELATIONS "$_, $intereutranrelations{$_}\n";
}
close INTERRELATIONS;


$test=@PRIMARY_NODECELLS-1;
for ($node=1; $node<=$test; $node++) {
	@node_related_cells=();
	foreach $cell (@{$PRIMARY_NODECELLS[$node]}) {
		$ref_to_node_related_cells=\@node_related_cells;
		@node_related_cells=&union($ref_to_node_related_cells, $CellRelations[$cell]);
	}
	$num_node_related_cells=@node_related_cells;
	$total_proxies=$total_proxies+$num_node_related_cells;
    $proxies{$num_node_related_cells}++;
    #print "Node $node has $num_node_related_cells proxies\n";
}

if (! open PROXIES, "> $proxies_file") {
    die "Cannot create $proxies_file: $!";
}
print PROXIES "Number of Relations, Frequency\n";
foreach (keys %proxies) {
    print PROXIES "$_, $proxies{$_}\n";
}
close PROXIES;

$average_proxies=$total_proxies/@PRIMARY_NODECELLS;
print "Average proxies is $average_proxies\n";
$average_numrelations=$total_numrelations/@CellRelations;
print "Average inter relations is $average_numrelations\n";

# get the union of two arrays. pass two array refs to this
sub union {
	%union=();
	@a=@{$_[0]};
	@b=@{$_[1]};
	foreach (@a) { $union{$_} = 1 }
	foreach (@b) { $union{$_} = 1 }
	@union = keys %union;
	return(@union)
}
# get the intersection of two arrays. pass two array refs to this
sub intersection {
    @intersection = ();
	%intersection=();
	@a=@{$_[0]};
	@b=@{$_[1]};
	foreach (@a) { $intersection{$_} = 1 }
	foreach (@b) { 
        if ($intersection{$_} == 1) {
            push (@intersection, $_);
            $intersection{$_} = 2;
        }
        $intersection{$_} = 1;
    }
	return(@intersection)
}

@Related_Cells = &getInterEUtranCellRelations(229, $ref_to_CellRelations); 
print "Cells related to Cell 229 are @Related_Cells\n";
