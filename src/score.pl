#!/usr/bin/perl

package ScoreArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'base' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   cmd_flag => 'base',
   cmd_aliases => 'b',
);

has 'other' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   cmd_flag => 'other',
   cmd_aliases => 't',
);

1;

use lib '../lib';
use Data::Dumper;
use AI::Subjectivity::Seed;

my $arguments = ScoreArgs->new_with_options;
my $base = AI::Subjectivity::Seed->new;
my $other = AI::Subjectivity::Seed->new;
$base->load($arguments->base);
$other->load($arguments->other);
my $measure = $base->accuracy($other);
say "   Accuracy: ", $measure->accuracy;
say "  Precision: ", $measure->precision;
say "     Recall: ", $measure->recall;
say "   F1 Score: ", $measure->f1;
say "Sensitivity: ", $measure->sensitivity;
say "Specificity: ", $measure->specificity;
say "     Youden: ", $measure->youden;
say "         DP: ", $measure->dp;
say "         p-: ", $measure->p_minus;
say "         p+: ", $measure->p_plus, "\n";
say "Raw Data:";
print Dumper($measure);
