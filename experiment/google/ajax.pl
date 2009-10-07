#!/usr/bin/perl

use Google::Search;

my $key = "";
my $referer = "http://s1n.dyndns.org";
my $search = Google::Search->Web(q => 'Jason Switzer',
                                 key => $key,
                                 referer => $referer);
my $result = $search->first;
while($result) {
   say $result->number, " ", $result->uri;
   $result = $result->next;\
}
