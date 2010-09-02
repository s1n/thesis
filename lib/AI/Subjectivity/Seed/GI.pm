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

sub read_data_files {
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   $self->build_tags("Pos", 1, $trace);
   $self->build_tags("Neg", -1, $trace);
}

sub build_tags {
   my ($self, $tag, $delta, $trace) = @_;
   my $lexref = $self->lexicon;
   my %newscores;

   #load the thesaurus
   $self->giobj->reset;
   $self->giobj->load($tag);

   for my $link(@{$self->giobj->rawdata}) {
      my $text = $link->text;
      my @tokens = split /\#/, $text;
      $text = lc shift @tokens;
      $lexref->{$text} += $delta;

      if($text eq $trace) {
         say "adjusting score $text by $delta";
      }
   }
}

no Moose;
1;
