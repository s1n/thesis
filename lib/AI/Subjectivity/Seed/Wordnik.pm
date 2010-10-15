package AI::Subjectivity::Seed::Wordnik;

use Data::Dumper;
use Modern::Perl;
use WWW::Wordnik::API;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'depth' => (
   is => 'rw',
   isa => 'Int',
   lazy => 1,
   default => sub { 2 },
);

has 'wordnik' => (
   is => 'rw',
   isa => 'WWW::Wordnik::API',
   default => sub { WWW::Wordnik::API->new() }
);

has 'aslalgo' => (
   is => 'rw',
   isa => 'AI::Subjectivity::Seed::ASL',
);

sub init {
   my ($self, $filesref) = @_;
   if(defined $filesref->{depth}) {
      $self->depth($filesref->{depth});
   }
   if(!defined $filesref->{apikey}) {
      die "An API key is required to use Wordnik.";
   }

   $self->wordnik->format('perl');
   $self->wordnik->api_key($filesref->{apikey});
   $self->wordnik->cache($filesref->{cache} // 1000);
   if(defined $filesref->{uri}) {
      $self->wordnik->server_uri($filesref->{uri});
   }

   if(defined $filesref->{dict} && @{$filesref->{dict}}) {
      use AI::Subjectivity::Seed::ASL;
      $self->aslalgo(AI::Subjectivity::Seed::ASL->new);
      $self->aslalgo->init({dict => $filesref->{dict}});
   }
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $wordsrc = $self->lexicon;
   if(defined $self->aslalgo && $self->aslalgo->dictionary) {
      $wordsrc = $self->aslalgo->dictionary;
   }
   my $lexref = $self->lexicon;
   my %senses = ('s' => 'synonym',
                 'a' => 'antonym',
                 'f' => 'form',
                 'e' => 'equivalent',
                 'h' => 'hyponym',
                 'v' => 'variant');
   my %newscores;

   #loop over every word in the lexicon
   while(my ($root, $score) = each(%$wordsrc)) {
      say "recursive root word trace: $root";
      my @relatedwords;
      for my $syn(values %senses) {
         $self->_trace_word_r($root, $syn, $self->depth, \@relatedwords);
      }
      die "Found ", scalar @relatedwords, " related words\n";

      #finished tracing wordnet at this point, safe to modify @relatedwords
      my $rdelta = $self->signed($lexref->{$root}->{score});
      my $log = '';
      $newscores{$root} = $lexref->{$root}->{score};
      for my $w(@relatedwords) {
         next if !$w;
         $self->_normalize(\$w);
         $newscores{$w} = $lexref->{$w}->{score};
         $rdelta += $self->signed($lexref->{$w}->{score} // 0);
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root} += $delta;
      for my $w(@relatedwords) {
         next if !$w;
         $self->_normalize(\$w);
         $newscores{$w} += $delta;
         my $temp = $lexref->{$w}->{score} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         if($temp != 0 || $w eq $trace) {
            $log .= "$w($temp|$newscores{$w}|$upordown), ";
         }
      }

      if($trace eq "*" || $root eq $trace ||
         ($trace && grep {$_ eq $trace} @relatedwords)) {
         my $temp = $lexref->{$root}->{score} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say "$root($temp|$newscores{$root}|$upordown), $log";
      }
      undef @relatedwords;
   }
   undef $self->{wordnik};

   while(my ($key, $score) = each(%newscores)) {
      $self->_normalize(\$key);
      say "lexicon adjust $key to $score" if $key eq $trace;
      $lexref->{$key}->{score} = $score
   }
   undef %newscores;
}

sub _trace_word_r {
   my ($self, $root, $sense, $depth, $wordsref) = @_;
   say "===========> tracing $root @", $depth;
   return if(0 >= $depth);
   if(1 >= $depth) {
      my @words;
      $self->_query_word($root, $sense, \@words);
      for my $nw(@words) {
         my @wordparts = split /#/, $nw;
         push @$wordsref, $wordparts[0] if !grep {$_ eq $nw} @$wordsref;
      }
      return $depth;
   }

   my @words;
   $self->_query_word($root, $sense, \@words);
   for my $w(@words) {
      $self->_trace_word_r($w, $sense, $depth - 1, $wordsref);
   }
}

sub _query_word {
   my ($self, $word, $relation, $results) = @_;
   my @api = $self->wordnik->related($word, limit => 1000, type => [$relation]);
   for my $sets(@api) {
      for my $synset(@$sets) {
         say "reltype: ", $synset->{'relType'}, " versus $relation";
         if($synset->{'relType'} eq $relation) {
            for my $w(@{$synset->{'wordstrings'}}) {
               push @$results, $w if !grep {$_ eq $w} @$results;
            }
         }
      }
   }
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectivity::Seed::Wordnik - builds a subjectivity lexicon by tracing
Wordnik.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

Wordnik is designed to be dictionary and thesaurus in the same vein as
Wikipedia, where it has a large pre-built lexicon and users are able to
contribute and modify it.

This will trace Wordnik the same way WordNet is traversed. For every word in
either the dictionary or the lexicon (depending on if the ASL module is
preloaded with dictionary data), it will trace words returned by Wordnik. The
I<depth> parameter will control how deep it will DFS traverse.

=head1 ATTRIBUTES

=head2 wordnik

The L<WWW::Wordnik::API> object that assists with accessing the Wordnik data.
An API key is required to access this data.

=head2 depth

How deep to traverse the Wordnik results. Traversing the results is done as a
depth first search (DFS).

=head2 aslalgo

L<AI::Subjectivity::Seed::ASL> object used to load the dictionary data. If
this object is set, determined by the I<dictionary> parameter to the L<init>
method, the L<build> method will traverse by those words rather than the
preloaded lexicon words.

=head1 METHODS

=head2 build(trace)

Builds the lexicon as described above.

If a I<trace> word is provided, that word will be traced. Passing '*' will
trace all words.

=head2 init(options)

Reads all files that are supported by this seeding algorithm. This should be
run before B<build> as it's considered a setup function. The I<options>
structure is a hash reference with the key value pointing to required and
optional parameters, such as I<apikey>, I<dict>, and I<cache>.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The Wordnik lexicon may be licensed under different terms. See
L<http://www.wordnik.com/> for more details.

=cut

__END__
