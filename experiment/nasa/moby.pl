#!/usr/bin/perl

use lib '../lib';
no utf8;
use Text::Thesaurus::Moby;
use Data::Dumper;
use Devel::Cycle;

my $m = Text::Thesaurus::Moby->new;
$m->load('../data/moby/thes/mthesaur.txt');
for my $line(@{$m->rawdata}) {
   my @words = split /,/, $line;
   @words = undef;
   print ".";
}
print "\n";
#my @similar = $m->search('freedom');
#print Dumper(\@similar);

#for(0..6) {
#   my $line = $m->synset('freedom');
#   my @junk = split /,/, $line;
#   print "iteration " . ($_ + 1) . "...\n";
#   @junk = undef;
#   $line = undef;
#   find_cycle($m);
#   sleep 5;
#}

#open TEST, "../data/moby/thes/mthesaur.txt" or die $!;
#while(my $line = <TEST>) {
#   my @words = split /,/, $line;
#   @words = undef;
#   print "slurped...\n";
#}
#close TEST;

#use Tie::File;
#use Fcntl 'O_RDONLY';
#tie @array, 'Tie::File', '../data/moby/thes/mthesaur.txt', mode => O_RDONLY;
#die if !@array;
#for(@array) {
#   print "$_\n" if /^freedom,/;
#}
#untie @array;
#print "sleeping...\n";
#sleep 15;
