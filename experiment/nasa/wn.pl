#!/usr/bin/perl

use WordNet::QueryData;
use Modern::Perl;
use Data::Dumper;

my $wn = WordNet::QueryData->new("/usr/share/wordnet/dict/");
my @words;
for my $word(@ARGV) {
   my $sense = "also";
   my %senses = ('n' => 'syns',
                 'v' => 'syns',
                 'a' => 'also');
   for my $pos(qw/n a v/) {
      trace_word($wn, "$word\#$pos", $senses{$pos}, \@words);
   }
}

my @cleanwords;
for my $w(@words) {
   my ($trimmed, undef, undef) = split /\#/, $w;
   push @cleanwords, $trimmed;
}

sub trace_word {
   my ($wn, $root, $sense, $wordref) = @_;
   say "tracing $root as $sense";

   my @words = query_sense($wn, $root, $sense);
   for my $w(@words) {
      my @newwords = query_sense($wn, $w, $sense);
      for my $nw(@newwords) {
         say "checking newword $nw";
         push @$wordref, $nw if !grep(/$nw/, @$wordref);
         say "dup $nw" if grep(/$nw/, @$wordref);
      }
   }
}

#my @words = query_sense($wn, "happy#a#1", "also");
#for my $word(@words) {
#   my @newwords = query_sense($wn, $word, "also");
#   for my $nw(@newwords) {
#      push @words, $nw if !grep(/$nw/, @words);
      #say "dup $nw" if grep(/$nw/, @words);
#   }
#}
say "related words:";
print Dumper(\@cleanwords);

###
### Queries a WordNet synset.
###
sub query_sense {
    my ($wordnet, $phrase, $sense) = @_;
    say "query phrase $phrase sense $sense";
    my @results = $wordnet->querySense($phrase, $sense);
    my $dump = join(", ", @results);
    say "$sense => $dump" if $dump;
    #say "$sense => ", join(", ", @results) if @results;
    @results;
}

sub query_word {
    my ($wordnet, $phrase, $word) = @_;
    my @results = $wordnet->queryWord($phrase, $word);
    my $dump = join(", ", @results);
    say "$word => $dump" if $dump;
    #say "$sense => ", join(", ", @results) if @results;
    @results;
}
