#!/usr/bin/perl

use Modern::Perl;
use Google::Search;

my $key = "ABQIAAAAkkcUrQgZB2CGtTBtoqQzVhRLOGg_GIWfo2k07J84chOCX73SvRRtOOE5K26gjA1W_V8J494prcKOLw";
my $referer = "http://s1n.dyndns.org";
my $search = Google::Search->Web(q => 'Jason Switzer',
                                 key => $key,
                                 referer => $referer);
my $result = $search->first;
while($result) {
   say $result->number, " ", $result->uri;
   $result = $result->next;
}
