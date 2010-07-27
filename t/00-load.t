#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Trudy' );
}

diag( "Testing Trudy $Trudy::VERSION, Perl $], $^X" );
