#!/usr/bin/perl

package Trudy::Plugins::SQLite;

use vars qw(@ISA @EXPORT_OK $VERSION);

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Exporter;
use Switch;
use Carp;
use Storable qw(freeze thaw);

$VERSION   = 0.1;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(archive provide);

sub setup {
    my $db  = shift;
    my $dsn = "DBI:SQLite:dbname=" . $db;
    my $dbh = DBI->connect($dsn) or croak "Could not open fuzzer database: $@";
    return $dbh;
}

sub archive {
    my ($db, $in, $out) = @_;

    print STDERR Dumper($in, $out);
    $Data::Dumper::Terse;
    my $_out = Dumper($out);
    $_out =~ s/'//g;
    my $_in = Dumper($in);
    $_in =~ s/'//g;
    my $dbh = setup($db->{db});
    my $insert = "INSERT INTO log ('ts', 'input', 'output', 'command', 'code', 'message') VALUES
    (".time.",'".$_in."','".$_out."','".$in->{command}."',".$out->{response}->{result}->{code}.",'".$out->{response}->{result}->{msg}->{content}."')";
    print STDERR "\n----\n";
    print STDERR $insert;
    print STDERR "\n----\n";
    $dbh->do($insert);
    print STDERR $dbh->errstr() if $dbh->errstr;
    return;
}

sub provide {
    my $db = shift;
    my $type = shift;

    my $dbh = setup($db->{db});

    switch ($type) {
        case 'handle' { return get_handle_data($dbh); }
        case 'domain' { return get_domain_data($dbh); }
    }

    return "ERR: data type not found";

}

sub get_handle_data {
    my $dbh = shift;

    my $chr = chr( int( rand(26) + 97 ) );

    my $handles = $dbh->selectall_arrayref(
        "SELECT * FROM contacts WHERE firstname LIKE '$chr%'",
        { Slice => {} } );
    return $handles->[ rand( scalar @{$handles} ) ];
}

sub get_domain_data {
    my $dbh = shift;

    my $chr = chr( int( rand(26) + 97 ) );

    my $domains = $dbh->selectall_arrayref(
        "SELECT * FROM domains WHERE domain LIKE '$chr%'",
        { Slice => {} } );
    my $dom = $domains->[ rand( scalar @{$domains} ) ];

    return {
        domain => $dom->{domain}.'.'.$dom->{tld},
        ns     => [
            { host => 'ns1.'.$domains->[0]->{domain}.'.'.$domains->[0]->{tld} },
            { host => 'ns2.'.$domains->[0]->{domain}.'.'.$domains->[0]->{tld} },
        ],
    };
}

sub get_result_summary {
    my $db = shift;
    my $dbh = setup($db);
    my $stats = $dbh->selectall_arrayref(qq/SELECT command, code, message, count(*) AS amt from log group by code,command order by command/,
            {Slice => {}} );
    return $stats;
}

1;
