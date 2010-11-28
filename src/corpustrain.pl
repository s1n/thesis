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

has 'output' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Output file to write the trained datum into.',
   default => 'output.log',
   cmd_flag => 'output',
   cmd_aliases => 'o',
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

has 'classes' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'File containing the class labels.',
   default => 'classes.dat',
   cmd_flag => 'classes',
   cmd_aliases => 'C',
);

1;

use Data::Dumper;
use AI::Subjectivity::Seed;
use Term::ProgressBar;

sub log2 {
   my ($value) = @_;
   return 0 if !defined $value || $value == 0;
   return log($value) / log(2);
}

sub doit {
   my ($cmd) = @_;
   my $ret;
   chomp($ret = `$cmd`);
   return $ret;
}

sub div {
   my ($num, $dem) = @_;
   return 0 if !$dem;
   return $num / $dem;
}

sub mult {
   my ($num, $dem) = @_;
   return 0 if !$dem;
   return $num * $dem;
}

my $arguments = CorpusArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
$ref->load($arguments->reference);

open CLASSES, $arguments->classes or die "Unable to load class labels: $!\n";
my @classes = <CLASSES>;
chomp @classes;
close CLASSES;

open OUTPUT, '>'.$arguments->output or die "Unable to write to file: $!\n";

my $corp = $arguments->corpus;
my $wcl = "wc -l";
my $grep = "egrep -i";
my $ungrep = "$grep -iv";

my $ccount = doit("cat $corp | $wcl");
say "Checking $ccount sentences for matches...";
my $pb = Term::ProgressBar->new({count => $ref->size * scalar @classes,
                                 name => "Processing",
                                 ETA => 'linear'});
$pb->minor(0);
$pb->max_update_rate(1);
my $sent = 0;

my %p_of_cj;
my %p_of_notcj;
my %p_of_cj_given_w;
my %p_of_notcj_given_w;
my %p_of_cj_given_notw;
my %p_of_notcj_given_notw;
my $p_of_w;
my $p_of_notw;
my $size_of_cj;
while(my ($w, $scoreref) = each %{$ref->lexicon}) {
   #say "checking $word...";
   my $word = quotemeta $w;
   $p_of_w = doit("$grep \"\\b$word\\b\" $corp | $wcl");
   $p_of_notw = doit("$ungrep \"\\b$word\\b\" $corp | $wcl");
   next if $p_of_w == 0;

   say "P(w=$word) = $p_of_w" if $arguments->verbose;
   say "P(w!=$word) = $p_of_notw" if $arguments->verbose;

   for my $c(@classes) {
      my ($clause1, $clause2, $clause3) = (0, 0, 0);
      $p_of_cj{$c} = doit("$grep ',.*$c' $corp | $wcl");
      $p_of_cj_given_w{$c} = doit("$grep ',.*$c' $corp | $grep \"\\b$word\\b\" | $wcl");
      $p_of_cj_given_notw{$c} = doit("$grep ',.*$c' $corp | $ungrep \"\\b$word\\b\" | $wcl");
      $p_of_notcj{$c} = doit("$ungrep ',.*$c' $corp | $wcl");
      $p_of_notcj_given_w{$c} = doit("$ungrep ',.*$c' $corp | $grep \"\\b$word\\b\" | $wcl");
      $p_of_notcj_given_notw{$c} = doit("$ungrep ',.*$c' $corp | $ungrep \"\\b$word\\b\" | $wcl");

      say "P(cj=$c) = $p_of_cj{$c}" if $arguments->verbose;
      say "P(cj!=$c) = $p_of_notcj{$c}" if $arguments->verbose;
      say "P(cj=$c|w=$word) = $p_of_cj_given_w{$c}" if $arguments->verbose;
      say "P(cj=$c|w!=$word) = $p_of_cj_given_notw{$c}" if $arguments->verbose;
      say "P(cj!=$c|w=$word) = $p_of_notcj_given_w{$c}" if $arguments->verbose;
      say "P(cj!=$c|w!=$word) = $p_of_notcj_given_notw{$c}" if $arguments->verbose;

      $clause1 -= div($p_of_cj{$c}, $ccount) * log2(div($p_of_cj{$c}, $ccount));
      $clause1 -= div($p_of_notcj{$c}, $ccount) * log2(div($p_of_notcj{$c}, $ccount));
      $clause2 -= div($p_of_cj_given_w{$c}, $p_of_w) * log2(div($p_of_cj_given_w{$c}, $p_of_w));
      $clause2 -= div($p_of_notcj_given_w{$c}, $p_of_w) * log2(div($p_of_notcj_given_w{$c}, $p_of_w));
      $clause3 -= div($p_of_cj_given_notw{$c}, $p_of_notw) * log2(div($p_of_cj_given_notw{$c}, $p_of_notw));
      $clause3 -= div($p_of_notcj_given_notw{$c}, $p_of_notw) * log2(div($p_of_notcj_given_notw{$c}, $p_of_notw));
      #$clause1 -= ($p_of_cj{$c}/$ccount) * log2($p_of_cj{$c} / $ccount);
      #$clause1 -= ($p_of_notcj{$c}/$ccount) * log2($p_of_notcj{$c} / $ccount);
      #$clause2 -= ($p_of_cj_given_w{$c}/$p_of_w) * log2($p_of_cj_given_w{$c}/$p_of_w);
      #$clause2 -= ($p_of_notcj_given_w{$c}/$p_of_w) * log2($p_of_notcj_given_w{$c}/$p_of_w);
      #$clause3 -= ($p_of_cj_given_notw{$c}/$p_of_notw) * log2($p_of_cj_given_notw{$c}/$p_of_notw);
      #$clause3 -= ($p_of_notcj_given_notw{$c}/$p_of_notw) * log2($p_of_notcj_given_notw{$c}/$p_of_notw);

      say "Entropy(cj=$c) = $clause1" if $arguments->verbose;
      say "Entropy(w=$word) = $clause2" if $arguments->verbose;
      say "Entropy(w!=$word) = $clause3" if $arguments->verbose;
      my $clause4 = (($p_of_w/$ccount)*$clause2) + (($p_of_notw/$ccount)*$clause3);
      say "Entropy(cj=$c|w=$word) = $clause4" if $arguments->verbose;
      my $gain = $clause1 - $clause4;
      say "IG(cj=$c,w=$word) = $clause1 - $clause4 = $gain" if $arguments->verbose;
      say OUTPUT "$c, $w, $gain";
      $pb->update(++$sent);
   }
}
close OUTPUT;
$pb->update($ref->size);

=pod

=head1 NAME

corpustrain.pl - Calculates the information gain for each word and class.

=head1 SYNOPSIS

 # builds the information gain list
 % corpustrain.pl --corpus trainingdata.txt --reference lexicon.dat \
                  --classes shapingfactors.txt --output train.log

=head1 DESCRIPTION

Finds all words in the corpus and reports their score and prediction from the
reference lexicon.

=head1 OPTIONS

=head2 --corpus|c

Sets the corpus file. This corpus file will be loaded and words will be split
by whitespace or punctuation. Only words found in the lexicon will be reported
as existing.

=head2 --reference|r

Sets the reference lexicon, which will be the authority.

=head2 --output|o

Sets the output data file.

=head2 --classes|r

Sets the list of classes that can be applied to each report.

=head2 --verbose|v

Sets the verbosity mode to true; prints the calculates as they are performed.

=cut

__END__
