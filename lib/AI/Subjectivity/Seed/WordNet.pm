package AI::Subjectivity::Seed::WordNet;
use Modern::Perl;
use WordNet::QueryData;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'wordnet' => (
   is => 'rw',
   isa => 'WordNet::QueryData',
   lazy => 1,
   default => sub { WordNet::QueryData->new('/usr/share/wordnet/dict/') },
);

sub build {
   my $self = shift;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;
   my %senses = ('n' => 'syns',
                 'v' => 'syns',
                 'a' => 'also');

   open(LOG, '>' . $self->args->matchlog) or
      die "Unable to create match log: $!\n";

   #loop over every word in the dictionary
   while(my ($word, $score) = each(%$dictref)) {
      my @relatedwords;
      for my $pos(qw/n v a/) {
         $self->_trace_word("$word\#$pos", $senses{$pos}, \@relatedwords);
      }
      for my $w(@relatedwords) {
         my $delta = 0;
         if($score == abs($score)) {
            $delta = 1;
         } else {
            $delta = -1;
         }
         say "adjusting score $w by $delta";
         my ($trimmed, undef, undef) = split /\#/, $w;
         $dictref->{$trimmed} += $delta;
      }
   }

   while(my ($word, $score) = each(%$dictref)) {
      say LOG "$word, $score";
   }

   close LOG;
}

sub _trace_word {
   my ($self, $root, $sense, $wordsref) = @_;
   #say "tracing $root as $sense";

   my @words = $self->_query_sense($root, $sense);
   for my $w(@words) {
      my @newwords = $self->_query_sense($w, $sense);
      for my $nw(@newwords) {
         #say "checking newword $nw";
         push @$wordsref, $nw if !grep(/$nw/, @$wordsref);
         #say "dup $nw" if grep(/$nw/, @$wordsref);
      }
   }
}

sub _query_sense {
   my ($self, $phrase, $sense) = @_;
   #say "query phrase $phrase sense $sense";
   my @results = $self->wordnet->querySense($phrase, $sense);
   my $dump = join(", ", @results);
   #say "$sense => $dump" if $dump;
   @results;
}

sub _query_word {
   my ($self, $phrase, $word) = @_;
   my @results = $self->wordnet->queryWord($phrase, $word);
   my $dump = join(", ", @results);
   #say "$word => $dump" if $dump;
   @results;
}

no Moose;
1;
