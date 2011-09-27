#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Net::NS::Update' ) || print "Bail out!
";
	use_ok( 'Net::NS::Update::nsupdate' ) || print "Bail out!
";
}

diag( "Testing Net::NS::Update " .
      "$Net::NS::Update::VERSION, Perl $], $^X" );
