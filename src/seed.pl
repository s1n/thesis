#!/usr/bin/perl

use feature ':5.10';

#slurp affixes.txt
open(AFFIX, 'affixes.txt') or
   die "Unable to open affix pattern file: $!\n";
@pats = <AFFIX>;
chomp @pats;
for $p(@pats) {
   next if $p =~ /^#/;
   my @parts = split /,/, $p;
   my $pp = qr/$parts[0]/;
   #$patset{$pp} = $parts[1];
   $patset{$parts[1]} = $parts[0];
   say "positive: $parts[0]\nnegative: $patset{$parts[0]}";
}
close AFFIX;

#my %words = ('logical' => 0, 'illogical' => 0);
#slurp the dictionary
open(DICT, '/usr/share/dict/words') or
   die "Unable to open dictionary: $!\n";
while($line = <DICT>) {
   chomp $line;
   $dict{$line} = 0;
}
close DICT;

open(LOG, '>matches.log') or
   die "Unable to create match log: $!\n";

#loop over every word in the dictionary
while(($key, $sign) = each(%dict)) {
   #first check if it's a positive word
   while(($negpat, $pospat) = each(%patset)) {
      #say "check $key to $pospat" if $key eq 'trust';
      if($key =~ /$pospat/) {
         $foo = eval "\"$negpat\"";
         #say "found $key to $foo" if $key eq 'trust';
         #now check to see if it's a negative match
         if(exists $dict{$foo}) {
            say "positive match of $key to $pospat with $1 finding $foo";
            say LOG "$key, $foo";
            $dict{$foo}--;
            $dict{$key}++;
         }
      }
   }
}
close LOG;
