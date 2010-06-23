#!/usr/bin/perl

###
### Loads the necessary modules for the text processing.
###
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Storable qw(nstore retrieve);
use Test::Deep;
use Test::More;
use feature ':5.10';

###
### Parse the command-line parameters.
###
my %opts = (cache => undef,
            wordlist => "words.wl",
            ngram => 2,
            verify => 1,
            who => undef,
            pofci => undef,
            help => undef);
GetOptions('wordlist:s' => \$opts{wordlist},
           'cache:s' => \$opts{cache},
           'ngram:i' => \$opts{ngram},
           'verify!' => \$opts{verify},
           'who:s' => \$opts{who},
           'pofci:f' => \$opts{pofci},
           'help' => \$opts{help}) or pod2usage(2);
pod2usage(1) if $opts{help};

###
### Do the grunt work here.
###
my @words;
my %ngram_probs;
if($opts{cache} && -f $opts{cache}) {
    %ngram_probs = &load_probs($opts{cache});
} else {
    @words = &load_wordlist($opts{wordlist});
    %ngram_probs = &compute_all_probs($opts{ngram}, @words);
}
#&sentence_prob("My friends, I think we should bomb Iraq", 2);
my %smashed = &squash_probs(%ngram_probs);
$smashed{who} = $opts{who};
$smashed{ngram} = $opts{ngram};
$smashed{pofci} = $opts{pofci};
&cache_probs($opts{cache}, $opts{verify}, %smashed);

###
### Loads the wordlist (in the form of sentences).
###
sub load_wordlist {
    my ($file) = @_;
    say "Loading wordlist: $file";
    open WL, $file or die "Unable to load wordlist: $!\n";
    my @ret = <WL>;
    close WL;
    $_ =~ s/\n/ .\n/ for @ret;
    @ret;
}

###
### Computes the ngram probabilities for the entire sentence corpus.
###
sub compute_all_probs {
    my ($ngram, @wordlist) = @_;
    my %seen_ngrams;
    say "Computing all ngram probabilities for " . $#wordlist . " sentences";
    for(@wordlist) {
        chomp;
        my %new_ngrams = &sentence_prob($_, $ngram);
        for my $h(keys %{$new_ngrams{data}}) {
            for my $d(keys %{$new_ngrams{data}{$h}}) {
                $seen_ngrams{data}{$h}{$d} += $new_ngrams{data}{$h}{$d};
            }
        }
    }
    #say Dumper(\%seen_ngrams);
    #$seen_ngrams{ngram} = $ngram;
    %seen_ngrams;
}

###
### Computes the ngram probabilities for a single sentence.
###
sub sentence_prob {
    my ($sentence, $ngram) = @_;
    my %seen_ngrams;
    #say "P('$sentence' | $ngram)";
    my @words = split /\s+/, $sentence;
    unshift @words, "\$" for 0..$ngram;
    while(@words) {
        my $d = pop @words;
        last if $d eq "\$";
        my $h;
        $h .= "$words[$_] " for(($#words - $ngram + 1)..$#words);
        chop $h;
        $seen_ngrams{data}{$d}{$h}++;
        #say "===> P('$d' | '$h' )";
    }
    %seen_ngrams;
}

###
### FIXME
###
sub squash_probs {
    my (%probs) = @_;
    say "Squashing the probabilities";

    #compute the wc
    my $wc = 0;
    my $grams = 0;
    for my $h(keys %{$probs{data}}) {
        for my $d(keys %{$probs{data}{$h}}) {
            $wc += $probs{data}{$h}{$d};
            $grams++;
        }
    }
    #copy metadata
    my %computed;
    $computed{wc} = $wc;
    $computed{tokc} = $grams;
    #$computed{tokc} = scalar keys %{$probs{data}};
    say "Word Count: $computed{wc}";
    say "Token Count: $computed{tokc}";

    #compute the probabilities
    for my $h(keys %{$probs{data}}) {
        for my $d(keys %{$probs{data}{$h}}) {
            $computed{data}{$h}{$d} = $probs{data}{$h}{$d} / $computed{tokc};
            #say "P($h | $d) = $probs{data}{$h}{$d} / $computed{tokc} = $computed{data}{$h}{$d}";
        }
    }

    #say Dumper(\%computed);
    %computed;
}

###
### Loads the probability map from the specified file.
###
sub load_probs {
    my ($file) = @_;
    say "Loading all prior probabilies from $file";
    my $nonref = retrieve $file;
    %$nonref;
}

###
### Writes the probabilities to a file, and tests the store if requested.
###
sub cache_probs {
    my ($file, $verify, %smashed) = @_;
    say "Caching all probabilities to $file";
    nstore(\%smashed, $file);

    if($verify) {
        plan tests => 1;
        my $coderef = retrieve $file;
        cmp_deeply(\%smashed, $coderef, "probability storage successful");
    }
}
