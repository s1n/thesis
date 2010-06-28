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
   cmd_aliases => 'a',
);

has 'matchlog' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'matches.log',
   cmd_flag => 'matchlog',
   cmd_aliases => 'm',
);
1;

use lib '../lib';
use AI::Subjectivity::Seed;
use Data::Dumper;

my $arguments = SeedArgs->new_with_options;
print Dumper($arguments);
my $seed = AI::Subjectivity::Seed->new(patterns=>{}, dictionary=>{});
$seed->args($arguments);
$seed->read_affixes;
print Dumper($seed);
$seed->read_dict;
$seed->build_asl;
