package AI::Subjectivity::Seed;

use Modern::Perl;
use Moose;

has 'lexicon' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub { { } },
);

has 'trace' => (
   is => 'rw',
   isa => 'Str',
   default => sub { "" },
);

sub save {
   my ($self, $lex) = @_;
   my $lexref = $self->lexicon;

   open(LEX, ">$lex") or
      die "Unable to create lexicon: $!\n";

   #loop over every word in the lexicon 
   while(my ($key, $sign) = each(%$lexref)) {
      say LEX "$key, $sign" if 0 != $sign;
   }

   close LEX;
}

sub load {
   my ($self, $lex) = @_;
   my $lexref = $self->lexicon;

   open(LEX, $lex) or die "Unable to open lexicon: $!\n";

   #loop over every word in the lexicon
   while(my $line = <LEX>) {
      chomp $line;
      my @tokens = split /,/, $line;
      next if @tokens != 2;
      $tokens[0] =~ s/^\s+//;
      $tokens[0] =~ s/.\s+$//;
      $tokens[1] =~ s/^\s+//;
      $tokens[1] =~ s/\s+//;
      $lexref->{$tokens[0]} = $tokens[1];
   } 

   close LEX;
}

sub accuracy {
   my ($self, $other) = @_;
   #my $measref = Stats::Measure->new;
   my $lexref = $self->lexicon;
   my $otherlexref = $other->lexicon;

   my ($correct, $total) = (0, 0);
   #loop over every word in the lexicon
   while(my ($key, $sign) = each(%$lexref)) {
      next if(!defined $otherlexref->{$key});
      $total++;
      #$correct++ if(_sign($sign) == _sign($otherlexref->{$key}));
      if($self->signed($sign) == $self->signed($otherlexref->{$key})) {
         $correct++;
      } else {
         say "MISLABEL: $key => $sign / $otherlexref->{$key}";
      }
   }
   return $correct / $total;
}

sub signed {
   my ($self, $value) = @_;
   return 0 if !$value;
   return 1 if($value == abs($value));
   return -1;
}

no Moose;
1;
