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
		'lib/Net/Bind9/Update.pm' => 'blib/man3/Net::Bind9::Update.3pm'
	},

	PM => {
		'lib/Net/Bind9/Update.pm' => '$(INST_LIBDIR)/Update.pm'
	},

	PREREQ_PM => {
		'Test::More' => 0,
	},
);

