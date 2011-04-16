use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Net::Bind9::Update::nsupdate',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	VERSION_FROM => 'lib/Net/Bind9/Update/nsupdate.pm',
	ABSTRACT_FROM => 'lib/Net/Bind9/Update/nsupdate.pm',
	LICENSE => 'perl',

	MAN3PODS => {
		'lib/Net/Bind9/Update/nsupdate.pm' => 
			'blib/man3/Net::Bind9::Update::nsupdate.3pm'
	},

	PM => {
		'lib/Net/Bind9/Update/nsupdate.pm' => 
			'$(INST_LIBDIR)/nsupdate.pm'
	},

	PREREQ_PM => {
		'Test::More' => 0,
	},
);

