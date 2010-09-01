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
@EXPORT_OK = qw(archive preserve provide);

sub setup {
    my $db  = shift;
    my $dsn = "DBI:SQLite:dbname=" . $db;
    my $dbh = DBI->connect($dsn) or croak "Could not open fuzzer database: $@";
    return $dbh;
}

sub archive {
    my ($db, $in, $out) = @_;

    print STDERR Dumper($in, $out);
    #$Data::Dumper::Terse;
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
    my $_type = shift;

    my $dbh = setup($db->{db});

    my @types = split(/:/, $_type);
    my %res;
    foreach my $type (@types){
        switch ($type) {
            case 'handle'       { %res = (%res, %{get_handle_data($dbh)}); }
            case 'contact'      { %res = (%res, %{get_contact_data($dbh)}); }
            case 'domain'       { %res = (%res, %{get_domain_data($dbh)}); }
            case 'systemdomain' { %res = (%res, %{get_systemdomain_data($dbh)}); }
            case 'reghandles'   { %res = (%res, %{get_reghandles_data($dbh)}); }
            default             { %res = (%res, "ERR: $type has no data generator!"); }
        }
    }
    return \%res;
}

sub preserve {
    my ($db, $command, $data) = @_;

    my $dbh = setup($db->{db});

    switch ($command) {
        case 'createcontact' { return set_handle_data($dbh, $data); }
        case 'createdomain' { return set_domain_data($dbh, $data); }
    }

    return "ERR: command outcome can not be preserved";

}

sub set_handle_data {
    my ($dbh, $handle) = @_;

    my $insert = "INSERT INTO handles ('handle') VALUES ('$handle')";
    print STDERR "\n----\n";
    print STDERR $insert;
    print STDERR "\n----\n";
    $dbh->do($insert);
    print STDERR $dbh->errstr() if $dbh->errstr;
    return;
}

sub set_domain_data {
    my ($dbh, $domain) = @_;

    my $insert = "INSERT INTO systemdomains ('domain') VALUES ('$domain')";
    print STDERR "\n----\n";
    print STDERR $insert;
    print STDERR "\n----\n";
    $dbh->do($insert);
    print STDERR $dbh->errstr() if $dbh->errstr;
    return;
}

sub get_contact_data {
    my $dbh = shift;

    my $chr = chr( int( rand(26) + 97 ) );

    my $handles = $dbh->selectall_arrayref(
        "SELECT * FROM contacts WHERE firstname LIKE '$chr%'",
        { Slice => {} } );
    my $handle = $handles->[ rand( scalar @{$handles} ) ];
    $handle->{contact_id} = uc($chr).'-'.time;
    return $handle;
}

sub get_handle_data {
    my $dbh = shift;

    my $_handles = $dbh->selectall_arrayref(
        "SELECT * FROM handles",
        { Slice => {} } );
    return $_handles->[ rand( scalar @{$_handles} ) ] || {handle => 'X-478942389'};
}

sub get_reghandles_data {
    my $dbh = shift;

    my $handles->{owner} = get_handle_data($dbh);
    $handles->{admin} = get_handle_data($dbh);
    $handles->{tech} = get_handle_data($dbh);
    return $handles;
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

sub get_systemdomain_data {
    my $dbh = shift;

    my $domains = $dbh->selectall_arrayref( "SELECT * FROM systemdomains", { Slice => {} } );
    return $domains->[ rand( scalar @{$domains} ) ] || {domain => 'no-domain.org.nz'};
}

sub get_result_summary {
    my $db = shift;
    my $dbh = setup($db);
    my $stats = $dbh->selectall_arrayref(qq/SELECT command, code, message, count(*) AS amt from log group by code,command order by command/,
            {Slice => {}} );
    return $stats;
}

sub get_code_summary {
    my $db = shift;
    my $code = shift;
    my $dbh = setup($db);
    my $stats = $dbh->selectall_arrayref("SELECT * from log where code=$code",
            {Slice => {}} );
    return $stats;
}

sub get_command_summary {
    my $db = shift;
    my $command = shift;
    my $dbh = setup($db);
    my $stats = $dbh->selectall_arrayref("SELECT * from log where command='$command'",
            {Slice => {}} );
    return $stats;
}

1;
