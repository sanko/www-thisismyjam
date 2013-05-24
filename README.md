# NAME


WWW::ThisIsMyJam - Synchronous and asynchronous interfaces to This Is My Jam


# SYNOPSIS


    use WWW::ThisIsMyJam;
    my $jam = WWW::ThisIsMyJam->new;
    $jam->person('jamoftheday');


# Description


This module provides access to Jam data through the new, official API in
synchronous or asynchronous mode.


The asynchronous mode requires you have [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) and [AnyEvent::HTTP](http://search.cpan.org/perldoc?AnyEvent::HTTP)
available. However, since it's just _supported_ and not _necessary_, it is
not declared as a prerequisite.


# Methods


This Is My Jam provides an ultra simple, JSON-based API. First, we'll cover
public utility methods and then the categorized Jam functions.


## Standard


### new( )


Creates a new [WWW::ThisIsMyJam](http://search.cpan.org/perldoc?WWW::ThisIsMyJam) object.


    # typical usage
    my $jam = WWW::ThisIsMyJam->new;


    # it would be pointless to change these, but it's possible
    my $jam = WWW::ThisIsMyJam->new(
        apiversion => 1,
        basename   => 'http://api.thisismyjam.com'
    );


## Person


Person methods cover a single user.


### user( person )


A user's overview data includes all information about the requested person
along with their current jam (if any). All methods require at least a
username.


    # Fetch info for the Jam of the Day account
    my $overview = $timj->user( 'jamoftheday' );


    # Use callbacks for a specific user
    $timj->user( 'jamoftheday', { cb => sub { my ( $overview ) = @_; ... } });


### likes( person )


Returns a list of liked jams. Takes the optional parameter 'show', which
specifies whether to include only current or past (expired) jams.


    # Get jams I like
    $timj->likes( 'jamoftheday' );


    # Only get active jams
    $timj->likes({ person => 'jamoftheday', show => 'current' });


    # Only get expired jams
    $timj->likes({ person => 'jamoftheday', show => 'past' });


### jams( person )


Returns a list of the person's jams. Optional parameter 'show' can be set to
only show past (expired) jams.


    # Get all of a user's jams
    $timj->jams({ person => 'jamoftheday' });


    # Only get (expired) jams from the past
    $timj->jams({ person => 'jamoftheday', show => 'past' });


### following( person )


Returns a list of people that a particular person is following. Optional
parameter 'order' can be set to sort the users: `order => 'followedDate'`
orders by date followed; `order => 'affinity'` currently orders by number
of likes from the requested person; `order => 'name'` orders by name
alphabetically.


While omitted from the official documentation, observation indicates that
'affinity' is the default order.


    # Get users the person if following
    $timj->following({ person => 'jamoftheday' });


    # Get users the person is following sorted by name
    $timj->following({ person => 'jamoftheday', order => 'name' });


### followers( person )


Returns a list of people that a particular person is followed by. Optional
parameter 'order' can be set to sort the users: `order => 'followedDate'`
orders by date followed; `order => 'affinity'` currently orders by number
of likes from the requested person; `order => 'name'` orders by name
alphabetically.


While omitted from the official documentation, observation indicates that
'affinity' is the default order.


    # Get users the person if following
    $timj->followers({ person => 'jamoftheday' });


    # Get users the person is following sorted by name
    $timj->followers({ person => 'jamoftheday', order => 'name' });


### follow( person )


Follow the specified user. Requires [authentication](#Authentication).


    # Follow someone
    $timj->follow({ person => 'jamoftheday' });


### unfollow( person )


Unfollow the specified user. Requires [authentication](#Authentication).


    # Unfollow someone
    $timj->unfollow({ person => 'jamoftheday' });


## Jam


Jam methods return metadata about a single or list of jams.


### jam( id )


Retrieves information on a single jam by ID.


    # Get info about a jam. (Jam of the Day from March 6th, 2013)
    $timj->jam( { id => '4zugtyg' });


### likers( id )


Returns a list of the people who liked a particular jam.


    # Get a list of people who liked the Jam of the Day from March 6th, 2013
    $timj->likers( { id => '4zugtyg' });


Note: "likers" isn't a word. I may change the name of this method before
v1.0.0.


### comments( id )


Returns a list of the comments that have been added to a jam.


    # What you say?
    $timj->comments({ id => '4zugtyg' });


### related( id )


Returns a list of jams that may be related (musically or otherwise) to the
specified jam. Only works on active jams and not to be confused with
[`related_jams( username )`](#related\_jams( username )).


    # All of these things are just like the other
    $timj->related({ id => '5sd5q1b' });


### like( id )


Like a jam. You can only like jams that are currently active. Requires
[authentication](http://search.cpan.org/perldoc?Authentication).


    $timj->like({ id => '4zugtyg' });


### unlike( id )


Unlike a jam. You can only unlike jams that are currently active. Requires
[authentication](http://search.cpan.org/perldoc?Authentication).


    $timj->like({ id => '4zugtyg' });


### post\_comment( id, comment )


Post a new comment on a jam. Requires [authentication](http://search.cpan.org/perldoc?Authentication).


    # Add nothing to the conversation
    $timj->post_comment({ id => '4zugtyg', comment => '+1' });


### rejammers( id )


Returns a list of people who rejammed this jam.


    # Find *true* fans of this jam
    $timj->rejammers({ id => '4zugtyg' });


## Comments


### get\_comment( id )


Retrieve a single comment by ID.


    # What's the story, morning glory?
    $timj->delete_comment({ id => 'q0hdq3' });


### delete\_comment( id )


Delete a single comment. Only the author of the comment and the person who
posted the jam can delete it. Requires [authentication](http://search.cpan.org/perldoc?Authentication).


    # Quiet, you!
    $timj->delete_comment({ id => 'q0hdq3' });


## Explore


### popular\_jams( )


Returns a list of today's most loved jams.


    $timj->popular_jams();


### trending\_jams( )


Returns a list of songs getting a lot of recent attention.


    $timj->trending_jams();


### rare\_jams( )


Returns a list of tracks we don't hear that often.


    $timj->rare_jams();


### random\_jams( )


Returns a random list of current jams.


    $timj->random_jams();


### newbie\_jams( )


Returns a list of jams from people who have just joined This Is My Jam.


    $timj->newbie_jams();


### related\_jams( username )


A list of jams related to username's current jam. Easily but not to be
confused with [`related( id )`](#related( id )).


    # Grab jams related to the current Jam of the Day
    $timj->related_jams({ username => 'jamoftheday' });


Yes, I know the person vs. username inconsistency. Blame This Is My Jam's API
designers or forget it and just use the
[short method call](#API Methods and Arguments):


    # Same as above but less confusing
    $timj->related_jams( 'jamoftheday' );


## Search


Search methods return lists of related material. With great power...


### search\_jams( by, q )


Searching by artist will return jams by or similar to the requested artist.
Genre search is powered by Last.fm tag search. Hashtag support is experimental
(no pagination, might be slow so use the
[asynchronus interface](#Asynchronus Callbacks)).


    # Find jams similar to those by The Knife
    $timj->search_jams({ by => 'artist', q => 'the knife' });


    # Find electronica jams
    $timj->search_jams({ by => 'genre', q => 'electro' });


    # Find jams with descriptions containing #jolly hashtags
    $timj->search_jams({ by => 'hashtag', q => 'jolly' }); # Note missing #


### search\_people( by, q )


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


## Miscellaneous


### verify( )


Returns information about the currently [authenticated](http://search.cpan.org/perldoc?Authentication) user.


    # Eh?
    $timj->verify();


# API Methods and Arguments


Most This Is My Jam API methods take parameters. All WWW::ThisIsMyJam API
methods will accept a HASH ref of named parameters as specified in the
This Is My Jam API documentation. For convenience, many WWW::ThisIsMyJam
methods accept simple positional arguments. The positional parameter passing
style is optional; you can always use the named parameters in a HASH reference
if you prefer.


You may pass any number of required parameters as positional parameters. You
_must_ pass them in the order specified in the documentation for each method.
Optional parameters must be passed as named parameters in a HASH reference.
The HASH reference containing the named parameters must be the final parameter
to the method call. Any required parameters not passed as positional
parameters, must be included in the named parameter HASH reference.


For example, the method `following` has one required parameter, `person`.
You can call `following` with a HASH ref argument:


    $timj->following({ person => 'jamoftheday' });


Or, you can use the convenient, positional parameter form:


    $timj->following('jamoftheday');


The `following` method also has an optional parameter: `order`. You __must__
use the HASH ref form:


    $timj->following({ person => 'jamoftheday', order => 'name' });


You may use the convenient positional form for the required `person`
parameter with the optional parameters specified in the named parameter HASH
reference:


    $timj->following('jamoftheday', { order => 'name' });


Convenience form is provided for the required parameters of all API methods.
So, these two calls are equivalent:


    $timj->search_jams({ by => 'artist', q => 'Stone Roses' });
    $timj->search_jams('artist', 'Stone Roses');


This scheme is ripped directly from [Net::Twitter](http://search.cpan.org/perldoc?Net::Twitter).


## Paging


Some methods return partial results a page at a time, currently 60 items per
page. For these, there is an optional `page` parameter. The first page is
returned by passing `page => 1`, the second page by passing
`page => 2`, etc. If no `page` parameter is passed, the first page is
returned. Each paged response contains a `list` HASH ref with a `hasMore`
key. On the last page, `hasMore` will be `false`.


Here's an example that demonstrates how to obtain all of a user's previous
jams in a loop:


    my @jams;
    for (my $page = 1;; ++$page) {
        my $r = $timj->jams({person => 'jamoftheday', page => $page});
        push @jams, @{$r->{jams}};
        last unless $r->{list}{hasMore};
    }


## Asynchronus Callbacks


The supported asynchronous mode requires an additional parameter `cb`. This
must be a CODE ref and works like so:


    $timj->verify({ cb => sub { ... } });


    $timj->jams( 'jamoftheday', { cb => sub { ... } });


    $timj->like({ id => '4zugtyg', cb => sub { ... } });


This is ripped directly from [Net::xkcd](http://search.cpan.org/perldoc?Net::xkcd).


# Authentication


In order to perform actions on behalf of a user such as
[liking a jam](#like( id )) or [following people](#follow( person )), a
user first needs to give permission to your app. Once that's been done, you
can make authenticated calls.


This Is My Jam uses OAuth 1.0 for authentication. Before v1.0.0,
WWW::ThisIsMyJam will support OAuth.


# Dependencies


- [Try::Tiny](http://search.cpan.org/perldoc?Try::Tiny)

- [HTTP::Tiny](http://search.cpan.org/perldoc?HTTP::Tiny)

- [JSON::Tiny](http://search.cpan.org/perldoc?JSON::Tiny)

- [Carp](http://search.cpan.org/perldoc?Carp)

- [URI](http://search.cpan.org/perldoc?URI)

- [URI::QueryParam](http://search.cpan.org/perldoc?URI::QueryParam)

- [Moo](http://search.cpan.org/perldoc?Moo)

- [Type::Tiny](http://search.cpan.org/perldoc?Type::Tiny)


## Optional Dependencies


- [AnyEvent](http://search.cpan.org/perldoc?AnyEvent)

- [AnyEvent::HTTP](http://search.cpan.org/perldoc?AnyEvent::HTTP)


# See Also


- [Net::Twitter](http://search.cpan.org/perldoc?Net::Twitter)

- [Net::xkcd](http://search.cpan.org/perldoc?Net::xkcd)

- [This Is My Jam API Documentation](http://www.thisismyjam.com/developers/docs)


# Bug Reports


If email is better for you, [my address is mentioned below](#Author) but I
would rather have bugs sent through the issue tracker found at
http://github.com/sanko/www-thisismyjam/issues.


# Author


Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/


CPAN ID: SANKO


# License and Legal


Copyright (C) 2013 by Sanko Robinson <sanko@cpan.org>


This program is free software; you can redistribute it and/or modify it under
the terms of
[The Artistic License 2.0](http://www.perlfoundation.org/artistic\_license\_2\_0).
See the `LICENSE` file included with this distribution or
[notes on the Artistic License 2.0](http://www.perlfoundation.org/artistic\_2\_0\_notes)
for clarification.


When separated from the distribution, all original POD documentation is
covered by the
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/us/legalcode).
See the
[clarification of the CCA-SA3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).

