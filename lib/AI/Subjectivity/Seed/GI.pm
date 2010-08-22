package AI::Subjectivity::Seed::GI;

use Modern::Perl;
use Text::Thesaurus::GI;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'giobj' => (
   is => 'rw',
   isa => 'Text::Thesaurus::GI',
   lazy => 1,
   default => sub { Text::Thesaurus::GI->new }
);

sub build {
   my $self = shift;
   $self->build_tags("Pos", 1);
   $self->build_tags("Neg", -1);
}

sub build_tags {
   my ($self, $tag, $delta) = @_;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;
   my %newscores;

   #load the thesaurus
   $self->giobj->reset;
   $self->giobj->load($tag);

   for my $link(@{$self->giobj->rawdata}) {
      my $text = $link->text;
      my @tokens = split /\#/, $text;
      $text = lc shift @tokens;
      $dictref->{$text} += $delta;

      if($text eq $self->args->trace) {
         say "adjusting score $text by $delta";
      }
   }
}

no Moose;
1;
