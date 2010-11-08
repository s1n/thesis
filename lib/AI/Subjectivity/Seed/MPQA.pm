package AI::Subjectivity::Seed::MPQA;

use Modern::Perl;
use Text::Lexicon::MPQA;
use Data::Dumper;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'mpqaobj' => (
   is => 'rw',
   isa => 'Text::Lexicon::MPQA',
   lazy => 1,
   default => sub { Text::Lexicon::MPQA->new }
);

sub init {
   my ($self, $filesref) = @_;
   if($filesref->{mpqa}) {
      $self->mpqaobj->load($filesref->{mpqa});
   } else {
      say "MPQA input data file not specified.";
   }
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $lexref = $self->lexicon;

   for my $line(@{$self->mpqaobj->rawdata}) {
      #die Dumper($line);
      my $root = $line->{word1};
      next if !$root || $self->is_stripwords($root);
      my $delta = 0;
      if($line->{priorpolarity} eq "negative") {
         $delta = -1;
      } elsif($line->{priorpolarity} eq "positive") {
         $delta = 1;
      }

      #print debug / trace code
      if($trace eq "*" || $root eq $trace) {
         my $temp = $lexref->{$root}->{score} // 0;
         my $newtemp = $temp + $delta;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say "$root($temp|$newtemp|$delta|$upordown)";
      }

      $lexref->{$root}->{score} += $delta;
   }
   undef $self->{mpqaobj};
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectipqavity::Seed::MPQA - seed algorithm based on Macquarie Seed Lexicon.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

Uses the MPQA manually marked lexicon as a source of seed data. Currently, only
the I<priorpolarity> and I<word1> words are used. There are several fields
for each entry, but most appear unused or not applicable.

This module will not modify the I<lexicon> in place until after the entire new
set of scores has been computed. That is, the lexicon is used as a reference
for determining the scores of the words on the line and the result will be
stored in a different object. Each word's lexicon score is only changed by
either -1 or 1 for negative or positive words respecitively. This is because
the MPQA data does not contain duplicates and each entry is only marked as either
positive or negative. After the entire lexicon is processed, the temporary storage
will be written to the I<lexicon>.

=head1 ATTRIBUTES

=head2 mpqaobj

The L<Text::Lexicon::MPQA> object that assists with parsing and storing of
the MPQA data.

=head1 METHODS

=head2 build(trace)

Builds the lexicon to match the MPQA data.

If a I<trace> word is provided, that word will be traced. Passing '*' will
trace all words.

=head2 init(options)

Reads all files that are supported by this seeding algorithm. This should be
run before B<build> as it's considered a setup function. The I<options>
structure is a hash with the key value pointing to an accessible local filename.

Current supports the following options:

 mpqa - MPQA data file

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
