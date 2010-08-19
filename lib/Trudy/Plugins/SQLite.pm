#!/usr/bin/perl

package Trudy::Plugins::SQLite;

use vars qw(@ISA @EXPORT_OK $VERSION);

use strict;
use warnings;
use DBI;
use Exporter;
use feature 'switch';

$VERSION = 0.1;
@ISA = qw(Exporter);
@EXPORT_OK = qw(provide);

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
        street => 'Wos Schoen is 66f',
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


1;
