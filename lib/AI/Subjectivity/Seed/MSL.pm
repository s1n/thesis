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
      my $log = '';
      for my $w(@words) {
         next if !$w;

         my $delta = 0;
         if(defined $lexref->{$w}) {
            $delta = $self->signed($lexref->{$w});
         }

         $rdelta += $delta;
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root} += $delta;
      for my $w(@words) {
         $newscores{$w} += $delta;
         my $temp = $lexref->{$w} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         $log .= "$w($temp|$newscores{$w}|$upordown), ";
      }
      if($trace eq "*" || $root eq $trace || ($trace && $log && $log =~ /$trace/)) {
         my $temp = $lexref->{$root} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say "$root($temp|$newscores{$root}|$upordown) $log";
      }
      undef @words;
   }
   undef $self->{mobyobj};

   while(my ($key, $sign) = each(%newscores)) {
      say "lexicon adjust $key to $sign" if $key eq $trace;
      $lexref->{$key} += $sign;
   }
   undef %newscores;
}

no Moose;
1;
