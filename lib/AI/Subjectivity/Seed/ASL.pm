package AI::Subjectivity::Seed::ASL;
use Modern::Perl;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

sub build {
   my $self = shift;
   my $dictref = $self->dictionary;
   my $patref = $self->patterns;

   open(LOG, '>' . $self->args->matchlog) or
      die "Unable to create match log: $!\n";

   #loop over every word in the dictionary
   while(my ($key, $sign) = each(%$dictref)) {
      #first check if it's a positive word
      while(my ($negpat, $pospat) = each(%$patref)) {
         if($key =~ /$pospat/) {
            #say "checking ASL match for: ", $key;
            my $foo = eval "\"$negpat\"";
            #now check to see if it's a negative match
            if(exists($dictref->{$foo})) {
               #say "positive match of $key to $pospat with $1 finding $foo";
               say LOG "$key, $foo";
               $dictref->{$foo}--;
               $dictref->{$key}++;
            } else {
               #say "no match of $key to $foo";
            }
         }
      }
   }
   close LOG;
}

no Moose;
1;
