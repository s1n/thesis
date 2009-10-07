#!/usr/bin/perl

use REST::Google::Search qw/WEB/;
use Modern::Perl;

# set service to use
REST::Google::Search->service(WEB);

# provide a valid http referer
REST::Google->http_referer('http://example.com');

my $res = REST::Google::Search->new(q => 'Jason Switzer');

die "response status failure" if $res->responseStatus != 200;

my $data = $res->responseData;

my $cursor = $data->cursor;
my $pages = $cursor->pages;

say "current page index: " . $cursor->currentPageIndex;
say "estimated result count: " . $cursor->estimatedResultCount;

#FIXME we want to sift over more pages of results
say "";
for($data->results) {
   say "title: " . $_->title;
   say "url: " . $_->url;
   say "";
}
