#!/usr/bin/perl

package Trudy::Registry::NZRS::EPP;

use strict;
use warnings;
use Carp;
use Switch;
use File::ShareDir 'module_dir';
use IO::Socket::SSL qw(inet4);
use Template::Alloy;
use XML::LibXML::Simple qw(XMLin);
use Data::Dumper;
use FindBin;

=head1 NAME

Trudy::Registry::NZRS::EPP - EPP libraries for the NZRS EPP interface

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

Quick summary of what the module does.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 connect

This function connects to the EPP server, reads the greeting
and returns the socket.

=cut

sub connect {
    my ( $_pkg, $conf ) = @_;

    my $client;
    print STDERR Dumper($conf) if $conf->{debug};

    if ( $conf->{account}->{ssl_cert} ) {
        my $cert;
        my $key;
        if(-f $conf->{account}->{ssl_cert}){
            $cert = $conf->{account}->{ssl_cert};
            $key = $conf->{account}->{ssl_key};
        } elsif (-f $FindBin::Bin.'/../'.$conf->{account}->{ssl_cert}){
            $cert = $FindBin::Bin.'/../'.$conf->{account}->{ssl_cert};
            $key = $FindBin::Bin.'/../'.$conf->{account}->{ssl_key};
        } else {
            die "Could not find SSL CERT file!";
        }
        $client = new IO::Socket::SSL(
            PeerAddr => $conf->{account}->{host},
            PeerPort => $conf->{account}->{port} || 700,

            #LocalAddr     => $conf->{myip},
            Blocking      => 1,
            SSL_key_file  => $key,
            SSL_cert_file => $cert,
            SSL_use_cert  => 1,
        );
    }
    else {
        $client = new IO::Socket::SSL(
            PeerAddr => $conf->{account}->{host},
            PeerPort => $conf->{account}->{port} || 700,

            #LocalAddr => $conf->{myip},
            Blocking => 1,
        );
    }
    carp "Could not open socket: " . IO::Socket::SSL::errstr() . "\n"
      unless defined $client;

    my $greet;
    my $length = 0;
    my $read;

    print STDERR "Got a socket...\n" if $conf->{debug};

    # read lentgh (in Bytes)
    read( $client, $read, 4 );
    $length = unpack( "N", $read );
    print STDERR "Got a length ($length)...\n" if $conf->{debug};
    $length -= 4;    # the length bit itself

    # read until $length bytes read
    while ( $length > 0 ) {
        $length -= read( $client, $read, $length );
        $greet .= $read;
    }

    if ( $conf->{debug} ) {
        print "greeting from the server:\n";
        print $greet;
        print "\n----------\n";
    }
    return { greet => $greet, sock => $client };
}

sub login {
    my ( $_pkg, $data, $sock ) = @_;

    $data->{command} = 'login';
    $data->{payload} = {
        user => $data->{account}->{user},
        pass => $data->{account}->{pass},
    };

    return talk( $_pkg, $data, $sock );
}

sub logout {
    my ( $_pkg, $data, $sock ) = @_;

    $data->{command} = 'logout';

    return Trudy::Registry::talk( $data, $sock );
}

=head2 talk

This is the only public function and it only expects the data to be sent
and the config values. It returns the data structures we got back from
the EPP server. There is no normalization done in the moment so all the
responses are just plain perl hashs.

=cut

sub talk {
    my ( $_pkg, $data, $sock ) = @_;

    print STDERR Dumper($data) if $data->{debug};

    #print STDERR Dumper($sock) if $data->{debug};

    my $tpl = _template($data);
    print "Template: \n" if $data->{debug};
    print "$tpl \n"      if $data->{debug};
    my $res = _send( $sock, $tpl, $data );
    print "raw response: \n" if $data->{debug};
    print "$res \n"          if $data->{debug};
    my $hash = _parse($res);
    print "parsed response: \n" if $data->{debug};
    print Dumper($hash) if $data->{debug};
    return $hash;
}

