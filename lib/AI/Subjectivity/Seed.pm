package AI::Subjectivity::Seed;
use Modern::Perl;
use Moose;

has 'patterns' => (is => 'rw', isa => 'HashRef');
has 'dictionary' => (is => 'rw', isa => 'HashRef');
has 'args' => (is => 'rw', isa => 'SeedArgs');

sub read_affixes {
   my $self = shift;
   my $patref = $self->patterns;
   say "Loading affix patterns from $self->args->affix ...";
   open(AFFIX, $self->args->affix) or
       die "Unable to open affix pattern file ", $self->args->affix, ": $!\n";
   my @pats = <AFFIX>;
   chomp @pats;
   for my $p(@pats) {
      next if $p =~ /^#/;
      my @parts = split /,/, $p;
      my $pp = qr/$parts[0]/;
      $patref->{$parts[1]} = $parts[0];
      #say "+|$parts[0] -|", $parts[1];
   }
   close AFFIX;
   return $patref;
}

sub read_dict {
   my $self = shift;
   my $dictref = $self->dictionary;

   #slurp the dictionary
   for my $d(@{$self->args->dict}) {
      say "Loading dictionary $d ...";
      open(DICT, $d) or
         die "Unable to open dictionary ", $d, ": $!\n";
      while(my $line = <DICT>) {
         chomp $line;
         $dictref->{$line} = 0;
      }
      close DICT;
   }
   return $dictref;
}

no Moose;
1;
