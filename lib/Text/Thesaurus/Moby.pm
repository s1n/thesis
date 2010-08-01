package Text::Thesaurus::Moby;

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Text::CSV;

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $self = {file => $init->{file},
               raw => []};
   bless $self, $class;
   $self->load($init->{file}) if $init->{file};
   return $self;
}

sub load {
   my ($self, $thes) = @_;
   my $csv = Text::CSV->new();
   open THES, $thes or croak "Unable to open thesaurus: $!"; 
   while(defined (my $line = <THES>)) {
      if($csv->parse($line)) {
         my @columns = $csv->fields();
         my $rootw = shift @columns;
         push @{$self->{thes}->{$rootw}}, @columns;
      } else {
         my $err = $csv->error_input;
         croak "Failed to parse line: $err"
      }
   }
   close THES;
   #print Dumper($self->{thes}->{'freedom'});
}

sub synset {
   my ($self, $rootword) = @_;
   #print $self->{thes}->{$rootword} . "\n";
   return $self->{thes}->{$rootword};
}

sub search {
   my ($self, $rootword) = @_;
   my @synset;
   for my $rw(keys %{$self->{thes}}) {
      push @synset, $rw if grep { $_ eq $rw } @{$self->{thes}->{$rw}};
   }
   return @synset;
}

1;
