#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGIx::Core' ) || print "Bail out!\n";
}

diag( "Testing CGIx::Core $CGIx::Core::VERSION, Perl $], $^X" );
