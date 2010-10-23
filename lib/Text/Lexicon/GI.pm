package Text::Lexicon::GI;

use warnings;
use strict;
use WWW::Mechanize;

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $webusebase = 'http://www.webuse.umd.edu:9090/tags/';
   my $self = {tag => $init->{tag} // 'POS',
               mech => $init->{mech} // WWW::Mechanize->new(autocheck => 1),
               url => $init->{url} // $webusebase,
               raw => $init->{raw} // []};
   bless $self, $class;
   $self->load($init->{tag}) if $init->{tag};
   return $self;
}

sub load {
   my ($self, $tag) = @_;
   my $tagurl = $self->url . "TAG$tag.html";
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

=pod

=head1 NAME

Text::Thesaurus::GI - downloads and stores a GI lexicon.

=head1 SYNOPSIS


   #load the thesaurus
   my $giobj = Text::Thesaurus::GI->new;
   my $tag = 'POSITIV';
   $giobj->load($tag);

   #example 1 - manual search
   for my $link(@{$giobj->rawdata}) {
      my $text = $link->text;
      my @tokens = split /\#/, $text;
      $text = lc shift @tokens;
      say "lexicon word: $text";
   }

   #example 2 - definition count
   say "'accord' is found ", $giobj->get('accord'), " times";

=head1 DESCRIPTION

Text::Thesaurus::GI downloads and stores lexicons from the General Inquirer
lexicon available on the WebUse website. Any tag can be accessed, though the
POSITIV and NEGATIV tagged datasets are the largest.

The GI lexicons are built by humans and are considered acurate but are limited
in size. The content owners of the GI lexicons have made each tagged lexicon
available via a webserver. This module automates the task of downloading and
storing the entire file's contents.

The lexicon files are HTML markup where each word is listed as a link to more
detailed information. Each word is listed in all caps as well, so it is
converted to lowercase during L<load>.

It is common with NLP (and SNLP) programs to suffer with a lack of processing
power and available memory. For this reason, it was decided that a method to
return a new list with only the words in it would be potentially wasteful. To
acheive this, see the first example in the L<SYNOPSIS> section.

=head1 METHODS

=head2 new

Constructs a new instance of this object. The method can take the following
parameters:

=over 4

=item * tag => lexicon tag name to load

=item * mech => WWW::Mechanized object to automate the download

=item * url => forces a completed URL of the tagged lexicon

=item * raw => raw data to initialize with (ArrayOfStr)

=back

=head2 load

Begin downloading the lexicon. This may be a time consuming process, so it is
only automatically performed if a I<url> is provided to the constructor.

=head2 get

Gets a count of the occurances that a word appears. When a word appears multiple
times in the lexicon, it will end with '#' followed by a number. For example:

 USED#1
 USED#2
 USED#3

which means the word 'used' has 3 definitions that are tagged accordingly.

=head2 reset

Resets the internal raw data. The I<mech> object is not reset or rebuilt.

=head2 url

Current URL of the tagged lexicon. This may be the forced URL from the
constructor.

=head2 mech

L<WWW::Mechanize> object that is capable of downloading the tagged lexicon files
and accessing the set of links.

=head2 rawdata

This method returns the crucial lexicon and should be used with care. It
is a collection of L<WWW::Mechanize::Link> objects. To obtain the link text
that is listed in each lexicon tag, call the L<WWW::Mechanize::Link::text>
method. This will be in all caps and may contain a definition count. See
the L<get> method for example data.

=head1 AUTHOR

Jason Switzer <s1n@voidreturn.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The General Inquirer lexicons may be licensed under different terms. See
L<http://www.wjh.harvard.edu/~inquirer/Home.html> for more details.

=cut

__END__
