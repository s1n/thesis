package AI::Subjectivity::Seed::ASL;

use Modern::Perl;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'dictionary' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub { { } },
);

has 'patterns' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub { { } },
);

sub read_data_files {
   my ($self, $filesref) = @_;
   if($filesref->{affix}) {
      $self->read_affixes($filesref->{affix});
   }

   if($filesref->{dict}) {
      $self->read_dict($filesref->{dict});
   }
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $lexref = $self->lexicon;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   #loop over every word in the dictionary
   while(my ($key, $sign) = each(%$dictref)) {
      #first check if it's a positive word
      while(my ($negpat, $pospat) = each(%$patref)) {
         if($key =~ /$pospat/) {
            #say "checking ASL match for: ", $key;
            my $foo = eval "\"$negpat\"";
            #now check to see if it's a negative match
            if(exists($dictref->{$foo})) {
               if($foo eq $trace) {
                  say "positive match of $key to $pospat with $1 finding $foo";
               }
               $lexref->{$foo}--;
               $lexref->{$key}++;
            } else {
               #say "no match of $key to $foo";
            }
         }
      }
   }
}

sub read_affixes {
   my ($self, $aff) = @_;
   my $patref = $self->patterns;
   say "Loading affix patterns from $aff ...";
   open(AFFIX, $aff) or
       die "Unable to open affix pattern file $aff: $!\n";
   my @pats = <AFFIX>;
   chomp @pats;
   for my $p(@pats) {
      next if $p =~ /^#/;
      my @parts = split /,/, $p;
      my $pp = qr/$parts[0]/;
      $patref->{$parts[1]} = $parts[0];
      #say "+|$parts[0] -|", $parts[1];
   }
   close AFFIX;
   return $patref;
}

sub read_dict {
   my ($self, $dicts) = @_;
   my $dictref = $self->dictionary;

   #slurp the dictionary
   for my $d(@$dicts) {
      say "Loading dictionary $d ...";
      open(DICT, $d) or
         die "Unable to open dictionary ", $d, ": $!\n";
      while(my $line = <DICT>) {
         chomp $line;
         $dictref->{$line} = 0;
      }
      close DICT;
   }
   return $dictref;
}


no Moose;
1;
