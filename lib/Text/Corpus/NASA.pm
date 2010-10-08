package Text::Corpus::NASA;

use warnings;
use strict;
use Data::Dumper;
use Fcntl qw/O_RDONLY/;
use Tie::File;
use Text::ExtractWords qw(words_list);
use Text::Sentence qw(split_sentences);
use POSIX qw(locale_h);

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $self = {file => $init->{file},
               minwordlen => $init->{minwordlen} // 2,
               maxwordlen => $init->{maxwordlen} // 30,
               raw => []};
   bless $self, $class;
   $self->load($init->{file}) if $init->{file};
   return $self;
}

sub load {
   my ($self, $lex) = @_;
   $self->file($lex);
   my @filedata;
   tie @filedata, 'Tie::File', $self->file, mode => O_RDONLY;

   for my $line(@filedata) {
      chomp $line;
      my @words;
      words_list(\@words, $line, {minwordlen => $self->minwordlen,
                                  maxwordlen => $self->maxwordlen});

      push @{$self->rawdata}, @words;
   }
   untie @filedata;
   undef @filedata;
}

sub _normalize {
   my ($self, $string) = @_;
   return if !$string || !$$string;
   chomp $$string;
   $$string =~ s/_/ /g;
   $$string = lc $$string;
}

sub minwordlen {
   my ($self, $min) = @_;
   $self->{minwordlen} = $min if $min;
   return $self->{minwordlen};
}

sub maxwordlen {
   my ($self, $max) = @_;
   $self->{maxwordlen} = $max if $max;
   return $self->{maxwordlen};
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

1;

=pod

=head1 NAME

Text::Lexicon::MPQA - loads the MPQA lexicon.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructs a new instance of this object. The method can take the following
parameters:

=over 4

=item * file => local file containing the lexicon

=item * raw => raw data to initialize with (ArrayOfHash)

=back

=head2 load(file)

Begin processing the lexicon I<file>. Due to the small size of this lexicon,
the load the data from the I<file> immediately.

=head2 search(word)

Return the structured lexicon data, relating to the word I<word>.

=head2 file(setname)

Current file of the tagged lexicon. This is can technically be any thesaurus
file, as long as it follows the same format as MPQA.

If no name is specified, this is an accessor. If I<setname> is specified,
it will change the name of the current filename; this is not advisable after
data has been loaded.

=head2 rawdata(data)

This method returns the crucial lexicon and should be used with care. This will
be set of hashes representing the data that was parsed from the MPQA lexicon.

If no I<data> parameter is specified, this is an accessor. Otherwise, it will
set the current raw data to I<data>.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The MPQA Opinion Corpus lexicon are owned and licensed by MITRE. See
L<http://www.cs.pitt.edu/mpqa/> for more details.

=cut

__END__
