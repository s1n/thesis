package Text::Thesaurus::Moby;

use warnings;
use strict;
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
}

1;
