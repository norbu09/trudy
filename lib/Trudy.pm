#!/usr/bin/perl -Ilib

package Trudy;

use strict;
use warnings;
use Config::General;
use Trudy::Registry;
use Data::Dumper;
use Trudy::Plugins::SQLite qw(archive preserve provide);
use Switch;
use List::Util 'shuffle';
use Carp;

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

=head2 setup

this starts the testing

=cut

sub setup {
    my $conf = shift;
    return Trudy::Registry::connect($conf);
}

sub run {
    my($conf) = @_;

    print STDERR Dumper($conf);
    my $sock = setup($conf);
    my $login = Trudy::Registry::login($conf, $sock);
    print STDERR Dumper($login) ;
    die "Could not log in: ".$login->{response}->{result}->{msg}->{content} 
        unless $login->{response}->{result}->{code} == 1000;
    my @_commands;
    foreach my $command (keys %{$conf->{commands}}){
        my $c = 0;
        while($c < $conf->{commands}->{$command}){
            push(@_commands, $command);
            $c++;
        }
    }
    my @commands = shuffle(@_commands);
    foreach my $command (@commands){
        #print "COMMAND: $command\n"; next;
        my $data_type = map_command_data($command);
        print STDERR "DATA TYPE: $data_type\n";
        croak "could not find a suitable data provider for the command: $command" unless $data_type;
        my $payload = provide($conf->{datastore}, $data_type);
        print STDERR Dumper($payload);

        $conf->{command} = $command;
        $conf->{payload} = $payload;

        my $res = Trudy::Registry::talk($conf, $sock);
        save_result($conf, $command, $res) if command_has_outcome($command);
        save($conf, $res);
        my $sleep = int(rand($conf->{min_wait} - $conf->{max_wait})) + $conf->{min_wait};
        sleep $sleep;
    }

    my $logout = Trudy::Registry::logout($conf, $sock);
}

sub save {
    my ($in, $out) = @_;

    print STDERR Dumper($out);
    archive($in->{datastore}, $in, $out);
}

sub save_result {
    my ($conf, $command, $result) = @_;
    my $res = Trudy::Registry::normalize($conf, $command, $result);
    if($res){
        preserve($conf->{datastore}, $command, $res);
    }
}

sub get_result_summary {
    my $datastore = shift;
    return Trudy::Plugins::SQLite::get_result_summary($datastore);
}

sub get_code_summary {
    my ($datastore, $code) = @_;
    return Trudy::Plugins::SQLite::get_code_summary($datastore, $code);
}

sub get_command_summary {
    my ($datastore, $command) = @_;
    return Trudy::Plugins::SQLite::get_command_summary($datastore, $command);
}

sub map_command_data {
    my $command = shift;
    
    switch($command) {
       case 'createcontact' {return 'contact';}
       case 'createdomain'  {return 'domain:reghandles';}
       case 'checkcontact'  {return 'handle';}
       case 'checkdomain'   {return 'domain';}
       case 'infocontact'   {return 'handle';}
       case 'infodomain'    {return 'systemdomain';}
       case 'deletecontact' {return 'handle';}
       case 'deletedomain'  {return 'systemdomain';}
    }
    return;
}

sub command_has_outcome {
    my $command = shift;
    
    switch($command) {
       case 'createcontact' {return '1';}
       case 'createdomain' {return '1';}
    }
    return;
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
