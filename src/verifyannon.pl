#!/usr/bin/perl

package VerifyAnnonArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'reference' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'reference.dat',
   documentation => 'Reference lexicon considered the authority lexicon.',
   cmd_flag => 'reference',
   cmd_aliases => 'r',
);

has 'output' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Lexicon to write the random words not in the reference.',
   default => 'output.dat',
   cmd_flag => 'output',
   cmd_aliases => 'o',
);

has 'lookup' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Bool',
   documentation => 'Lookup and prompt the user for the word label.',
   default => sub { 0 },
   cmd_flag => 'lookup',
   cmd_aliases => 'k',
);

has 'apikey' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   documentation => 'Wordnik API key to use when looking up a word.',
   default => sub { '' },
   cmd_flag => 'apikey',
   cmd_aliases => 'a',
);

1;

use Data::Dumper;
use AI::Subjectivity::Seed;
use WWW::Wordnik::API;

my $arguments = VerifyAnnonArgs->new_with_options;
my $ref = AI::Subjectivity::Seed->new;
my $lex = AI::Subjectivity::Seed->new;
my $output = AI::Subjectivity::Seed->new;

#load the reference lexicon
eval { $ref->load($arguments->reference); };
if($@) {
   say "Failed to load lexicon ", $arguments->reference, " skipping";
}

#load the output file, in case previous data is present
eval { $output->load($arguments->output); };
if($@) {
   say "Failed to load lexicon ", $arguments->output, " skipping";
}

my $wordnik;
if($arguments->lookup) {
   die "Must provide an API key for Wordnik.\n" if !$arguments->apikey;
   $wordnik = WWW::Wordnik::API->new();
   $wordnik->api_key($arguments->apikey);
   $wordnik->format('perl');
   $wordnik->cache(1000);
}

my $todo = scalar keys %{$ref->lexicon};
my $sofar = scalar keys %{$output->lexicon};
say "Words labeled: $sofar of $todo";
for my $key(keys %{$ref->lexicon}) {
   next if defined $output->lexicon->{$key};
   say "word: $key";
   my $input = 'n';
   define($wordnik, $key) if $arguments->lookup;
   print "Label [p or n]: ";
   $input = <STDIN>;
   chomp $input;
   $input = lc $input;
   redo if $input !~ /^[np]$/;
   $output->lexicon->{$key} = {score => $input eq 'p' ? 1 : -1,
                               weight => 0};
   $sofar++;
   say "Words labeled: $sofar of $todo";
   $output->save($arguments->output);
}

sub define {
   my ($wordnik, $word) = @_;
   return "" if !$wordnik || !$word;
   my @results = $wordnik->definitions($word);
   my $i = 1;
   for my $outer(@results) {
      for my $inner(@$outer) {
         say "    $i ) $inner->{text}";
         $i++;
      }
   }
}

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
