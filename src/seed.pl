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

my $readdict = 0;
my $readpat = 0;
my $arguments = SeedArgs->new_with_options;
for my $a(@{$arguments->algo}) {
   my $seeder = "AI::Subjectivity::Seed::" . $a;
   say "Preparing lexicon based on algorithm: $a ...";
   my $seed;
   if(!$readdict && !$readpat) {
      $seed = $seeder->new(patterns=>{}, dictionary=>{});
      $seed->args($arguments);
      eval { $readpat = $seed->read_affixes };
      if(!-e $arguments->lexicon) {
         $readdict = $seed->read_dict;
      } else {
         eval { $seed->load };
         $readdict = $seed->dictionary;
      }
   } else {
      $seed = $seeder->new(patterns=>$readpat, dictionary=>$readdict);
      $seed->args($arguments);
   }
   eval { $seed->load };
   if($@) {
      say "Skipping prior data load of ", $arguments->lexicon;
   }
   #print Dumper($seed);
   say "Building lexicon subjectivity scores with algorithm: $a ...";
   $seed->build;
   $seed->save;
   undef $seed;
}
