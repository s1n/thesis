#!/usr/bin/perl

package TrainingSetArgs;
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

has 'testing' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Output testing lexicon.',
   default => 'testing.dat',
   cmd_flag => 'testint',
   cmd_aliases => 'e',
);

has 'training' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Output training lexicon.',
   default => 'training.dat',
   cmd_flag => 'training',
   cmd_aliases => 'r',
);

has 'percent' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Num',
   documentation => 'Output training lexicon percentage split of reference.',
   default => 50,
   cmd_flag => 'training-perc',
   cmd_aliases => 'r',
);

1;

use Data::Dumper;
use AI::Subjectivity::Seed;

my $arguments = TrainingSetArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
my $test = AI::Subjectivity::Seed->new;
my $train = AI::Subjectivity::Seed->new;
$ref->load($arguments->reference);

die "Cannot split on a negative number" if 0 > $arguments->percent;

while(my ($key, $scoreref) = each(%{$ref->lexicon})) {
   my $whereto = int(rand(100));
   if($whereto < $arguments->percent) {
      say "TRAIN(", $whereto, ") $key => ", $arguments->training;
      $train->lexicon->{$key} = $scoreref;
   } else {
      say "TEST(", $whereto, ") $key => ", $arguments->testing;
      $test->lexicon->{$key} = $scoreref;
   }
}
$test->save($arguments->testing);
$train->save($arguments->training);

=pod

=head1 NAME



=head1 SYNOPSIS

 #create test and training tests from a reference lexicon
 ./traingset.pl --reference ../results/gi.dat \
                --testing test.dat --training training.dat \
                --train-perc 70

=head1 DESCRIPTION

This script is used to split a reference lexicon into test and training sets.
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
