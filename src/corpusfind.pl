#!/usr/bin/perl

package CorpusArgs;
use Data::Dumper;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'corpus' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'corpus.dat',
   documentation => 'Corpus file with words, sentences, or paragraphs.',
   cmd_flag => 'corpus',
   cmd_aliases => 'c',
);

has 'reference' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Lexicon to use as reference.',
   default => 'lexicon.dat',
   cmd_flag => 'reference',
   cmd_aliases => 'r',
);

has 'lexicon' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Lexicon to write the matches to.',
   default => 'output.dat',
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
use Text::Corpus::ASRS;
use Term::ProgressBar;

my $arguments = CorpusArgs->new_with_options;
my $output = AI::Subjectivity::Seed->new;
my $ref = AI::Subjectivity::Seed->new;
my $corpus = Text::Corpus::ASRS->new({file => $arguments->corpus});
$ref->load($arguments->reference);
eval { $output->load($arguments->lexicon); };

my %wordsfound;
my $sentencesfound = 0;
my $ccount = `wc -l $arguments->{corpus}`;
chomp $ccount;
say "Checking $ccount sentences for matches...";
my $pb = Term::ProgressBar->new({count => $ref->size,
                                 name => "Preprocessing",
                                 ETA => 'linear'});
$pb->minor(0);
$pb->max_update_rate(1);
my $sent = 0;
while(my ($word, $scoreref) = each %{$ref->lexicon}) {
   my $args = !$arguments->matches ? "-v" : "";
   #say "checking $word...";
   my $lc = `egrep "\\W$word\\W" $arguments->{corpus} | wc -l`;
   if($lc > 0) {
      #say "FOUND $word";
      $output->lexicon->{$word}->{score} = $ref->lexicon->{$word}->{score};
      $output->lexicon->{$word}->{weight} = $ref->lexicon->{$word}->{weight};
      $wordsfound{$word} += $lc;
   }
   $pb->update(++$sent);
}
$output->save($arguments->lexicon);
$pb->update($ref->size);

#print the results
my $count = 0;
while(my ($w, $c) = each %wordsfound) {
   $count += $c;
}
say "sentences Searched: $sent";
say "Total Word Matches: $count";
say "Unique Word Matches:", scalar keys %wordsfound;
#say "Total sentence Matches: $sentencesfound";

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
