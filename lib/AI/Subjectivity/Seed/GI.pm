package AI::Subjectivity::Seed::GI;

use Modern::Perl;
use Text::Lexicon::GI;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'giobj' => (
   is => 'rw',
   isa => 'Text::Lexicon::GI',
   lazy => 1,
   default => sub { Text::Lexicon::GI->new }
);

sub init {
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   $self->build_tags("Pos", 1, $trace);
   $self->build_tags("Neg", -1, $trace);
}

sub build_tags {
   my ($self, $tag, $delta, $trace) = @_;
   my $lexref = $self->lexicon;
   my %newscores;

   #load the thesaurus
   $self->giobj->reset;
   $self->giobj->load($tag);

   for my $link(@{$self->giobj->rawdata}) {
      my $text = $link->text;
      my @tokens = split /\#/, $text;
      $text = lc shift @tokens;
      next if !$text || $self->is_stopword($text);
      $lexref->{$text}->{score} += $delta;

      if($text eq $trace) {
         say "adjusting score $text by $delta";
      }
   }
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectivity::Seed::GI - seeds based on the General Inquirer lexicon.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

The General Inquirer lexicon was built by humans and is considered authorative,
though is severely limited in size. This module is responsible for automating
the download process through L<Text::Lexicon::GI>. Once the B<build> method
is finished, the B<lexicon> attribute will have only I<POSITIV> and I<NEGATIV>
tagged words. It is possible to load other tags by directly calling the
B<build_tags> method; use with caution.

=head1 ATTRIBUTES

=head2 giobj

L<Text::Lexicon::GI> lexicon object that automates the downloading.

=head1 METHODS

=head2 init(options) 

Unused. This module has no options to load.

=head2 build(trace)

Loads 2 different tagged GI lexicons: I<POSITIV> and I<NEGATIV>. Each one goes
into the B<lexicon> attribute with added scores of 1 and -1 respectively.

If a I<trace> word is provided, that word will be traced. Passing '*' will
trace all words.

=head2 build_tags(tag, delta, trace)

Loads an arbitrarily named tagged GI lexicon and stores in the B<lexicon>
attribute with the score specified.

A I<delta> score is required to know how much each tagged word's lexicon
score is changed by upon discovery.

If a I<trace> word is provided, that word will be traced. Passing '*' will
trace all words.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
