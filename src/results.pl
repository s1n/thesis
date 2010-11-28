#!/usr/bin/perl

use Modern::Perl;
use Time::Interval;
use Getopt::Long;

my ($boost, $experiment) = ('', '');
GetOptions('boost=i' => \$boost, 'test=s' => \$experiment);

sub score {
   my ($test, $reflex) = @_;
   $test //= "mpqa";
   $reflex //= "results/gi.dat";
   say "Performance against GI ($reflex):";
   print `perl -Ilib src/score.pl --reference $reflex --test results/$test.dat`;
   say "Performance against PCMA:";
   print `perl -Ilib src/score.pl --reference results/pcma.dat --test results/$test\.dat`;
   say "  Size of Lexicon: ", `wc -l results/$test\.dat`;
}

sub runtest {
   my ($test, $conffile, $extraargs) = @_;
   $conffile //= "conf/$test.json";
   $extraargs //= "";
   say "Running test: $test $extraargs to $test\.dat > log/$test\.log";
   my $start = time();
   `perl -Ilib src/seed.pl --configfile $conffile --lexicon results/$test\.dat --stopwords data/smartstop.txt $extraargs >& log/$test.log`;
   my $end = time();
   say "Time of execution: ", parseInterval(seconds => $end - $start,
                                            String => 1);
   score $test;
   #score $test, $extraargs;
}

sub runboosting {
   my ($test) = @_;
   for my $algo(qw/ada inv/) {
      my $iter = $boost;
      #for my $iter(qw/3 10/) {
         my $boosttest = $test . "_" . "$algo$iter";
         my $boostalgo = `echo "$algo" | { dd bs=1 count=1 conv=ucase 2>/dev/null; cat; }`;
         chomp $boostalgo;
         my $booster = $boostalgo . "Boost";
         if(-f "results/$boosttest.dat") {
            say "Previously run test: $boosttest";
            score $boosttest;
            next;
         }
         runtest $boosttest, "conf/$test\.json", "--boost-iter $iter --boost $booster --boost-ref results/gi.dat";
         #score $boosttest;
      #}
   }
}

`mkdir -p log`;
my @files;
if($experiment) {
   push @files, $experiment;
} else {
   while(<conf/*.json>) {
      push @files, $_ if -f $_;
   }
}

#for my $f(`ls conf/*.json`) {
for my $f(@files) {
   my $test = `basename $f | cut -d. -f1`;
   chomp $test;
   next if $test eq "gi";
   if(-f "results/$test\.dat") {
      say "Previously run test: $test";
      score $test;
      runboosting $test if $boost;
      next;
   }

   runtest $test;
   runboosting $test if $boost;
}
