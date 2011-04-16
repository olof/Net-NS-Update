use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $tpcv = 1.08;
eval "use Test::Pod::Coverage $tpcv";
plan skip_all => "Test::Pod::Coverage $tpcv required for testing POD coverage"
	if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $pcv = 0.18;
eval "use Pod::Coverage $pcv";
plan skip_all => "Pod::Coverage $pcv required for testing POD coverage"
	if $@;

all_pod_coverage_ok(
	{ also_private => [qw/new/] }
);
