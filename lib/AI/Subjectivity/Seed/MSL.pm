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

         $rdelta += $delta;
      }

#FIXME this seems to be wrong. --trace upset, should be -1
      my $delta = $self->signed($rdelta);
      $newscores{$root} += $delta;
      say "adjusting score $root to $delta ($newscores{$root})" if $root eq $trace;
      for my $w(@words) {
         $newscores{$w} += $delta;
         if($w eq $trace) {
            say "adjusting score $root -> $w to $delta ($newscores{$w})";
         } elsif($root eq $trace) {
            say "adjusting score $root -> $w to $delta ($newscores{$root})";
         }
      }
      undef @words;
   }
   undef $self->{mobyobj};

   while(my ($key, $sign) = each(%newscores)) {
      say "adjusting lexicot $key to $sign" if $key eq $trace;
      $lexref->{$key} += $sign;
   }
   undef %newscores;
}

no Moose;
1;
