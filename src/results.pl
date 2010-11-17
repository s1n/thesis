#!/usr/bin/perl

use Modern::Perl;
use Time::Interval;

my $boost = @ARGV && ($ARGV[0] eq "--boost" || $ARGV[0] eq "-b") ? 1 : 0;

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
   my ($test, $extraargs, $logfile) = @_;
   $logfile //= "log/$test.log";
   $extraargs //= "";
   say "Running test: $test $extraargs to $test\.dat > $logfile";
   my $start = time();
   `perl -Ilib src/seed.pl --configfile conf/$test\.json --lexicon results/$test\.dat --stripwords data/stripwords.txt $extraargs >& $logfile`;
   my $end = time();
   say "Time of execution: ", parseInterval(seconds => $end - $start,
                                            String => 1);
   score $test;
   #score $test, $extraargs;
}

sub runboosting {
   my ($test) = @_;
   for my $algo(qw/ada inv/) {
      for my $iter(qw/3 10/) {
         my $boosttest = $test . "_" . "$algo$iter";
         my $boostalgo = `echo "$algo" | { dd bs=1 count=1 conv=ucase 2>/dev/null; cat; }`;
         chomp $boostalgo;
         my $booster = $boostalgo . "Boost";
         if(-f "results/$boosttest.dat") {
            say "Previously run test: $boosttest";
            score $boosttest, "results/pcma.dat";
            continue
         }
         runtest $test, "--boost-iter $iter --lexicon results/$boosttest\.dat --boost $booster --boost-ref results/gi.dat", "log/$boosttest.log";
         score $boosttest, "results/pcma.dat";
      }
   }
}

`mkdir -p log`;
my @files;
while(<conf/*.json>) {
   push @files, $_ if -f $_;
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
