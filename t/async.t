#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use WWW::ThisIsMyJam;
use Test::More;

# check for AnyEvent and AnyEvent::HTTP
eval 'use AnyEvent';
$@ and plan skip_all => 'AnyEvent required for this test';
eval 'use AnyEvent::HTTP';
$@ and plan skip_all => 'AnyEvent::HTTP required for this test';

# actual test
plan tests => 7;
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
my $cv = AnyEvent->condvar;
#
$cv->begin;
$x->_request(
    'GET',
    'http://api.thisismyjam.com/1/jamoftheday.json',
    sub {
        my $meta = shift;
        check_person($meta);
        check_jam($meta);
        $cv->end;
    }
);
$cv->begin;
$x->_request(
    'GET',
    'http://api.thisismyjam.com/1/jams/4zugtyg.json',
    sub {
        my $meta = shift;
        check_jam($meta);
        $cv->end;
    }
);
$cv->recv;
