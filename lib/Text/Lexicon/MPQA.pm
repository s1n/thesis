package Text::Lexicon::MPQA;

use warnings;
use strict;
use Data::Dumper;
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
   my ($self, $lex) = @_;
   $self->file($lex);
   my @filedata;
   tie @filedata, 'Tie::File', $self->file, mode => O_RDONLY;

   for my $line(@filedata) {
      chomp $line;
      my @words = split /\s+/, $line;
      my %tokenized = map { my @kv = split/\s*=\s*/;
                            $self->_normalize(\$kv[0]);
                            $self->_normalize(\$kv[1]);
                            $kv[0] => $kv[1]
                          } @words;
      push @{$self->rawdata}, \%tokenized;
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

sub search {
   my ($self, $searching) = @_;
   my @synset;
   for my $entry(@{$self->rawdata}) {
      if($entry->{word} eq $searching) {
         push @synset, %$entry;
      }
   }
   return @synset;
}

1;

=pod

=head1 NAME

Text::Lexicon::MPQA - loads the MPQA lexicon.

=head1 SYNOPSIS

   #load the lexicon
   my $mobyobj = Text::Lexicon::MPQA->new;
   $mobyobj->load('../data/MPQA/subjclueslen1-HLTEMNLP05.tff');

   #example 1 - manual search
   for my $line(@{$mpqaobj->rawdata}) {
      chomp $line;
      my @words = split /\s+/, $line;
      my %tokenized = map { my @kv = split/\s*=\s*/; $kv[0] => $kv[1] } @words;
      while(my ($key, $val) = each(%tokenized)) {
         say "$key => $val";
      }
   }

   #example 2 - definition count
   say "'accord' polarity", $mpqaobj->priorpolarity('accord');
   say "'accord' part of speech", $mpqaobj->pos('accord');
   say "'accord' type", $mpqaobj->type('accord');
   say "'accord' is stemmed", $mpqaobj->stemmed('accord');
   say "'accord' len", $mpqaobj->len('accord');

   #example 3 - search
   print Dumper($mpqa->search('accord'));

=head1 DESCRIPTION

Text::MPQA::MPQA loads the lexicons from the MPQA project, which can be
downloaded from the Project Gutenberg website (see the
L<COPYRIGHT AND LICENSE> section).

The MPQA lexicon is a large manually (and automatically) annotated lexicon
that includes POS tags (parts of speech) and subjectivity labels. Therefore,
this dataset is of high quality. Each line in the lexicon contains a set of
key/value pairs seperated by '='. Each key/value pair on the line is space
delimited. See the MPQA README file for more information about what each
field represents, though basic information is available in this module.

At current writing, there are only about 8,000 entries in the MPQA lexicon,
which makes for a small dataset. Since this dataset is so small, techniques
such as those needed by the L<Text::Thesaurus::Moby> module are most likely
unnecessary. No attempt has been made to reduce this module's footprint.

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
