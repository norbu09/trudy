#!/usr/bin/perl -Ilib

package Trudy::Registry;

use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Trudy::Registry - The great new Trudy::Registry!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Trudy::Registry;

    my $foo = Trudy::Registry->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub connect {
    my $req = shift;

    print STDERR "Connecting ...\n" if $req->{debug};
    my $LIB = _use($req);
    my $res;
    eval { $res = $LIB->connect($req) };
    return $@ || $res;
}

sub login {
    my $req = shift;

    print STDERR "Login ...\n" if $req->{debug};
    my $LIB = _use($req);
    my $res;
    unshift(@_, $req); 
    eval { $res = $LIB->login(@_) };
    return $@ || $res;
}

sub logout {
    my $req = shift;

    print STDERR "Logout ...\n" if $req->{debug};
    my $LIB = _use($req);
    my $res;
    unshift(@_, $req); 
    eval { $res = $LIB->logout(@_) };
    return $@ || $res;
}

sub talk {
    my $req = shift;

    print STDERR "Talking ...\n" if $req->{debug};
    my $LIB = _use($req);
    print STDERR "LIB: $LIB\n";
    my $res;
    unshift(@_, $req); 
    eval { $res = $LIB->talk(@_) };
    return $@ || $res;
}

sub _use {
    my $req = shift;
    carp "Error: You need to define a interface for your request"
      unless $req->{account}->{interface};
    my $LIB = 'Trudy::Registry::' . $req->{account}->{interface};
    eval "use $LIB";
    carp "Error: Could not find interface " . $req->{account}->{interface} . ": $@" if $@;
    return $LIB;
}

=head2 function2

=cut


=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-registry at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Trudy-Registry>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Trudy::Registry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Trudy-Registry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Trudy-Registry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Trudy-Registry>

=item * Search CPAN

L<http://search.cpan.org/dist/Trudy-Registry/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Trudy::Registry
