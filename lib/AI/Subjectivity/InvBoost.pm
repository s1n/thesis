package AI::Subjectivity::InvBoost;

use Modern::Perl;
use Moose;

has 'error' => (
   is => 'rw',
   isa => 'Num',
   default => sub { 0.0 },
);

has 'alpha' => (
   is => 'rw',
   isa => 'Num',
   default => sub { 1.0 },
);

sub boost {
   my ($self, $reference, $other) = @_;
   my $reflex = $reference->lexicon;
   my $checklex = $other->lexicon;
   my $defweight = 1 / (scalar keys %$reflex);

   #mark all the errors
   $self->error(0);
   $self->alpha(0);
   while(my ($key, $scoreref) = each(%$reflex)) {
      #skip missing labels, cannot reweight
      next if !defined $checklex->{$key} || !defined $checklex->{$key}->{score};

      #snag the signed score values
      my $refsign = $reference->signed($scoreref->{score});
      my $checksign = $reference->signed($checklex->{$key}->{score});

      #fix the weight of the words if they have no weight assigned
      if(!defined $checklex->{$key}->{weight}) {
         $checklex->{$key}->{weight} = $defweight;
      }

      #identify misclassifications and total the error
      if($refsign != $checksign) {
         my $junk = $self->error;
         $self->error($self->error + ($checklex->{$key}->{weight} // $defweight));
         #say "mislabeled '$key', ",
         #    $checklex->{$key}->{score},
         #    ", ",
         #    $checklex->{$key}->{weight},
         #    ", error = ",
         #    $self->error;
      } else {
         #say "labeled '$key', ",
         #    $checklex->{$key}->{score},
         #    ", ",
         #    $checklex->{$key}->{weight},
         #    ", error = ",
         #    $self->error;
      }
   }

   die "Error: ", $self->error, "\n" if $self->error > 1;

   #compute alpha
   return if $self->error == 0;
   $self->alpha(0.5 * log((1 - $self->error) / $self->error));
   say "alpha: ", $self->alpha;
   say "error: ", $self->error;

   #recompute weights
   my $totalw = 0;
   while(my ($key, $scoreref) = each(%$reflex)) {
      #skip missing labels, cannot reweight
#FIXME what do we do with the weights of the words we dont have reference data?
      next if !defined $checklex->{$key} || !defined $checklex->{$key}->{score};

      #snag the signed score values
      my $refsign = $reference->signed($scoreref->{score});
      my $checksign = $reference->signed($checklex->{$key}->{score});

      #this increases weight of misclassifications, we want the opposite
      my $expsign = $refsign == $checksign ? 1 : -1;
      #identify correct classifications and recompute the weights
      $checklex->{$key}->{weight} *= exp($self->alpha * $expsign);
      #$checklex->{$key}->{weight} *= exp(log($self->alpha) * $refsign * $checksign);
      $totalw += $checklex->{$key}->{weight};
   }
   say "total weight: $totalw";

   #normalize the weights to a probability distribution
   while(my ($key, $scoreref) = each(%$reflex)) {
      #skip missing labels, cannot reweight
#FIXME what do we do with the weights of the words we dont have reference data?
      next if !defined $checklex->{$key} || !defined $checklex->{$key}->{score};

      #snag the signed score values
      my $refsign = $reference->signed($scoreref->{score});
      my $checksign = $reference->signed($checklex->{$key}->{score});
      #this increases weight of misclassifications, we want the opposite
      my $expsign = $refsign == $checksign ? 1 : -1;
      $checklex->{$key}->{weight} /= $totalw;

      #say "recomputed weights for '",
      #    $key,
      #    "' => ",
      #    $checklex->{$key}->{score},
      #    ", ",
      #    $checklex->{$key}->{weight},
      #    " from ",
      #    exp($self->alpha * $expsign);
   }
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
