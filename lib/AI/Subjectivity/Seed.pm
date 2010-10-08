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
   my $keycount = scalar keys %$lexref;
   while(my ($key, $scoreref) = each(%$lexref)) {
      if(0 != $scoreref->{score}) {
         say LEX "$key, $scoreref->{score}, ", $scoreref->{weight} // (1 / $keycount);
      }
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
      next if @tokens < 1;
      $tokens[$_] =~ s/^\s+// for 0..$#tokens;
      $tokens[$_] =~ s/.\s+$// for 0..$#tokens;
      $lexref->{$tokens[0]}->{score} = $tokens[1] // 0;
      $lexref->{$tokens[0]}->{weight} = $tokens[2] // 0;
   } 

   close LEX;
}

sub accuracy {
   my ($self, $other) = @_;
   my $measref = Stats::Measure->new;
   my $reference_lexicon = $self->lexicon;
   my $check_lexicon = $other->lexicon;
   while(my ($key, $scoreref) = each(%$reference_lexicon)) {
      #false positive, missing results are considered mislabeled
      if(!defined $check_lexicon->{$key}) {
         say "unknown: $key";
         $measref->unknown(1);
         #$measref->falsenegative(1);
         next;
      }

      my $refsign = $self->signed($scoreref->{score});
      my $checksign = $self->signed($check_lexicon->{$key}->{score});
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

sub _normalize {
   my ($self, $string) = @_;
   chomp $$string;
   $$string =~ s/_/ /g;
   $$string = lc $$string;
}

sub weigh {
   my ($self, $wordref) = @_;
   my $nom = $wordref->{score} // 0;
   my $denom = $wordref->{weight} // 1;
   return $nom / $denom;
}

sub normalize_weight {
   my ($self, $weight, $precount, $postcount, $isnew) = @_;
   my $newcount = $postcount - $precount;
   return $weight * ($newcount / $postcount) if $isnew;
   return $weight * ($precount / $postcount);
   #return $weight * ($newwordcount / $newtotalwordcount) if $isnew;
   #return $weight * (($newtotalwordcount - $newwordcount) / $newtotalwordcount);
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectivity::Seed - base class for all seeding algorithms.

=head1 SYNOPSIS

 #instantiate a new Seed object
 my $seed = "AI::Subjectivity::Seed::$seeder"->new;

 #load the previous lexicon file, may throw exception (die) upon failure
 eval { $seed->load($lexicon_file); };
 if($@) {
    say "Failed to load lexicon ", $lexicon_file, " skipping";
 }

 #load all supported data files (some may not be used)
 $seed->read_data_files({thes => $thes_file,
                         dict => $dict_file,
                         affix => $affix_file});

 #run the build, this may take a while
 $seed->build($trace_word);

 #write the lexicon back to the file
 $seed->save($lexicon_file);
 undef $seed;

=head1 DESCRIPTION

All seeding algorithms should follow the same interaction as they share many
things in common. No matter the algorithm, the destination lexicon file will
be of the same format, so the B<load> and B<save> will be common. Also, this
means that lexicons built from two different algorithms can be loaded into
this class and compared directly with the B<accuracy> method.

By extending this class, subclasses can access its lexicon by the I<lexicon>
attribute.

A potential point that will need refactoring is the trace attribute. This is
something that all algorithms should have in common but wind up implementing
uniquely to the problem they represent. 

=head1 ATTRIBUTES

=head2 lexicon(data)

Contains the current lexicon data. This is stored as a hash:

 word => lex_score

where I<word> is a unique lexicon word and I<lex_score> is the lexicon score
for the I<word>. The higher the score, the more positive the word; conversely,
the lower the score, the more negative the word.

If the I<data> parameter is not specified, this is an accessor, otherwise a
modifier. B<It is not recommended to use this method as a modifier.>

=head2 trace(word)

Single word to trace. This word may appear anywhere found by the algorithm used.
If I<word> is not specified, this is an accessor, otherwise a modifier.

=head1 METHODS

=head2 new

Constructs a new instance. For this class, this is a generic object that is
incapable of building a seeded lexicon.

=head2 load

Loads a lexicon file into memory. Afterwards, the lexicon can be accessed via
the B<lexicon> attribute.

=head2 save

Saves the current lexicon data to a file.

=head2 accuracy

Compares two lexicons and returns a L<Stats::Measure>, which can report various
accuracy measures.

=head2 signed

Returns -1 for negative values, 1 for positive values, and 0 otherwise.

=head1 LEXICON

Lexicons are stored with 1 word and subjectivity score per line. The line has
the following format:

 word_1,score_1
 ...
 word_n,score_n

where I<word_n> is the nth word and I<score_n> is the score for the same (nth)
word. The score should be either positive or negative, but indeterminate scores
may also be present.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
