#!/usr/bin/perl

sub openit {
   my $file = shift;
   open $fd, $file or die "Cannot open: $!\n";
   print "opened...\n";
   return $fd;
}

sub nextline {
   my $fd = shift;
   print "reading...\n";
   $line = <$fd>;
   return $line;
}

sub splitit {
   my ($line, $array) = @_;
   print "splitting...\n";
   my @tokens = split /\s/, $line;
   print (scalar @tokens) . "\n";
   push @$array, @tokens;
   undef @tokens;
}

sub closeit {
   my $fd = shift;
   close $fd;
}

my $fd = openit(shift);
while(my $line = nextline($fd)) {
   my @tok;
   splitit($line, \@tok);
   sleep 1;
}
print "\n";
closeit($fd);
