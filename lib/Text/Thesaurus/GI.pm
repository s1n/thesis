package Text::Thesaurus::GI;

use warnings;
use strict;
use Carp;
use WWW::Mechanize;

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $webusebase = 'http://www.webuse.umd.edu:9090/tags/';
   my $self = {cat => $init->{category} // 'POS',
               mech => $init->{mech} // WWW::Mechanize->new(autocheck => 1),
               url => $init->{url} // $webusebase,
               raw => $init->{raw} // []};
   bless $self, $class;
   $self->load($init->{category}) if $init->{category};
   return $self;
}

sub load {
   my ($self, $cat) = @_;
   my $tagurl = $self->url . "TAG$cat.html";
   $self->mech()->get($tagurl);
   push @{$self->{raw}}, $self->mech()->find_all_links;
}

sub mech {
   my ($self, $mech) = @_;
   $self->{mech} = $mech if $mech;
   return $self->{mech};
}

sub url {
   my ($self, $url) = @_;
   $self->{url} = $url if $url;
   return $self->{url};
}

sub rawdata {
   my ($self, $data) = @_;
   $self->{raw} = $data if $data;
   return $self->{raw};
}

sub reset {
   my $self = shift;
   #undef $_ for(@{$self->{raw}});
   $self->{raw} = [];
}

sub get {
   my ($self, $word) = @_;
   my $count = 0;
   for my $link(@{$self->{raw}}) {
      my $text = lc $link->text;
      $count++ if $word eq $text || $text =~ /$word\#\d+/g;
   }
   return $count;
}

1;
