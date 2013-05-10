#!perl
# checks that fetch_metadata can fail
use strict;
use warnings;
use lib '../lib';
use Test::More tests => 8;
use Test::Fatal;

# this makes the $can_async return false
{
    no warnings qw/redefine once/;

    sub Try::Tiny::try(&;@) {
        my $coderef = shift;
        is(ref $coderef,
            ref sub {1},
            'Got code reference when overriding try()',
        );
        return 0;
    }

    sub Try::Tiny::catch(&;@) {
        my $coderef = shift;
        is(ref $coderef,
            ref sub {1},
            'Got code reference when overriding catch()',
        );
        return 0;
    }
    require WWW::ThisIsMyJam;
}
{
    no warnings qw/redefine once/;
    *HTTP::Tiny::request = sub {
        my $self   = shift;
        my $method = shift;
        my $img    = shift;
        isa_ok($self, 'HTTP::Tiny');
        is($img,
            'http://api.thisismyjam.com/1/jamoftheday.json',
            'Correct request');

        # this is purposely missing 'success' key
        return {reason => 'bwahaha'};
    };
}
my $x = WWW::ThisIsMyJam->new();
isa_ok($x, 'WWW::ThisIsMyJam');
can_ok($x, 'person');
like(exception { $x->person('jamoftheday') },
     qr/bwahaha/, 'Failed with good reason',
);
SKIP: {
    local $@ = undef;
    eval 'use AnyEvent';
    $@ and skip 'AnyEvent is needed for this test' => 1;
    like(
        exception {
            $x->person(
                'ProperNoun',
                {cb => sub {1}
                }
            );
        },
        qr/^\QAnyEvent and AnyEvent::HTTP are required for async mode\E/,
        'Failed in async as well',
    );
}
