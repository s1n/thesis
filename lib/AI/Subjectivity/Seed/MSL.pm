package AI::Subjectivity::Seed::MSL;

use Modern::Perl;
use Text::Thesaurus::Moby;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'mobyobj' => (
   is => 'rw',
   isa => 'Text::Thesaurus::Moby',
   lazy => 1,
   default => sub { Text::Thesaurus::Moby->new }
);

#FIXME none of this works yet
sub build {
   my $self = shift;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   #load the thesaurus
   $self->mobyobj->load($self->args->thes);

   #loop over every word in the dictionary
   while(my ($word, $score) = each(%$dictref)) {
      my @relatedwords;
      $self->_trace_word($word, \@relatedwords);
      for my $w(@relatedwords) {
         my $delta = ($score == abs($score)) ? 1 : -1;
         say "adjusting score $w by $delta" if $delta < 0;
         my ($trimmed, undef, undef) = split /\#/, $w;
         $dictref->{$trimmed} += $delta;
      }
   }
}

sub _trace_word {
   my ($self, $root, $wordsref) = @_;
   #say "tracing $root as $sense";

   my @words = $self->_query_word($root);
   for my $w(@words) {
      my @newwords = $self->_query_word($w);
      for my $nw(@newwords) {
         #say "checking newword $nw";
         push @$wordsref, $nw if !grep(/$nw/, @$wordsref);
         #say "dup $nw" if grep(/$nw/, @$wordsref);
      }
   }
}

sub _query_word {
   my ($self, $word) = @_;
#FIXME integrate Text::Thesaurus::Moby
   #my @results = $self->wordnet->queryWord($phrase, $word);
   my $results = $self->mobyobj->synset($word);
   #my $dump = join(", ", @results);
   #say "$word => $dump" if $dump;
   return @$results if $results;
   my @junk;
   return @junk;
}

no Moose;
1;
