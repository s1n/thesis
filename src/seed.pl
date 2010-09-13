#!/usr/bin/perl

package SeedArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'trace' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '',
   documentation => 'Perform a complete debug trace against a word ("*" for everything).',
   cmd_flag => 'trace',
   cmd_aliases => 't',
);

has 'thes' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '/usr/share/dict/thesaurus',
   documentation => 'Thesaurus file, CSV format with first word as root word.',
   cmd_flag => 'thes',
   cmd_aliases => 'h',
);

has 'dict' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { ['/usr/share/dict/words'] },
   documentation => 'Dictionary file, one word per line',
   cmd_flag => 'dict',
   cmd_aliases => 'd',
);

has 'affix' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'affix.dat',
   documentation => 'Affix pattern file (negative,positive).',
   cmd_flag => 'affix',
   cmd_aliases => 'f',
);

has 'lexicon' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   documentation => 'Lexicon to build upon, if already exists.',
   cmd_flag => 'lexicon',
   cmd_aliases => 'l',
);

has 'algo' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { [ ] },
   documentation => 'Algorithm to use: GI, ASL, MSL, WordNet.',
   cmd_flag => 'algo',
   cmd_aliases => 'a',
);

1;

use lib '../lib';
use AI::Subjectivity::Seed::ASL;
use AI::Subjectivity::Seed::MSL;
use AI::Subjectivity::Seed::WordNet;
use AI::Subjectivity::Seed::GI;
use Data::Dumper;

my $flag = 0;
my $readdict = 0;
my $readpat = 0;
my $arguments = SeedArgs->new_with_options;
for my $a(@{$arguments->algo}) {
   my $seeder = "AI::Subjectivity::Seed::" . $a;
#FIXME should be able to require $a but it fails
   #require $seeder;
   say "Preparing lexicon based on algorithm: $a ...";
   my $seed;
   $seed = $seeder->new;
   eval { $seed->load($arguments->lexicon); };
   if($@) {
      say "Failed to load lexicon ", $arguments->lexicon, " skipping";
   }
   $seed->read_data_files({thes => $arguments->thes,
                           dict => $arguments->dict,
                           affix => $arguments->affix});
   say "Building lexicon subjectivity scores with algorithm: $a ...";
   $seed->build($arguments->trace);
   $seed->save($arguments->lexicon);
   undef $seed;
}

__END__

=head1 NAME

./seed.pl - Seed and build a subjectivity lexicon.

=head1 SYNOPSIS

 #seed with GI data
 ./seed.pl --algo GI

 #stack the ASL seeded data on the GI data
 ./seed.pl --dict /usr/share/dict/words --affix ../data/affixes.txt --algo ASL

 #stack the MSL seeded data on the GI+ASL data and trace the word 'bandit'
 ./seed.pl --thes ../data/moby/mthesaur.txt --algo MSL --trace bandit

 #seed ASL then stack on MSL data afterwards
 rm lexicon.dat
 ./seed.pl --dict /usr/share/dict/words --affix ../data/affixes.txt --algo ASL \
           --thes ../data/moby/mthesaur.txt --algo MSL

=head1 DESCRIPTION

This program is largely responsible for building the seeded lexicon to indicate
subjectivity. Lexicons can be built in a progressive manner. That is, if an
existing lexicon is specified, each successive algorithm will build upon the
prior lexicon. This is referred to as 'stacking'.

The lexicon files will be of the following format:

 word_1,score_1
 ...
 word_n,score_n

where word_x is any given seeded word and score_x is its matching seeded score.
A seeded score may be either positive or negative. Words with a score of zero,
which indicates inconclusiveness, will be omitted. The lower the negative score,
the more negative the word and similarly with higher positive scores.

Some of the options are specific to the algorithm that needs them. All algorithm
specific arguments will be passed to the module and processed on an as-need
basis. For example, specifying B<--thes> to the ASL algorithm will be ignored.

Each individual module will discuss its options, requirements, and usage
details.
