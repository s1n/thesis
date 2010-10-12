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

sub init {
   my ($self, $filesref) = @_;
   if($filesref->{thes}) {
      $self->mobyobj(Text::Thesaurus::Moby->new) if !defined $self->mobyobj;
      $self->mobyobj->load($filesref->{thes});
   }
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $lexref = $self->lexicon;
   my %newscores;
   my $precount = scalar keys %$lexref;

   for my $line(@{$self->mobyobj->rawdata}) {
      chomp $line;
      my @relatedwords = split /,/, $line;
      my $root = shift @relatedwords;
      @relatedwords = undef && next if !$root;
      chomp @relatedwords;
      #say "rescoring root: $root";
      $newscores{$root}{score} = $lexref->{$root}->{score};
      $newscores{$root}{weight} = $lexref->{$root}->{weight};
      my $rdelta = $self->weigh($lexref->{$root});
      my $log = '';
      for my $w(@relatedwords) {
         next if !$w;
         my $wref = $lexref->{$w};
         die if $w eq "145871383";
         $newscores{$w}{score} = $lexref->{$w}->{score};
         $newscores{$w}{weight} = $lexref->{$w}->{weight};
         $rdelta += $self->weigh($lexref->{$w});
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root}{score} += $delta;
      for my $w(@relatedwords) {
         $newscores{$w}{score} += $delta;
         my $temp = $self->weigh($lexref->{$w});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         if($temp != 0 || $w eq $trace) {
            $log .= "$w($temp|$newscores{$w}{score}|$delta|$upordown), ";
         }
      }

      if($trace eq "*" || $root eq $trace ||
         ($trace && grep {$_ eq $trace} @relatedwords)) {
         my $temp = $self->weigh($lexref->{$root});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say "$root($temp|$newscores{$root}{score}|$rdelta|$upordown), $log";
      }
      undef @relatedwords;
   }
   undef $self->{mobyobj};

   my $postcount = scalar keys %newscores;
   while(my ($key, $score) = each(%newscores)) {
      say "lexicon adjust $key to $score" if $key eq $trace;
      $lexref->{$key}->{score} = $score->{score};
      $lexref->{$key}->{weight} = $self->normalize_weight($lexref->{$key}->{weight},
                                                          $precount,
                                                          $postcount);
   }
   undef %newscores;
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectivity::Seed::MSL - seed algorithm based on Macquarie Seed Lexicon.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

Based on the paper by FIXME to implement a thesaurus based algorithm. The paper
says that if the score of the entire entry for every word added up results in
a positive subjectivity, every word on the line is labeled as positive. The
same applies to negative words.

This module will not modify the I<lexicon> in place until after the entire new
set of scores has been computed. That is, the lexicon is used as a reference
for determining the scores of the words on the line and the result will be
stored in a different object. Each word's lexicon score is only changed by a
difference of 1 at most per line, regardless of how many positive/negative
words are associated. After the entire thesaurus has been processed, the
temporary storage will be written to the I<lexicon>.

=head1 ATTRIBUTES

=head2 mobyobj

The L<Text::Thesaurus::Moby> object that assists with parsing and storing of
the thesaurus data.

=head1 METHODS

=head2 build(trace)

Builds the lexicon according to the paper by FIXME, as described above.

If a I<trace> word is provided, that word will be traced. Passing '*' will
trace all words.

=head2 init(options)

Reads all files that are supported by this seeding algorithm. This should be
run before B<build> as it's considered a setup function. The I<options>
structure is a hash with the key value pointing to an accessible local filename.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
