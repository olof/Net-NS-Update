#!/usr/bin/perl
# Net::NS::Update, Perl module to do dynamic updates for DNS zones
# 
# Copyright (c) 2011, Olof Johansson <olof@cpan.org> 
# All rights reserved.
# 
# This program is free software; you can redistribute it 
# and/or modify it under the same terms as Perl itself.  

=head1 NAME

Net::NS::Update - Perl module to do dynamic updates for DNS zones

=head1 SYNOPSIS

 my $update = Net::NS::Update->new(
         origin => 'example.com.',
	 ttl => 3600,
	 keyfile => '/etc/bind/session.key',
 );

=head1 DESCRIPTION

Update your dynamic zones directly from Perl. This module either wraps
the nsupdate program or uses Net::DNS to send authenticated UPDATE 
queries to the server, both using a single API. You start by adding 
instructions to the module, and then run execute.

=cut

package Net::NS::Update;
use feature qw/say/;
use warnings;
use strict;
use Carp;
use File::Temp qw/tempfile/;
our $VERSION = 0.1;

=head1 CONSTRUCTOR

 Net::NS::Update->new(
         origin=>'.',
         ttl=>3600,
         keyfile=>'/dev/null',
         timeout=>0,
         server=>'foobarbaz',
         port=>53535, 
         local=>0,
         datadir=>'/tmp',
         backend=>'DNS',
 );

=head2 Options

=head3 keyfile (required)

=head3 backend

Which backend to use when communicating with the server. Can either
be DNS or nsupdate. DNS will use Net::DNS to do UPDATE queries, 
while nsupdate will wrap the nsupdate program (which of course,
depends on its availability on the system). Only nsupdate is 
implemented yet. By not specifying this, the module will first try
the DNS module and then fall back to the nsupdate module.

=head3 origin

=head3 ttl

=head3 timeout

=head3 server

=head3 port

=head3 local

=head3 datadir

=cut

sub new {
	my $class = shift;

	my $self = { 
		origin=>'.',
		ttl=>3600,
		class=>'IN',
		local=>0,
		timeout=>300,
		silent=>0,
		datadir=>'.',

		@_,

		instructions => [],
	};

	if($class eq 'Net::NS::Update') {
		if(not defined $self->{backend}) {
			my %errs;
			if(eval {
				require Net::NS::Update::DNS;
			}) {
				$errs{dns} = $@;
				$class = 'Net::NS::Update::DNS';
			} elsif(eval {
				require Net::NS::Update::nsupdate;
			}) {
				$errs{nsupdate} = $@;
				$class = 'Net::NS::Update::nsupdate';
			} else {
				croak(<< "EOF" );
Could not load either of the backends:
DNS: $errs{dns}
nsupdate: $errs{nsupdate}

EOF
			}
		} elsif($self->{backend} eq 'DNS') {
		} elsif($self->{backend} eq 'nsupdate') {
			eval {
				require "Net::NS::Update::$self->{backend}"
			} or croak("Could not load backend: $@"); 
		} else {
			croak("Unknown backend: $self->{backend}");
		}
	}

	bless $self, $class;
}

=head1 METHODS

=head2 execute

Execute the instructions added using nsupdate, either using Net::DNS
or the nsupdate program. 

=cut

sub execute {
	my $self = shift;
	
	# weed out deleted instructions (see the undo method)
	my @instructions = grep {$_} @{$self->{instructions}};

	my($fh, $tmpfile) = tempfile(
		'nsupdate-XXXXXX', DIR=>$self->{datadir}
	) or do {
		$self->{error} = "Could not open tempfile: $!";
		return undef;
	};

	say $fh sprintf("server %s %s", 
		$self->{server}, $self->{port} // '' 
	) if $self->{server};
	
	say $fh sprintf("local %s %s", 
		$self->{server}, $self->{port} // '' 
	) if $self->{server};
	
	push @instructions, 'send';
	foreach(@instructions) {
		say $fh $_;
	}

	# Ceci n'est pas une pipe
	open(my $pipe, $self->_get_cmd($tmpfile) . '|') or do {
		$self->{error} = "Couldn't open pipe: $!";
		return undef;
	}; 

	while(<$pipe>) {
		# Treat all output from nsupdate as fatal errors.
		# bad? probably
		chomp;
		$self->{error} = $_;
		return undef;
	}
	close $pipe;
	unlink $tmpfile;
	
	# clear the list of instructions
	$self->{instructions} = [];

	return 1;
}

=head2 add

