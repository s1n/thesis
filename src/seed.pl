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
   cmd_flag => 'trace',
   cmd_aliases => 't',
);

has 'thes' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '/usr/share/dict/thesaurus',
   cmd_flag => 'thes',
   cmd_aliases => 't',
);

has 'dict' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { ['/usr/share/dict/words'] },
   cmd_flag => 'dict',
   cmd_aliases => 'd',
);

has 'affix' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'affix.dat',
   cmd_flag => 'affix',
   cmd_aliases => 'x',
);

has 'lexicon' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   cmd_flag => 'lexicon',
   cmd_aliases => 'x',
);

has 'algo' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { [ ] },
   #default => sub { ['ASL'] },
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
