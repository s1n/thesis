#!/usr/bin/perl

package ScoreArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'reference' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   documentation => 'Reference lexicon considered the authority lexicon.',
   cmd_flag => 'reference',
   cmd_aliases => 'r',
);

has 'test' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Test lexicon to compare against the reference.',
   default => 'lexicon.dat',
   cmd_flag => 'test',
   cmd_aliases => 't',
);

has 'verbose' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Bool',
   documentation => 'Enables verbosity when scoring.',
   default => sub { 0 },
   cmd_flag => 'verbose',
   cmd_aliases => 'v',
);

1;

use Data::Dumper;
use AI::Subjectivity::Seed;

my $arguments = ScoreArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
my $test = AI::Subjectivity::Seed->new;
$ref->load($arguments->reference);
$test->load($arguments->test);
my $measure = $ref->accuracy($test, $arguments->verbose);
say "  Words in Common: ", $measure->incommon, " out of ", $ref->size;
say "         Accuracy: ", $measure->accuracy;
say "         F1 Score: ", $measure->f1;
say "        Precision: ", $measure->precision if $arguments->verbose;
say "           Recall: ", $measure->recall if $arguments->verbose;
say "      Sensitivity: ", $measure->sensitivity if $arguments->verbose;
say "      Specificity: ", $measure->specificity if $arguments->verbose;
say "           Youden: ", $measure->youden if $arguments->verbose;
say "               DP: ", $measure->dp if $arguments->verbose;
say "               p-: ", $measure->p_minus if $arguments->verbose;
say "               p+: ", $measure->p_plus, "\n" if $arguments->verbose;
say "Raw Data:" if $arguments->verbose;
print Dumper($measure) if $arguments->verbose;

=pod

=head1 NAME

score.pl - scores the accuracy between two lexicons.

=head1 SYNOPSIS

 #compare the current lexicon against the GI lexicon
 ./score.pl --reference ../results/gi.dat --test lexicon.dat

=head1 DESCRIPTION

This script is used to check the current accuracy against a known lexicon.
The term 'reference' lexicon means that this lexicon is considered the reference
lexicon. The 'test' lexicon is any other lexicon that the user wishes to check
its accuracy against the reference lexicon.

Generally, the user will do this during development or training of the lexicon.
For example, to know if a new algorithm is working well, the user may wish to
compare their lexicon against the GI lexicon since it was built by humans.

The GI lexicon can be found at
L<http://www.wjh.harvard.edu/~inquirer/homecat.htm>. This comparison will report
all metrics that can be computed by L<Stats::Measure> as indicated here:
L<http://github.com/s1n/thesis/blob/master/lib/Stats/Measure.pm>.

=head1 OPTIONS

=head2 --reference|r

Sets the reference lexicon, which will be the authority.

=head2 --test|t

Sets the testing lexicon. Only words found in the reference lexicon will be
checked. The rest will be marked as 'unknown'.

=cut

__END__
