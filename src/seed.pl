#!/usr/bin/perl

package SeedArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'dict' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => '/usr/share/dict/words',
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

has 'matchlog' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'matches.log',
   cmd_flag => 'matchlog',
   cmd_aliases => 'm',
);

has 'algo' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'ASL',
   cmd_flag => 'algo',
   cmd_aliases => 'a',
);

1;

use lib '../lib';
use AI::Subjectivity::Seed::ASL;
use AI::Subjectivity::Seed::WordNet;
use Data::Dumper;

my $arguments = SeedArgs->new_with_options;
my $seeder = "AI::Subjectivity::Seed::" . $arguments->algo;
my $seed = $seeder->new(patterns=>{}, dictionary=>{});
$seed->args($arguments);
$seed->read_affixes;
print Dumper($seed);
$seed->read_dict;
$seed->build;
