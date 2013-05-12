package WWW::ThisIsMyJam;

# ABSTRACT: Synchronous and asynchronous interfaces to This Is My Jam
our $VERSION = v0.0.2;
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
use Moo;
use Types::Standard qw[Object Int Str];
use Type::Utils qw[coerce from];
#
has apiversion => (is => 'ro', isa => Int, default => '1');
coerce Object, from Str, q[URI->new( $_ )];
has baseurl => (is      => 'ro',
                isa     => Object,
                default => 'http://api.thisismyjam.com',
                coerce  => Object->coercion
);
#
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
    rejammers => {path         => 'jams/:id/rejammers',
                  method       => 'GET',
                  params       => [qw[id cb]],
                  required     => [qw[id]],
                  returns      => 'ArrayRef[Person]',
                  undocumented => 1
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
                my $meta = $s->_decode_json($body);
                return $cb->($meta);
            }
        );
        return 0;
    }

    # this is sync
    my $result = HTTP::Tiny->new->request($method, $url);
    $result->{'success'} or croak "Can't fetch $url: " . $result->{'reason'};
    my $meta = $s->_decode_json($result->{'content'});
    return $meta;
}

sub _decode_json {
    my $s    = shift;
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
    my $cb = delete $args{cb};
    my $uri = URI->new(sprintf '%s/%d/%s.json', $s->baseurl,
                       $s->apiversion,          $local_path);
    $uri->query_form_hash(%args);
    ($API{$method}{method}, $uri, $cb);
}
!!'This is my Jam!';

=pod

=head1 NAME

WWW::ThisIsMyJam - Synchronous and asynchronous interfaces to This Is My Jam

=head1 SYNOPSIS

    use WWW::ThisIsMyJam;
    my $jam = WWW::ThisIsMyJam->new;
    $jam->person('jamoftheday');

=head1 Description

This module provides access to Jam data through the new, official API in
synchronous or asynchronous mode.

The asynchronous mode requires you have L<AnyEvent> and L<AnyEvent::HTTP>
available. However, since it's just I<supported> and not I<necessary>, it is
not declared as a prerequisite.

=head1 Methods

This Is My Jam provides an ultra simple, JSON-based API. First, we'll cover
public utility methods and then the categorized Jam functions.

=head2 Standard

=head3 new( )

Creates a new L<WWW::ThisIsMyJam> object.

    # typical usage
    my $jam = WWW::ThisIsMyJam->new;

    # it would be pointless to change these, but it's possible
    my $jam = WWW::ThisIsMyJam->new(
        apiversion => 1,
        basename   => 'http://api.thisismyjam.com'
    );

=head2 Person

Person methods cover a single user.

=head3 user( person )

A user's overview data includes all information about the requested person
along with their current jam (if any). All methods require at least a
username.

    # Fetch info for the Jam of the Day account
    my $overview = $timj->user( 'jamoftheday' );

    # Use callbacks for a specific user
    $timj->user( 'jamoftheday', { cb => sub { my ( $overview ) = @_; ... } });

=head3 likes( person )

Returns a list of liked jams. Takes the optional parameter 'show', which
specifies whether to include only current or past (expired) jams.

    # Get jams I like
    $timj->likes( 'jamoftheday' );

    # Only get active jams
    $timj->likes({ person => 'jamoftheday', show => 'current' });

    # Only get expired jams
    $timj->likes({ person => 'jamoftheday', show => 'past' });

=head3 jams( person )

Returns a list of the person's jams. Optional parameter 'show' can be set to
only show past (expired) jams.

    # Get all of a user's jams
    $timj->jams({ person => 'jamoftheday' });

    # Only get (expired) jams from the past
    $timj->jams({ person => 'jamoftheday', show => 'past' });

=head3 following( person )

Returns a list of people that a particular person is following. Optional
parameter 'order' can be set to sort the users: C<< order => 'followedDate' >>
orders by date followed; C<< order => 'affinity' >> currently orders by number
of likes from the requested person; C<< order => 'name' >> orders by name
alphabetically.

While omitted from the official documentation, observation indicates that
'affinity' is the default order.

    # Get users the person if following
    $timj->following({ person => 'jamoftheday' });

    # Get users the person is following sorted by name
    $timj->following({ person => 'jamoftheday', order => 'name' });

=head3 followers( person )

