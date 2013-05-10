package WWW::ThisIsMyJam;
# ABSTRACT: Synchronous and asynchronous interfaces to This Is My Jam
our $API     = 1;
our $URL     = 'http://api.thisismyjam.com';
our $VERSION = v0.0.1;
use strict;
use warnings;
use Carp;
use JSON;
use Try::Tiny;
use HTTP::Tiny;
use URI;
use URI::QueryParam;
my $can_async
    = try { require AnyEvent; require AnyEvent::HTTP; !!1 } catch { !1 };
#
sub new {
    my $c = shift;
    my %args = (apiversion => $API,
                baseurl    => $URL,
                oauth      => {},
                @_
    );
    return bless {%args}, $c;
}
our %API = (
    person => {path     => ':person',
               method   => 'GET',
               params   => [qw[person cb]],
               required => [qw[person]],
               returns  => 'HashRef'
    },
    likes => {path     => ':person/likes',
              method   => 'GET',
              params   => [qw[person show page cb]],
              required => [qw[person]],
              returns  => 'ArrayRef[HashRef]'
    },
    jams => {path     => ':person/jams',
             method   => 'GET',
             params   => [qw[person show page cb]],
             required => [qw[person]],
             returns  => 'ArrayRef[HashRef]'
    },
    following => {path     => ':person/following',
                  method   => 'GET',
                  params   => [qw[person order page cb]],
                  required => [qw[person]],
                  returns  => 'ArrayRef[HashRef]'
    },
    followers => {path     => ':person/followers',
                  method   => 'GET',
                  params   => [qw[person order page cb]],
                  required => [qw[person]],
                  returns  => 'ArrayRef[HashRef]'
    },
    follow => {path         => ':person/follow',
               method       => 'POST',
               params       => [qw[person cb]],
               required     => [qw[person]],
               returns      => 'Bool',
               authenticate => 1
    },
    unfollow => {path         => ':person/unfollow',
                 method       => 'POST',
                 params       => [qw[person cb]],
                 required     => [qw[person]],
                 returns      => 'Bool',
                 authenticate => 1
    },

    # Jam
    jam => {path     => 'jams/:id',
            method   => 'GET',
            params   => [qw[id cb]],
            required => [qw[id]],
            returns  => 'Jam'
    },
    likers => {path     => 'jams/:id/likes',
               method   => 'GET',
               params   => [qw[id cb]],
               required => [qw[id]],
               returns  => 'ArrayRef[User]'
    },
    comments => {path     => 'jams/:id/comments',
                 method   => 'GET',
                 params   => [qw[id cb]],
                 required => [qw[id]],
                 returns  => 'ArrayRef[Comment]'
    },
    like => {path         => 'jams/:id/like',
             method       => 'POST',
             params       => [qw[id cb]],
             required     => [qw[id]],
             returns      => 'Bool',
             authenticate => 1
    },
    unlike => {path         => 'jams/:id/unlike',
               method       => 'POST',
               params       => [qw[id cb]],
               required     => [qw[id]],
               returns      => 'Bool',
               authenticate => 1
    },
    post_comment => {path         => 'jams/:id/comment',
                     method       => 'POST',
                     params       => [qw[id comment cb]],
                     required     => [qw[id comment]],
                     returns      => 'Bool',
                     authenticate => 1
    },

    # Comments
    get_comment => {path     => 'comments/:id',
                    method   => 'GET',
                    params   => [qw[id cb]],
                    required => [qw[id]],
                    returns  => 'Comment'
    },
    delete_comment => {path         => 'comments/:id',
                       method       => 'DELETE',
                       params       => [qw[id cb]],
                       required     => [qw[id]],
                       returns      => 'Bool',
                       authenticate => 1
    },

    # Explore
    popular_jams => {path     => 'explore/popular',
                     method   => 'GET',
                     params   => [qw[cb]],
                     required => [],
                     returns  => 'ArrayRef[Jam]',
    },
    trending_jams => {path     => 'explore/breaking',
                      method   => 'GET',
                      params   => [qw[cb]],
                      required => [],
                      returns  => 'ArrayRef[Jam]'
    },
    rare_jams => {path     => 'explore/rare',
                  method   => 'GET',
                  params   => [qw[cb]],
                  required => [],
                  returns  => 'ArrayRef[Jam]'
    },
    random_jams => {path     => 'explore/chance',
                    method   => 'GET',
                    params   => [qw[cb]],
                    required => [],
                    returns  => 'ArrayRef[Jam]'
    },
    newbie_jams => {path     => 'explore/newcomers',
                    method   => 'GET',
                    params   => [qw[cb]],
                    required => [],
                    returns  => 'ArrayRef[Jam]'
    },
    related_jams => {path     => 'explore/related',
                     method   => 'GET',
                     params   => [qw[username cb]],
                     required => [qw[username]],
                     returns  => 'ArrayRef[Jam]'
    },

    # Search
    search_jams => {path     => 'search/jam',
                    method   => 'GET',
                    params   => [qw[by q cb]],
                    required => [qw[by q]],
                    returns  => 'ArrayRef[Jam]'
    },
    ,
    search_people => {path     => 'search/person',
                      method   => 'GET',
                      params   => [qw[by q cb]],
                      required => [qw[by q]],
                      returns  => 'ArrayRef[Jam]'
    },

    # Misc
    verify => {path         => 'verify',
               method       => 'GET',
               params       => [qw[cb]],
               required     => [],
               returns      => 'HashRef',
               authenticate => 1
    },
);
for my $method (keys %API) {
    eval sprintf
        q[sub WWW::ThisIsMyJam::%s { my $s = shift; $s->_request($s->_parse_args( '%s', @_ )) }],
        $method, $method;
}

# Private methods
sub _request {
    my ($s, $method, $url, $cb) = @_;
    if ($cb) {

        # this is async
        croak 'AnyEvent and AnyEvent::HTTP are required for async mode'
            unless $can_async;
        AnyEvent::HTTP::http_request(
            $method, $url,
            sub {
                my $body = shift;
                my $meta = _decode_json($body);
                return $cb->($meta);
            }
        );
        return 0;
    }

    # this is sync
    my $result = HTTP::Tiny->new->request($method, $url);
    $result->{'success'} or croak "Can't fetch $url: " . $result->{'reason'};
    my $meta = _decode_json($result->{'content'});
    return $meta;
}

sub _decode_json {
    my $json = shift;
    my $data = try { decode_json $json }
    catch { croak "Can't decode '$json': $_" };
    return $data;
}

sub _parse_args {
    my $s      = shift;
    my $method = shift;
    $API{$method} // confess 'Unknown RPC method: ' . $method;
    my %args;
    for my $arg (@{$API{$method}{required}}) {
        last if ref $_[0] eq 'HASH';
        $args{$arg} = shift;
    }
    my $args_2 = shift;
    @args{keys %$args_2} = values %$args_2;
    #for my $arg (@{$API{$method}{required}}) {
    #    $args{$arg} // croak qq[required arg '$arg' is is missing!];
    #}

    # replace placeholder arguments
    my $local_path = $API{$method}{path};
    $local_path =~ s,/:id$,,
        unless exists $args{id};    # remove optional trailing id
    $local_path
        =~ s/:(\w+)/delete $args{$1} or croak "required arg '$1' missing"/eg;
    #
    my $cb  = delete $args{cb};
    my $uri = URI->new("$URL/$API/$local_path.json");
    $uri->query_form_hash(%args);
    ($API{$method}{method}, $uri, $cb);
}
!!'This is my Jam!';
