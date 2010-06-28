#!/usr/bin/perl

package AI::Subjectivity::Seed;
use Modern::Perl;
use Moose;

has 'patterns' => (is => 'rw', isa => 'HashRef');
has 'dictionary' => (is => 'rw', isa => 'HashRef');
has 'args' => (is => 'rw', isa => 'SeedArgs');

sub read_affixes {
   my $self = shift;
   my $patref = $self->patterns;
   open(AFFIX, $self->args->affix) or
       die "Unable to open affix pattern file ", $self->args->affix, ": $!\n";
   my @pats = <AFFIX>;
   chomp @pats;
   for my $p(@pats) {
      next if $p =~ /^#/;
      my @parts = split /,/, $p;
      my $pp = qr/$parts[0]/;
      $patref->{$parts[1]} = $parts[0];
      say "+|$parts[0] -|", $parts[1];
   }
   close AFFIX;
}

sub read_dict {
   my $self = shift;
   my $dictref = $self->dictionary;

   #slurp the dictionary
   open(DICT, $self->args->dict) or
      die "Unable to open dictionary ", $self->args->dict, ": $!\n";
   while(my $line = <DICT>) {
      chomp $line;
      $dictref->{$line} = 0;
   }
   close DICT;
}

sub build_asl {
   my $self = shift;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;
   say "Read ", scalar(keys(%$dictref)), " lines";

   open(LOG, '>' . $self->args->matchlog) or
      die "Unable to create match log: $!\n";

   #loop over every word in the dictionary
   while(my ($key, $sign) = each(%$dictref)) {
      #first check if it's a positive word
      while(my ($negpat, $pospat) = each(%$patref)) {
         if($key =~ /$pospat/) {
            my $foo = eval "\"$negpat\"";
            #now check to see if it's a negative match
            if(exists($dictref->{$foo})) {
               say "positive match of $key to $pospat with $1 finding $foo";
               say LOG "$key, $foo";
               $dictref->{$foo}--;
               $dictref->{$key}++;
            }
         }
      }
   }
   close LOG;
}

no Moose;
1;
