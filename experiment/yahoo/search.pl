#!/usr/bin/perl
#IOsS5LLV34ECNN_x4bzFgK5JqzVKt3Ml6uzOyo_b8MWDz.xWN0Hn0ODzotw27ibRzrI-

use Modern::Perl;
use Yahoo::Search;

my $search = Yahoo::Search->new(AppId=>'cqL55Q_V34F4bh5L9TOepTBv3l39KWPBC5tH5M8VBUfKXZccpy0NubA7k7CR_cj.CqHRRiIH');
#pass a higher count?
my $request = $search->Request(Doc => 'Jason Switzer');
my $response = $request->Fetch();

while(my $result = $response->NextResult) {
   say "Result: #", $result->I + 1;
   say "URL: ", $result->Url;
}
