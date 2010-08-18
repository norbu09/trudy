#!/usr/bin/perl

package Trudy::Plugins::SQLite;

use strict;
use warnings;
use Storable qw(freeze thaw);
use IO::Socket::UNIX;
use DBI;
use feature 'switch';

our $PORT = '/tmp/_trudy.sqlite.sock';

sub setup {
    unlink $PORT;
    my $conn = IO::Socket::UNIX->new(
        LocalAddr => $PORT,
        Type      => SOCK_STREAM,
        Listen    => 5
    ) or die $@;
    return $conn;
}

sub provide {
    my $type = shift;

    given($type) {
        when('handle') { return get_handle_data(); }
        when('domain') { return get_domain_data(); }
    }
    
    return "ERR: data type not found";

}

sub get_handle_data {
    return {
        firstname => 'Max',
        lastname => 'Mustermann',
        street => 'Wos Schoen is 4',
        city => 'Hintertupf',
        pcode => '12345',
        ccode => 'DE',
        phone => '+49.123456789',
        email => 'max@mustermann.de',
    };
}

sub get_domain_data {
    return {
        domain => 'muster.de',
        ns => [{host => 'ns1.muster.de', ip4 => '1.2.3.4'}, {host => 'ns1.dns.com'}, {host => 'ns2.dns.com'}],
    };
}

sub teardown {
    my $conn = shift;

    close $conn;
    unlink $PORT;
}

1;