Returns a list of people that a particular person is followed by. Optional
parameter 'order' can be set to sort the users: C<< order => 'followedDate' >>
orders by date followed; C<< order => 'affinity' >> currently orders by number
of likes from the requested person; C<< order => 'name' >> orders by name
alphabetically.

While omitted from the official documentation, observation indicates that
'affinity' is the default order.

    # Get users the person if following
    $timj->followers({ person => 'jamoftheday' });

    # Get users the person is following sorted by name
    $timj->followers({ person => 'jamoftheday', order => 'name' });

=head3 follow( person )

Follow the specified user. Requires L<authentication|/Authentication>.

    # Follow someone
    $timj->follow({ person => 'jamoftheday' });

=head3 unfollow( person )

Unfollow the specified user. Requires L<authentication|/Authentication>.

    # Unfollow someone
    $timj->unfollow({ person => 'jamoftheday' });

=head2 Jam

Jam methods return metadata about a single or list of jams.

=head3 jam( id )

Retrieves information on a single jam by ID.

    # Get info about a jam. (Jam of the Day from March 6th, 2013)
    $timj->jam( { id => '4zugtyg' });

=head3 likers( id )

Returns a list of the people who liked a particular jam.

    # Get a list of people who liked the Jam of the Day from March 6th, 2013
    $timj->likers( { id => '4zugtyg' });

Note: "likers" isn't a word. I may change the name of this method before
v1.0.0.

=head3 comments( id )

Returns a list of the comments that have been added to a jam.

    # What you say?
    $timj->comments({ id => '4zugtyg' });

=head3 like( id )

Like a jam. You can only like jams that are currently active. Requires
L<authentication|Authentication>.

    $timj->like({ id => '4zugtyg' });

=head3 unlike( id )

Unlike a jam. You can only unlike jams that are currently active. Requires
L<authentication|Authentication>.

    $timj->like({ id => '4zugtyg' });

=head3 post_comment( id, comment )

Post a new comment on a jam. Requires L<authentication|Authentication>.

    # Add nothing to the conversation
    $timj->post_comment({ id => '4zugtyg', comment => '+1' });

=head3 rejammers( id )

Returns a list of people who rejammed this jam.

    # Find out *true* fans of this jam
    $timj->rejammers({ id => '4zugtyg' });

=head2 Comments

=head3 get_comment( id )

Retrieve a single comment by ID.

    # What's the story, morning glory?
    $timj->delete_comment({ id => 'q0hdq3' });

=head3 delete_comment( id )

Delete a single comment. Only the author of the comment and the person who
posted the jam can delete it. Requires L<authentication|Authentication>.

    # Quiet, you!
    $timj->delete_comment({ id => 'q0hdq3' });

=head2 Explore

=head3 popular_jams( )

Returns a list of today's most loved jams.

    $timj->popular_jams();

=head3 trending_jams( )

Returns a list of songs getting a lot of recent attention.

    $timj->trending_jams();

=head3 rare_jams( )

Returns a list of tracks we don't hear that often.

    $timj->rare_jams();

=head3 random_jams( )

Returns a random list of current jams.

    $timj->random_jams();

=head3 newbie_jams( )

Returns a list of jams from people who have just joined This Is My Jam.

    $timj->newbie_jams();

=head3 related_jams( username )

A list of jams related to username's current jam.

    # Grab jams related to the current Jam of the Day
    $timj->related_jams({ username => 'jamoftheday' });

Yes, I know the person vs. username inconsistency. Blame This Is My Jam's API
designers or forget it and just use the
L<short method call|/"API Methods and Arguments">:

    # Same as above but less confusing
    $timj->related_jams( 'jamoftheday' );

=head2 Search

Search methods return lists of related material. With great power...

=head3 search_jams( by, q )

Searching by artist will return jams by or similar to the requested artist.
Genre search is powered by Last.fm tag search.

    # Find jams similar to those by The Knife
    $timj->search_jams({ by => 'artist', q => 'the knife' });

    # Find electronica jams
    $timj->search_jams({ by => 'genre', q => 'electro' });

=head3 search_people( by, q )

