#!/usr/bin/perl
# Net::NS::Update::nsupdate, Perl module wrapper for nsupdate
# 
# Copyright (c) 2011, Olof Johansson <olof@cpan.org> 
# All rights reserved.
# 
# This program is free software; you can redistribute it 
# and/or modify it under the same terms as Perl itself.  

=head1 NAME

Net::NS::Update::nsupdate - Net::NS::Update module for wrapping nsupdate

=head1 SYNOPSIS

 my $update = Net::NS::Update->new(
         origin => 'example.com.',
	 ttl => 3600,
	 keyfile => '/etc/bind/session.key',
	 backend => 'nsupdate',
 );

=head1 DESCRIPTION

Update your dynamic zones directly from Perl. This module is a simple
wrapper around the nsupdate program, distributed as part of Bind9. You
start by adding some instructions to the module, and then run execute.

=cut

package Net::NS::Update::nsupdate;
use feature qw/say/;
use warnings;
use strict;
use parent qw/Net::NS::Update/;
use Carp;
use File::Temp qw/tempfile/;
our $VERSION = 0.1;

=head1 METHODS

=head2 execute

Execute the instructions added using nsupdate. 

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

=head1 AVAILABILITY

Git repository (VCS) is available through Github:

 L<http://github.com/olof/Net-NS-Update>

=head1 SEE ALSO

=over

=item * Net::NS::Update

=item * nsupdate(1)

=item * Bind Administrator's Reference Manual, chapter 4, section 
        on dynamic updates

=back

=head1 COPYRIGHT

Copyright (c) 2011, Olof Johansson <olof@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.  

