package Text::Thesaurus::Moby;

use warnings;
use strict;
use Carp;
use Fcntl qw/O_RDONLY/;
use Tie::File;

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
   $self->file($thes);
   tie @{$self->rawdata}, 'Tie::File', $self->file, mode => O_RDONLY;
}

sub file {
   my ($self, $file) = @_;
   $self->{file} = $file if $file;
   return $self->{file};
}

sub rawdata {
   my ($self, $data) = @_;
   $self->{raw} = $data if $data;
   return $self->{raw};
}

sub synset {
   my ($self, $rootword) = @_;
   for my $rw(@{$self->{raw}}) {
      return $rw if $rw =~ /^$rootword,/;
   }
   return undef;
}

sub search {
   my ($self, $rootword) = @_;
   my @synset;
   for my $rw(@{$self->rawdata}) {
      if($rw =~ /,$rootword,?/) {
         my @words = split /,/, $rw;
         push @synset, $words[0] if @words;
      }
   }
   return @synset;
}

1;
