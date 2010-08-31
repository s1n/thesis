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
   my %newscores;

   #load the thesaurus
   $self->mobyobj->load($self->args->thes);

   for my $line(@{$self->mobyobj->rawdata}) {
      chomp $line;
      my @words = split /,/, $line;
      my $root = shift @words;
      @words = undef && next if !$root;
      chomp @words;
      #say "rescoring root: $root";
      my $rdelta = $self->signed($dictref->{$root});
      for my $w(@words) {
         next if !$w;

         my $delta = 0;
         if(defined $dictref->{$w}) {
            $delta = $self->signed($dictref->{$w});
         }

         if($w eq $self->args->trace || $root eq $self->args->trace) {
            say "adjusting score $root -> $w by $delta";
         }

         $rdelta += $delta;
      }

      my $delta = $self->signed($rdelta);
      for my $w(@words) {
         $newscores{$w} = $delta;
      }
      undef @words;
   }
   undef $self->{mobyobj};

   while(my ($key, $sign) = each(%newscores)) {
      if($key eq $self->args->trace) {
         say "adjusting score $key to $sign";
      }
      $dictref->{$key} += $sign;
   }
   undef %newscores;
}

no Moose;
1;
