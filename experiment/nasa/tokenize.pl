#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Text::ExtractWords qw(words_list);
use Text::Sentence qw(split_sentences);
use POSIX qw(locale_h);
use feature ':5.10';

my %opts = (minwordlen => 2,
            maxwordlen => 30,
            file => undef,
            wordlist => "words.wl",
            inplace => undef,
            help => undef);
GetOptions('minwordlen:i' => \$opts{minwordlen},
           'maxwordlen:i' => \$opts{maxwordlen},
           'wordlist:s' => \$opts{wordlist},
           'file:s' => \$opts{file},
           'inplace:s' => \$opts{inplace},
           'help' => \$opts{help}) or pod2usage(2);
pod2usage(1) if $opts{help};

if($opts{inplace}) {
    $opts{file} = $opts{inplace};
    $opts{wordlist} = $opts{inplace};
}

my @files = &find_files($opts{file});

my $test;
my @bigwordlist;

&setlocale(LC_CTYPE, 'iso_8859_1');
for(@files) {
    my $test = &slurp($_);
    #push @bigwordlist, "DOCUMENT: $_\n";
    for my $sent(split_sentences($test)) {
        push @bigwordlist, &split_words($sent,
                                        $opts{minwordlen},
                                        $opts{maxwordlen});
    }
}

&print_words($opts{wordlist}, @bigwordlist);

sub print_words {
    my $output = shift;
    open WORDS, ">$output" or die "Unable to save wordlist: $!\n";
    print WORDS join "\n", @_;
    close WORDS;
}

sub find_files {
    my ($file) = @_;
    if(!$file) {
        @files = `ls *.txt`;
        chomp @files;
    } else {
        @files = ($file);
    }
    @files;
}

sub split_words {
    my ($sentence, $minw, $maxw) = @_;
    my @list;
    words_list(\@list, $sentence, {minwordlen => $minw, maxwordlen => $maxw});
    join ' ', @list;
}

sub slurp {
    my ($filename) = @_;
    open IN, $filename or die "Unable to read $filename: $!\n";
    my @lines = <IN>;
    close IN;
    chomp @lines;
    join "\n", @lines;
}
