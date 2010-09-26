#!/usr/bin/perl

package SeedArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::SimpleConfig';
with 'MooseX::Getopt';

has 'trace' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '',
   documentation => 'Debug trace against a word ("*" for everything).',
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
   default => sub { [ ] },
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

has 'wnhome' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '/usr/share/wordnet/dict/',
   documentation => 'WordNet data path, same as environment variable WNHOME.',
   cmd_flag => 'wnhome',
   cmd_aliases => 'w',
);


has 'algo' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { [ ] },
   documentation => 'Algorithm to use: GI, ASL, MSL, WordNet.',
   cmd_flag => 'algo',
   cmd_aliases => 'a',
   required => 1,
);

has 'depth' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Int',
   default => sub { 2 },
   documentation => 'Search depth when tracing WordNet.',
   cmd_flag => 'depth',
   cmd_aliases => 'e',
);

has 'mpqa' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => sub { '' },
   documentation => 'Specify MPQA lexicon file.',
   cmd_flag => 'mpqa',
   cmd_aliases => 'm',
);

1;

use lib '../lib';
my $arguments = SeedArgs->new_with_options;
for my $a(@{$arguments->algo}) {
   #determine and load the Seed class
   my $seeder = "AI::Subjectivity::Seed::" . $a;
   (my $filename = $seeder . '.pm') =~ s/::/\//g;
   require $filename;

   say "Preparing lexicon based on algorithm: $a ...";
   my $seed;
   $seed = $seeder->new;
   eval { $seed->load($arguments->lexicon); };
   if($@) {
      say "Failed to load lexicon ", $arguments->lexicon, " skipping";
   }

   say "Building lexicon subjectivity scores with algorithm: $a ...";
   my $ret = $seed->init({thes => $arguments->thes,
                          dict => $arguments->dict,
                          affix => $arguments->affix,
                          wnhome => $arguments->wnhome,
                          mpqa => $arguments->mpqa,
                          depth => $arguments->depth});
   exit(-1) if !$ret;
   $seed->build($arguments->trace);
   $seed->save($arguments->lexicon);
   undef $seed;
}

=pod

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

=head1 OPTIONS

Use the B<--help> option to display all options and their meaning.

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

None of the modules for the seeding algorithms are loaded by default. Only the
the modules specified by the B<--algo> option will be loaded upon request and
can only be used once per execution. Seeding algorithms currently supported all
belong in the B<AI::Subjectivity::Seed> namespace and must be found in @INC.

=head1 OPTIONS

=head2 --configfile

Sets the configuration file, that uses Config::Any formats, to load all
options from.

=head2 --dict|d

Sets the dictionary file. Used by ASL and WordNet.

=head2 --thes|h

Sets the thesaurus file. Used by MSL.

=head2 --trace|t

Enables tracing of a word. Used by all algorithms.

=head2 --affix|f

Sets the affix pattern file. Used by ASL.

=head2 --lexicon|l

Sets the lexicon file name; if preexisting file, uses it as the basis for
execution. Changes made to determine the subjectivity lexicon will be written
to this file after each Seed algorithm finishes. Used by all algorithms.

=head2 --wnhome|w

Sets the WordNet data home directory. Used by WordNet.

=head2 --algo|a

Set the algorithm to use. May specify any number of algorithms to use, in the
same order as specified on the command line.

=head2 --depth|e

Sets the word discovery depth. Used by WordNet.

=head2 --mpqa|m

Sets the MPQA source data file. Used by MPQA.

=cut

__END__
