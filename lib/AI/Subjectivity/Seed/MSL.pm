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

has 'thes' => (
   is => 'rw',
   isa => 'Str',
   default => sub { "" },
);

sub read_data_files {
   my ($self, $filesref) = @_;
   if($filesref->{thes}) {
      $self->mobyobj->load($filesref->{thes});
   }
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $lexref = $self->lexicon;
   my %newscores;

   for my $line(@{$self->mobyobj->rawdata}) {
      chomp $line;
      my @words = split /,/, $line;
      my $root = shift @words;
      @words = undef && next if !$root;
      chomp @words;
      #say "rescoring root: $root";
      my $rdelta = $self->signed($lexref->{$root});
      for my $w(@words) {
         next if !$w;

         my $delta = 0;
         if(defined $lexref->{$w}) {
            $delta = $self->signed($lexref->{$w});
         }

         if($w eq $trace || $root eq $trace) {
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
      if($key eq $trace) {
         say "adjusting score $key to $sign";
      }
      $lexref->{$key} += $sign;
   }
   undef %newscores;
}

no Moose;
1;
