#!/usr/bin/perl

use strict;
use warnings;

my $file = shift || die "Usage: $0 inputfile\n";
open(INPUT, $file) or die "Unable to read input: $!\n";
my @data = <INPUT>;
close INPUT;
chomp @data;
while(@data) {
   shift @data;
   my $reportnum = shift @data;
   print "Processing $reportnum...";
   shift @data;
   my $annotation = shift @data;
   shift @data;
   my $report = shift @data;
   shift @data;
   my @parts = split /#/, $reportnum;
   my $filename = "$parts[0]_$parts[1].txt";
   open(OUTPUT, ">$filename") or die "Unable to write output: $!\n";
   print OUTPUT $report;
   close OUTPUT;
   print "Done!\n";
}
