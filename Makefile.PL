use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Net::NS::Update',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	VERSION_FROM => 'lib/Net/NS/Update.pm',
	ABSTRACT_FROM => 'lib/Net/NS/Update.pm',
	LICENSE => 'perl',

	MAN3PODS => {
		'lib/Net/NS/Update.pm' =>
			'blib/man3/Net::NS::Update.3pm',
		'lib/Net/NS/Update/nsupdate.pm' =>
			'blib/man3/Net::NS::Update::nsupdate.3pm',
	},

	PREREQ_PM => {
		'Test::More' => 0,
	},
);

