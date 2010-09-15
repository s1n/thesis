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

=pod

=head1 NAME

AI::Subjectivity::Seed::ASL - Affix Seel Lexicon generator.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

This Seed algorithm uses the affix patterns discussed in the FIXME paper. Based
the affix patterns defined in a file, this will overtly mark words in pairs as
positive and negative words.

=head1 ATTRIBUTES

=head2 patterns

Gets and sets the set of affix patterns loaded from the affix file. Each affix
pattern comes in pairs:

 negative,positive

where the positive word typically contains a match to $1 from the negative word.
Both the positive and negative words are regular expressions as supported by
Perl. That is, negative words typically add an affix (prefix or suffix). For
example:

 un(happy),$1

matches 'unhappy' as the negative word and 'happy' as the positive word. See
L<AFFIX FILE>.

=head2 dictionary

Gets and sets the dictionary data. As loaded from the file, this is just one
word or phrase. See L<DICT FILE>.

=head1 METHODS

=head2 build(trace)

Runs through the entire dictionary file and matches according to the ASL
algorithm. At the very least, this should be an O(nln) operation, but currently
runs as an O(n**2) algorithm. When finished, the lexicon data will be available
in the B<AI::Subjectivity::Seed::lexicon> property.

When a I<trace> word is specified, this will print all related matches. Note
that '*' will match every string.

=head2 read_dict(file)

Reads a dictionary file and maintains it in the B<dict> attribute. See
L<DICT FILE>.

=head2 read_affix(file)

Reads an affix file and maintains it in the B<thes> attribute. See
L<AFFIX FILE>.

=head2 read_data_files(files)

Reads all files that are supported by this seeding algorithm. This should be
run before B<build> as it's considered a setup function. The I<files> structure
is a hash with the key value pointing to an accessible local filename.

=head1 DICT FILE

Dictionary files have the same format as standard Unix dict files. Each line
contains one word or phrase followed by a newline.

=head1 AFFIX FILE

Affix files contain pairs of words that correspond to positive and negative
correlations. That is, when 2 words match, one will match the positive regex
and the other word will match the negative regex. When this happens, it will
increase their subjectivity scores by 1 and -1 respectively.

For example, the following affix patterns can be found in /data/affix.dat:

 ^(l(.+))$,il$1

will match the words 'logical' and 'illogical' as the positive and negative
words.

Comments can be used, which are lines that begin with a '#' symbol. Inline
comments are not supported. Blank lines will be ignored, but lines that do
not match this format will result in an error.

=head1 AUTHOR

Jason Switzer <s1n@voidreturn.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
