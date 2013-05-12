use strict;
use warnings;
use WWW::ThisIsMyJam;
#
my $timj = WWW::ThisIsMyJam->new();
my @jams;
for (my $page = 1;; ++$page) {
    my $r = $timj->jams({person => 'jamoftheday', page => $page});
    push @jams, @{$r->{jams}};
    last unless $r->{list}{hasMore};
}

# Do something cool with @jams
