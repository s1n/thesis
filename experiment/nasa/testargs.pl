#!/usr/bin/perl

package SeedApp;
use Moose;
        
with 'MooseX::Getopt';

has '_patterns' => (
   is => 'rw',
   isa => 'HashRef');

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

use Modern::Perl;

my $seed = SeedApp->new_with_options;
say "dict = ", $seed->dict;
say "affix = ", $seed->affix;
say "matchlog = ", $seed->matchlog;
$seed->_patterns({'foo' => 3});
say "patterns = ", $seed->_patterns()->{'foo'};
