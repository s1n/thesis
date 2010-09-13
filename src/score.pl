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
   documentation => 'Base lexicon considered the reference lexicon.',
   cmd_flag => 'base',
   cmd_aliases => 'b',
);

has 'other' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Secondary lexicon to compare against the base.',
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

__END__

=head1 NAME

score.pl - scores the accuracy between two lexicons.

=head1 SYNOPSIS

 #compare the current lexicon against the GI lexicon
 ./score.pl --base ../results/gi.dat --other lexicon.dat

=head1 DESCRIPTION

This script is used to check the current accuracy against a known lexicon.
The term 'base' lexicon means that this lexicon is considered the reference 
lexicon. The 'other' lexicon is any other lexicon that the user wishes to check
its accuracy against the base lexicon.

Generally, the user will do this during development or training of the lexicon.
For example, to know if a new algorithm is working well, the user may wish to
compare their lexicon against the GI lexicon since it was built by humans.

The GI lexicon can be found at
L<http://www.wjh.harvard.edu/~inquirer/homecat.htm>. This comparison will report
all metrics that can be computed by L<Stats::Measure> as indicated here:
L<http://github.com/s1n/thesis/blob/master/lib/Stats/Measure.pm>.
