#!/usr/bin/perl -Ilib -I../Net-Registry/lib

package Trudy;

use strict;
use warnings;
use Config::General;
use Net::Registry;
use Data::Dumper;

=head1 NAME

Trudy - The base modue for the Trudy testing suite

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Trudy;

    my $foo = Trudy->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 configure

Call this function to configure your environment

=cut

=head2 run

this starts the testing

=cut

sub connect {
    my $conf = shift;
    return Net::Registry::connect($conf);
}

sub run {
    my($conf) = @_;

    print STDERR Dumper($conf);
    my $sock = &connect($conf);
    foreach my $command (keys %{$conf->{commands}}){

        my $payload = {
            domain => 'blubb.co.nz',
        };

        $conf->{command} = $command;
        $conf->{payload} = $payload;

        Net::Registry::talk($conf, $sock);
    }

    my $sleep = int(rand($conf->{min_wait} - $conf->{max_wait})) + $conf->{min_wait};
    sleep $sleep;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trudy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Trudy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Trudy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Trudy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Trudy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Trudy>

=item * Search CPAN

L<http://search.cpan.org/dist/Trudy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Trudy
