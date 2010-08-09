package AI::Subjectivity::Seed;

use Modern::Perl;
use Moose;

has 'patterns' => (is => 'rw', isa => 'HashRef');
has 'dictionary' => (is => 'rw', isa => 'HashRef');
has 'args' => (is => 'rw', isa => 'SeedArgs');

sub read_affixes {
   my $self = shift;
   my $patref = $self->patterns;
   say "Loading affix patterns from", $self->args->affix, " ...";
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

sub save {
   my ($self) = @_;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   open(LEX, '>' . $self->args->lexicon) or
      die "Unable to create lexicon: $!\n";

   #loop over every word in the dictionary
   while(my ($key, $sign) = each(%$dictref)) {
      say LEX "$key, $sign" if 0 != $sign;
   }

   close LEX;
}

sub load {
   my ($self) = @_;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   open(LEX, $self->args->lexicon) or
      die "Unable to open lexicon: $!\n";

   #loop over every word in the dictionary
   while(my $line = <LEX>) {
      chomp $line;
      my @tokens = split /,/, $line;
      next if @tokens != 2;
      $tokens[0] =~ s/^\s+//;
      $tokens[0] =~ s/.\s+$//;
      $tokens[1] =~ s/^\s+//;
      $tokens[1] =~ s/\s+//;
      $dictref->{$tokens[0]} = $tokens[1];
   } 

   close LEX;
}

no Moose;
1;
