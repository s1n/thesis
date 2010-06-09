#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use WordNet::QueryData;
use WordNet::stem;
use Lingua::Stem;
use Lingua::EN::Inflect qw/PL/;
use feature ':5.10';

my %opts = (phrase => undef,
            querysense => undef,
            queryword => undef,
            validforms => undef,
            stem => undef,
            altstem => undef,
            inflect => undef,
            help => undef);
GetOptions('phrase:s' => \$opts{phrase},
           'querysense:s' => \$opts{querysense},
           'queryword:s' => \$opts{queryword},
           'validforms' => \$opts{validforms},
           'stem' => \$opts{stem},
           'altstem' => \$opts{altstem},
           'inflect' => \$opts{inflect},
           'help' => \$opts{help}) or pod2usage(2);
pod2usage(1) if $opts{help};

my @senses = qw/also glos syns hype inst hypes hypo hasi hypos mmem
                msub mprt mero hmem hsub hprt holo attr sim enta
                caus domn dmnc dmnu dmnr domt dmtc dmtu dmtr/;

my @words = qw/also ants deri part pert vgrp/;
#my $wn = WordNet::QueryData->new(noload => 1);
my $wn = WordNet::QueryData->new(dir => $ENV{WNHOME} // "/usr/share/wordnet", noload => 1);

if($opts{querysense}) {
   say "Querying $opts{querysense} for $opts{phrase}";
   &qsense($wn, $opts{phrase}, $opts{querysense});
} else {
   say "Querying all senses for $opts{phrase}";
   &qsense($wn, $opts{phrase}, $_) for @senses;
}

if($opts{queryword}) {
   say "Querying $opts{queryword} for $opts{phrase}";
   &qword($wn, $opts{phrase}, $opts{queryword});
} else {
   say "Querying all words for $opts{phrase}";
   &qsense($wn, $opts{phrase}, $_) for @words;
}

if($opts{validforms}) {
    say "$opts{phrase} => ", join(", ", $wn->validForms($opts{phrase}));
}

if($opts{stem}) {
    my $stemmer = WordNet::stem->new($wn);
    my @stems = $stemmer->stemWord($opts{phrase});
    say "Possible WordNet stems:";
    say join ", ", @stems;
}

if($opts{altstem}) {
    say "Possible Lingua::Stem stems:";
    my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
    $stemmer->stem_caching({ -level => 2 });
    say join ", ", @{$stemmer->stem($opts{phrase})};
}

if($opts{inflect}) {
    say "Possible plural inflection:";
    my @plurals;
    for(0..10) {
        my $next = PL($opts{phrase}, $_);
        last if grep { /$opts{phrase}/ } @plurals;
        push @plurals, $next;
    }
    say join ", ", @plurals;
}

sub qsense {
    my ($wordnet, $phrase, $sense) = @_;
    my @results = $wordnet->querySense($phrase, $sense);
    my $dump = join(", ", @results);
    say "$sense => $dump" if $dump;
    #say "$sense => ", join(", ", @results) if @results;
}

sub qword {
    my ($wordnet, $phrase, $word) = @_;
    my @results = $wordnet->queryWord($phrase, $word);
    say "$word => ", join(", ", @results) if @results;
}
