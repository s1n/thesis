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
   isa => 'ArrayRef',
   default => sub { ['ASL'] },
   cmd_flag => 'algo',
   cmd_aliases => 'a',
);

1;

use lib '../lib';
use AI::Subjectivity::Seed::ASL;
use AI::Subjectivity::Seed::WordNet;
use Data::Dumper;

my $readdict = 0;
my $readpat = 0;
my $arguments = SeedArgs->new_with_options;
for my $a(@{$arguments->algo}) {
   my $seeder = "AI::Subjectivity::Seed::" . $a;
   say "loading $seeder";
   my $seed;
   if(!$readdict && !$readpat) {
      $seed = $seeder->new(patterns=>{}, dictionary=>{});
      $seed->args($arguments);
      $readpat = $seed->read_affixes;
      $readdict = $seed->read_dict;
   } else {
      $seed = $seeder->new(patterns=>$readpat, dictionary=>$readdict);
      $seed->args($arguments);
   }
   #print Dumper($seed);
   $seed->build;
}