You can either search for people by name, artist and track. Searching by name
returns people with the search string in their username, full name or Twitter
name. Searching by artist returns people who have posted tracks by artists
(fuzzy) matching the search string. Searching by track returns people who have
posted a particular track (strict, case-insensitive matching).

    # Find users with the word 'jam' in their name, username, twitter handle
    $timj->search_people({ by => 'name' , q => 'jam' });

    # Find users who jam out to music by The Beach Boys
    $timj->search_people({ by => 'artist', q => 'beach boys' });

    # Find users who jam out to 'Video Games' by Lana del Rey
    $timj->search_people({ by => 'track', q => 'Lana del Rey|Video games' });

=head2 Miscellaneous

=head3 verify( )

Returns information about the currently L<authenticated|Authentication> user.

    # Eh?
    $timj->verify();

=head1 API Methods and Arguments

Most This Is My Jam API methods take parameters. All WWW::ThisIsMyJam API
methods will accept a HASH ref of named parameters as specified in the
This Is My Jam API documentation. For convenience, many WWW::ThisIsMyJam
methods accept simple positional arguments. The positional parameter passing
style is optional; you can always use the named parameters in a HASH reference
if you prefer.

You may pass any number of required parameters as positional parameters. You
I<must> pass them in the order specified in the documentation for each method.
Optional parameters must be passed as named parameters in a HASH reference.
The HASH reference containing the named parameters must be the final parameter
to the method call. Any required parameters not passed as positional
parameters, must be included in the named parameter HASH reference.

For example, the method C<following> has one required parameter, C<person>.
You can call C<following> with a HASH ref argument:

    $timj->following({ person => 'jamoftheday' });

Or, you can use the convenient, positional parameter form:

    $timj->following('jamoftheday');

The C<following> method also has an optional parameter: C<order>. You B<must>
use the HASH ref form:

    $timj->following({ person => 'jamoftheday', order => 'name' });

You may use the convenient positional form for the required C<person>
parameter with the optional parameters specified in the named parameter HASH
reference:

    $timj->following('jamoftheday', { order => 'name' });

Convenience form is provided for the required parameters of all API methods.
So, these two calls are equivalent:

    $timj->search_jams({ by => 'artist', q => 'Stone Roses' });
    $timj->search_jams('artist', 'Stone Roses');

This scheme is ripped directly from L<Net::Twitter>.

=head2 Paging

Some methods return partial results a page at a time, currently 60 items per
page. For these, there is an optional C<page> parameter. The first page is
returned by passing C<< page => 1 >>, the second page by passing
C<< page => 2 >>, etc. If no C<page> parameter is passed, the first page is
returned. Each paged response contains a C<list> HASH ref with a C<hasMore>
key. On the last page, C<hasMore> will be C<false>.

Here's an example that demonstrates how to obtain all of a user's previous
jams in a loop:

    my @jams;
    for (my $page = 1;; ++$page) {
        my $r = $timj->jams({person => 'jamoftheday', page => $page});
        push @jams, @{$r->{jams}};
        last unless $r->{list}{hasMore};
    }

=head2 Asynchronus Callbacks

The supported asynchronous mode requires an additional parameter C<cb>. This
must be a CODE ref and works like so:

    $timj->verify({ cb => sub { ... } });

    $timj->jams( 'jamoftheday', { cb => sub { ... } });

    $timj->like({ id => '4zugtyg', cb => sub { ... } });

This is ripped directly from L<Net::xkcd>.

=head1 Authentication

In order to perform actions on behalf of a user such as
L<liking a jam|/"like( id )"> or L<following people|/"follow( person )">, a
user first needs to give permission to your app. Once that's been done, you
can make authenticated calls.

This Is My Jam uses OAuth 1.0 for authentication. Before v1.0.0,
WWW::ThisIsMyJam will support OAuth.

=head1 Dependencies

=over 4

=item * L<Try::Tiny>

=item * L<HTTP::Tiny>

=item * L<JSON>

=item * L<Carp>

=item * L<URI>

=item * L<URI::QueryParam>

=item * L<Moo>

=item * L<Type::Tiny>

=back

=head2 Optional Dependencies

=over 4

=item * L<AnyEvent>

=item * L<AnyEvent::HTTP>

=back

=head1 See Also

=over 4

=item * L<Net::Twitter>

=item * L<Net::xkcd>

=item * L<This Is My Jam API Documentation|http://www.thisismyjam.com/developers/docs>

=back

=head1 Bug Reports

If email is better for you, L<my address is mentioned below|/"Author"> but I
would rather have bugs sent through the issue tracker found at
http://github.com/sanko/www-thisismyjam/issues.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2013 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
