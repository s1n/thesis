#!/usr/bin/perl

use Modern::Perl;
use Yahoo::Search;

my $search = Yahoo::Search->new();
#pass a higher count?
my $request = $search->Request(Doc => 'Jason Switzer');
my $response = $request->Fetch();

while(my $result = $response->NextResult) {
   say "Result: #", $result->I + 1;
   say "URL: ", $result->Url;
}
