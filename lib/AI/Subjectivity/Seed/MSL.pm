package AI::Subjectivity::Seed::MSL;

use Modern::Perl;
use Text::Thesaurus::Moby;
use Moose;
use Devel::Cycle;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'mobyobj' => (
   is => 'rw',
   isa => 'Text::Thesaurus::Moby',
   lazy => 1,
   default => sub { Text::Thesaurus::Moby->new }
);

sub build {
   my $self = shift;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   #load the thesaurus
   $self->mobyobj->load($self->args->thes);

   for my $line(@{$self->mobyobj->rawdata}) {
      chomp $line;
      my @words = split /,/, $line;
      my $root = shift @words;
      @words = undef && next if !$root;
      chomp @words;
      #say "rescoring root: $root";
      for my $w(@words) {
         next if !$w;
         my $delta = ($dictref->{$root} && 
                      $dictref->{$root} == abs($dictref->{$root})) ? 1 : -1;
         #say "adjusting score $w by $delta";
         if($w !~ /\S+/) {
            say "JUNK: $line";
         }
         $dictref->{$root} += $delta;
      }
      @words = undef;
   }
}

no Moose;
1;
