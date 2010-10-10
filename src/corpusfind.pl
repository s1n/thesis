#!/usr/bin/perl

package ScoreArgs;
use Data::Dumper;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'corpus' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'corpus.dat',
   documentation => 'Corpus file with words, sentances, or paragraphs.',
   cmd_flag => 'corpus',
   cmd_aliases => 'c',
);

has 'lexicon' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Lexicon to use as reference.',
   default => 'lexicon.dat',
   cmd_flag => 'lexicon',
   cmd_aliases => 'l',
);

has 'matches' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Bool',
   documentation => 'Dictates whether matches or non-matches are reported.',
   default => sub { 1 },
   cmd_flag => 'matches',
   cmd_aliases => 'm',
);

has 'verbose' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Bool',
   documentation => 'Enables verbosity when scanning.',
   default => sub { 0 },
   cmd_flag => 'verbose',
   cmd_aliases => 'v',
);

1;

use Data::Dumper;
use AI::Subjectivity::Seed;
use Text::Corpus::NASA;

my $arguments = ScoreArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
my $corpus = Text::Corpus::NASA->new({file => $arguments->corpus});
$ref->load($arguments->lexicon);

my @words;
while($corpus->next(\@words)) {
   for my $cw(@words) {
      if(UNIVERSAL::isa($cw, "ARRAY")) {
         #die Dumper($cw);
         push @words, @$cw;
         next;
      }
      say "Checking corpus word: $cw..." if $arguments->verbose;
      if(($arguments->matches && defined $ref->lexicon->{$cw}) ||
         (!$arguments->matches && !defined $ref->lexicon->{$cw})) {
         print "word=$cw";
         if($arguments->verbose) {
            print ", score=", $ref->lexicon->{$cw}->{score};
            print ", weight=", $ref->lexicon->{$cw}->{weight};
         }
         print "\n";
      }
   }
   @words = [];
}

=pod

=head1 NAME

corpusfind.pl - Finds trained lexicon words in the corpus.

=head1 SYNOPSIS

 # checks the file lines.txt to find words trained in the lexicon lexicon.dat.
 % corpusfind.pl --corpus lines.txt --lexicon lexicon.dat

=head1 DESCRIPTION

Finds all words in the corpus and reports their score and prediction from the
reference lexicon.

=head1 OPTIONS

=head2 --corpus|c

Sets the corpus file. This corpus file will be loaded and words will be split
by whitespace or punctuation. Only words found in the lexicon will be reported
as existing.

=head2 --lexicon|l

Sets the reference lexicon, which will be the authority.

=cut

__END__
