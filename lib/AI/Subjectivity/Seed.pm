package AI::Subjectivity::Seed;

use Stats::Measure;
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
   my $measref = Stats::Measure->new;
   my $reference_lexicon = $self->lexicon;
   my $check_lexicon = $other->lexicon;
   while(my ($key, $sign) = each(%$reference_lexicon)) {
      #false positive, missing results are considered mislabeled
      if(!defined $check_lexicon->{$key}) {
         say "unknown: $key";
         $measref->unknown(1);
         #$measref->falsenegative(1);
         next;
      }

      my $refsign = $self->signed($sign);
      my $checksign = $self->signed($check_lexicon->{$key});
      if(0 < $refsign) {
         if($refsign == $checksign) {
            #actual positive, true positive (correct label)
            say "true positive: $key => $refsign / $checksign";
            $measref->truepositive(1);
         } else {
            #actual positive, false negative (wrong label)
            say "false negative: $key => $refsign / $checksign";
            $measref->falsenegative(1);
         }
      } else {
         if($refsign == $checksign) {
            #actual negative, true negative (correct label)
            say "true negative: $key => $refsign / $checksign";
            $measref->truenegative(1);
         } else {
            #actual negative, false positive (wrong label)
            say "false positive: $key => $refsign / $checksign";
            $measref->falsepositive(1);
         }
      }
   }
   return $measref;
}

sub signed {
   my ($self, $value) = @_;
   return 0 if !$value;
   return 1 if($value == abs($value));
   return -1;
}

no Moose;
1;