Add a record to the zone. 

 $update->add(
	name=>$label, 
	type=>$rrtype, 
	ttl=>3600, 
	class=>'IN',
	data=>$data,
 );

ttl and class are optional.

=cut

sub add {
	my $self = shift;
	my $args = { @_ };

	my $domain = $args->{name};
	my $type = $args->{type};
	my $data = $args->{data};
	my $ttl = $args->{ttl} // $self->{ttl};
	my $class = $args->{class} // $self->{class};

	unless($domain) {
		$self->{error} = "Domain was not supplied to add";
		return;
	}

	$domain = $self->fqdnize($domain);
	push @{$self->{instructions}}, sprintf("update add %s %d %s %s %s",
		$domain, $ttl, $class, $type, $data
	);
}

=head2 del

Delete a domain, rrset or rr from the zone.

 $update->del(
	name=>$label, 
	type=>$rrtype, 
	class=>'IN',
	data=>$data,
 );

Everything, except the name, is optional. No defaults will be used, 
unlike add.

=cut

sub del {
	my $self = shift;
	my $args = { @_ };

	my $domain = $self->fqdnize($args->{name});
	my $type = $args->{type};
	my $data = $args->{data};
	my $class = $args->{class};

	unless($domain) {
		$self->{error} = "Domain was not supplied to delete";
		return undef;
	}

	my $instruction = "update delete $domain ";

	if(defined $type) {
		$instruction .= "$type ";
		
		if(defined $data) {
			$instruction .= "$data";
		}
	}

	push @{$self->{instructions}}, $instruction;
}

=head2 list

Returns a list of the instructions that hasn't been sent to 
nsupdate yet. The index values of this array can be used as
argument to the undo method.

=cut

sub list {
	my $self = shift;

	return @{$self->{instructions}};
}

=head2 undo

Before doing execute, you can delete an instruction. The 
argument is the array index, as seen when calling list.

=cut

sub undo {
	my $self = shift;
	my $n = shift;
	$self->{instructions}->[$n] = undef;
}

=head2 ttl

Sets or gets the default ttl set for new domains. Defaults to 3600.

=cut

sub ttl {
	my $self = shift;
	return $self->{ttl} unless @_;
	$self->{ttl} = shift;
}

=head2 class

Sets or gets the class used for new domains. 'IN' is the default.

=cut

sub class {
	my $self = shift;
	return $self->{origin} unless @_;
	$self->{origin} = shift;
}

=head2 origin

Sets or gets the origin domain (the domain appended to labels witout
trailing .). Defaults to ".". This will be treated as a fully 
qualified domain, even if you don't have a trailing ".". If you omit
the "." you will get a warning, but the dot will be appended anyways.

 $update->origin('example.com.');
 my $origin = $update->origin;

=cut

sub origin {
	my $self = shift;
	return $self->{origin} unless @_;
	my $origin = shift;

	unless($origin =~ /\.$/) {
		$origin .= '.';
	}

	$self->{origin} = shift;
}

=head2 error

Return the latest error message as a readable string.

=cut

sub error {
	my $self = shift; 
	return $self->{error};
}

=head1 INTERNAL METHODS

=head2 fqdnize

Helper method to make the domain fully qualified. This is done by 
appendning $self->origin to the domain unless it already ends with ".". 
This is primarily used internally by the module, but feel free to use 
it if you want to.

=cut

sub fqdnize {
	my $self = shift;
	my $label = shift;
	my $origin = $self->origin;
	return $label if $label =~ /\.$/;

	unless(defined $origin) {
		$self->{error} = "Non fully qualified domain $label";
		return undef;
	}

	return "$label." if $origin eq '.';
	return "$label.$origin"; 
}

sub _get_cmd {
	my $self = shift;
	my $tmpfile = shift;

	my $cmd = 'nsupdate ';

	$cmd .= "-t $self->{timeout} " if $self->{timeout};
	$cmd .= '-l '                  if $self->{local};
	$cmd .= "-k $self->{keyfile} " if $self->{keyfile};
	$cmd .= $tmpfile;

	say $cmd;
	return $cmd;
}

1;

=head1 

=head1 AVAILABILITY

Git repository (VCS) is available through Github:

 L<http://github.com/olof/Net-NS-Update>

=head1 SEE ALSO

=over

=item * nsupdate(1)

=item * Bind Administrator's Reference Manual, chapter 4, section 
        on dynamic updates

=back

=head1 COPYRIGHT

Copyright (c) 2011, Olof Johansson <olof@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.  

