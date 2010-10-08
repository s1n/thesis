#!/usr/bin/perl

package ScoreArgs;
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

1;

use Data::Dumper;
use AI::Subjectivity::Seed;
use Text::Corpus::NASA;

my $arguments = ScoreArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
my $corpus = Text::Corpus::NASA->new;
$ref->load($arguments->lexicon);
$corpus->load($arguments->corpus);

for my $cw(@{$corpus->rawdata}) {
   say "Checking corpus word: $cw...";
   if(defined $ref->lexicon->{$cw}) {
      print "$cw => ";
      print $ref->lexicon->{$cw}->{score}, ", ";
      print $ref->lexicon->{$cw}->{weight}, "\n";
   }
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
