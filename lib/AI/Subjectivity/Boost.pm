package AI::Subjectivity::Boost;

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
   default => sub { 0.0 },
);

sub offline_boost {
   my ($self, $reference, $other) = @_;
   my $reflex = $reference->lexicon;
   my $checklex = $other->lexicon;
   while(my ($key, $scoreref) = each(%$reflex)) {
      #skip missing labels, cannot reweight
      next if !defined $checklex->{$key}->{score};

      #snag the signed score values
      my $refsign = $reflex->signed($scoreref->{score});
      my $checksign = $reflex->signed($checklex->{$key}->{score});

      #identify misclassifications and total the error
      if($refsign != $checksign) {
         $self->error($self->error + $scoreref->{weight});
      }
   }

   while(my ($key, $scoreref) = each(%$reflex)) {
      #skip missing labels, cannot reweight
      next if !defined $checklex->{$key}->{score};

      #snag the signed score values
      my $refsign = $reflex->signed($scoreref->{score});
      my $checksign = $reflex->signed($checklex->{$key}->{score});

      #identify correct classifications and recompute the weights
      my $expsign = $refsign == $checksign ? 1 : -1;
      $checklex->{$key}->{weight} *= exp($self->alpha * $expsign);
      say "recomputed weights for '", $key, "' => ", $checklex->{$key}->{score}, ", ", $checklex->{$key}->{weight};
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
