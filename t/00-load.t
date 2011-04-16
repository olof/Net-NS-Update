#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Net::Bind9::Update' ) || print "Bail out!
";
	use_ok( 'Net::Bind9::Update::nsupdate' ) || print "Bail out!
";
}

diag( "Testing Net::Bind9::Update " . 
      "$Net::Bind9::Update::VERSION, Perl $], $^X" );
