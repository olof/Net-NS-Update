use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Net::Bind9::Update',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	VERSION_FROM => 'lib/Net/Bind9/Update.pm',
	ABSTRACT_FROM => 'lib/Net/Bind9/Update.pm',
	LICENSE => 'perl',

	MAN3PODS => {
		'lib/Net/Bind9/Update.pm' => 
			'blib/man3/Net::Bind9::Update.3pm',
		'lib/Net/Bind9/Update/nsupdate.pm' => 
			'blib/man3/Net::Bind9::Update::nsupdate.3pm',
	},

	PREREQ_PM => {
		'Test::More' => 0,
	},
);

