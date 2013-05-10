#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use WWW::ThisIsMyJam;
use Test::More tests => 6;
my $x = WWW::ThisIsMyJam->new;
isa_ok($x, 'WWW::ThisIsMyJam');
can_ok($x, '_request');

sub check_person {
    my $meta = shift;
    ok($meta, 'Successful request');
    is(ref $meta, 'HASH', 'Correct type of meta');
    ok(exists $meta->{'person'}, 'Got person (user) data in meta');
    if (shift) {
        is($meta->{'person'}{'fullname'},
            'Jam Of The Day',
            'Got correct name');
    }
}

sub check_jam {
    my $meta = shift;
    ok(exists $meta->{'jam'}, 'Got jam info');
}
my $meta
    = $x->_request('GET', 'http://api.thisismyjam.com/1/jamoftheday.json');
check_person($meta);
check_jam($meta);
