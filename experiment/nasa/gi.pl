#!/usr/bin/perl

use warnings;
use strict;
use WWW::Mechanize;

my $start = shift;
my $mech = WWW::Mechanize->new(autocheck => 1);
$mech->get($start);

my @links = $mech->find_all_links;

for my $link(@links) {
   my $url = $link->url_abs;
   my $word = lc $link->text;
   print "$word => $url\n";
}
