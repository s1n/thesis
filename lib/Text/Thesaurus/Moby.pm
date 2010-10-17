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
               fd => undef,
               raw => []};
   bless $self, $class;
   $self->open($init->{file}) if $init->{file};
   return $self;
}

sub load {
   my ($self, $thes) = @_;
   $self->file($thes);
   tie @{$self->rawdata}, 'Tie::File', $self->file, mode => O_RDONLY;
}

sub fd {
   my ($self, $fd) = @_;
   $self->{fd} = $fd if $fd;
   return $self->{fd};
}

sub open {
   my ($self, $file) = @_;
   $self->file($file);
   open $self->{fd}, $file or die "Unable to open $file: $!\n";
   return 1;
}

sub next {
   my ($self, $array) = @_;
   my $fd = $self->fd;
   my $line = <$fd>;
   if(!defined $line) {
      close $self->fd;
      return undef;
   }
   chomp $line;
   push @$array, split /,/, $line;
   return $line;
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

=pod

=head1 NAME

Text::Thesaurus::Moby - loads the Moby thesaurus lexicon.

=head1 SYNOPSIS

   #load the thesaurus
   my $mobyobj = Text::Thesaurus::Moby->new;
   $mobyobj->load('../data/moby/thes/mthesaur.txt');

   #example 1 - manual search
   for my $line(@{$mobyobj->rawdata}) {
      chomp $line;
      my @words = split /,/, $line;
      my $root = shift @words;
      @words = undef && next if !$root;
      chomp @words;
      say "root $root and lexicon word: $_" for @words;
   }

   #example 2 - definition count
   say "'accord' synset ", $mobyobj->synset('accord');
   say "'accord' search ", $mobyobj->search('accord');

=head1 DESCRIPTION

Text::Thesaurus::Moby loads the thesaurus lexicons from the Moby project,
which can be downloaded from the Project Gutenberg website (see the
L<COPYRIGHT AND LICENSE> section).

The Moby thesaurus is a B<large> thesaurus built by humans and is considered
accurate. Each line is a CSV list with the first word as the root word. Each
subsequent word on the same line is similar to the root word, and inplicitly
to all other words on the line. Each word may be a multi-word phrase as well,
punctuated only by commas.

Due to the sheer size of this lexicon, and potential problems returning list
data from subroutines, this package will only provide direct access to the
internal raw data. Duplication of any of this data is likely to leak by Perl
itself. If it is necessary to temporarily store the data, the user of this
package must ensure that it can be deallocated quickly (undef all references
immediately when finished). Failure to do so has been seen to leak large
amounts of memory.

=head1 METHODS

=head2 new

Constructs a new instance of this object. The method can take the following
parameters:

=over 4

=item * file => local file containing the thesaurus lexicon

=item * raw => raw data to initialize with (ArrayOfStr)

=back

=head2 load(file)

Begin processing the lexicon I<file>. This is fast as it only ties to the
thesaurus.

=head2 synset(root)

Return the synset, or synonym set, relating to the root word I<root>.

=head2 search(word)

Search for I<word> and return all root words that are associated to it.

=head2 file(setname)

Current file of the tagged lexicon. This is can technically be any thesaurus
file, as long as it follows the same format as Moby.

If no name is specified, this is an accessor. If B<setname> is specified,
it will change the name of the current filename; this is not advisable after
data has been loaded.

=head2 rawdata(data)

This method returns the crucial lexicon and should be used with care. This will
be in all lowercase seperated by commas. The first word is considered the 'root'
word and all subsequent words are related to some degree.

If no I<data> parameter is specified, this is an accessor. Otherwise, it will
set the current raw data to I<data>.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The Moby thesaurus lexicons are licensed under public domain. See
L<http://www.gutenberg.org/etext/3202> for more details.

=cut

__END__