sub normalize {
    my ($_pkg, $command, $data) = @_;

    switch($command){
        case 'createcontact' {return _filter_create_contact($data);}
        case 'createdomain' {return _filter_create_domain($data);}
    }
    return;
}

sub _filter_create_contact {
    my ($data) = @_;
    return unless $data->{response}->{result}->{code} == 1000;
    return $data->{response}->{resData}->{'contact:creData'}->{'contact:id'};
}

sub _filter_create_domain {
    my ($data) = @_;
    return unless $data->{response}->{result}->{code} == 1000;
    return $data->{response}->{resData}->{'domain:creData'}->{'domain:name'};
}

=head2 _template

This internal function parses the data structure into our XML template
and returns the full XML request.
It expects a 'template_path' config value with the path to the relevant
template tree.

=cut

sub _template {
    my ($data) = @_;
    $data->{payload}->{command} = $data->{command} . '.tt';
    $data->{payload}->{transaction_id} = time.'-trudy'
        unless $data->{payload}->{transaction_id};
    print STDERR Dumper($data) if $data->{debug};
     #my $t = Template::Alloy->new( DEBUG => 'DEBUG_ALL', INCLUDE_PATH => [ $data->{account}->{template_path}, module_dir(__PACKAGE__)."/share/NZRS/EPP" ], );
    my $t =
      Template::Alloy->new(
        INCLUDE_PATH => [ $data->{account}->{template_path} ] );
    my $template = '';
    $t->process( 'frame.tt', $data->{payload}, \$template ) || carp $t->error;
    print STDERR $template;
    return $template;
}

=head2 _send

This internal function uses a socket to the EPP server, 
then sends the XML template we want to send. The response
has the greeting, the response from the login and the response from the
command we ran.

=cut

sub _send {
    my ( $conn, $request, $conf ) = @_;

    my $client = $conn->{sock};
    print STDERR "SOCKET: $client\n";

    if ( $conf->{debug} ) {
        print "sending this template:\n";
        print $request;
        print "----------\n";
    }

    my $req = sprintf( "%s%s", _lE2bE( length($request) + 4 ), $request );
    print $client $req;

    my $stream;
    my $read;
    my $length = 0;

    # read lentgh (in Bytes)
    read( $client, $read, 4 );
    $length = unpack( "N", $read );
    $length -= 4;    # the length bit itself
    print "readning $length bytes ...\n" if $conf->{debug};

    # read until $length bytes read
    while ( $length > 0 ) {
        $length -= read( $client, $read, $length );
        $stream .= $read;
    }
    if ( $conf->{debug} ) {
        print "recieved this response:\n";
        print $stream;
        print "\n----------\n";
    }
    return $stream;
}

=head2 _lE2bE

This internal function converts little endian to big endian as network
byte order as defined in the EPP RFCs is normally not what we have on a
machine running this code base.

=cut

sub _lE2bE {
    my $number = shift;
    my ( $c, @numbers ) = (0);
    for ( my $c = 0 ; $c < 4 ; ++$c ) {
        push @numbers, $number % 256;
        $number >>= 8;
    }
    return
      sprintf( "%c%c%c%c", $numbers[3], $numbers[2], $numbers[1], $numbers[0] );
}

=head2 _parse

This internal function takes a XML snippet and parses it to a perl
structure. working with a perl hash is so much nicer that with plain XML

=cut

sub _parse {
    my $xml = shift;

    my $dump = XMLin($xml);
    return $dump;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Trudy::Registry::NZRS::EPP at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Trudy::Registry::NZRS::EPP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Trudy::Registry::NZRS::EPP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Trudy::Registry::NZRS::EPP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Trudy::Registry::NZRS::EPP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Trudy::Registry::NZRS::EPP>

=item * Search CPAN

L<http://search.cpan.org/dist/Trudy::Registry::NZRS::EPP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Trudy::Registry::NZRS::EPP
