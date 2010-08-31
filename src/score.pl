#!/usr/bin/perl

package SeedArgs;
use Modern::Perl;
use Moose;
        
with 'MooseX::Getopt';

has 'base' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   cmd_flag => 'base',
   cmd_aliases => 'b',
);

has 'other' => (
   metaclass => 'MooseX::Getopt::Meta::Attribute',
   is => 'ro',
   isa => 'Str',
   default => 'lexicon.dat',
   cmd_flag => 'other',
   cmd_aliases => 't',
);

1;

use lib '../lib';
use Data::Dumper;

my $base = AI::Subjectivity::Seed::GI->new(patterns=>{}, dictionary=>{});
my $other = AI::Subjectivity::Seed->new(patterns=>{}, dictionary=>{});
$base->load;
$other->load;
my $measure = $base->compare($other);
print Dumper($measure);
