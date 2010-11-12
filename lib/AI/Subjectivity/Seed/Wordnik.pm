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

   if(!$self->wordnik) {
      $self->wordnik(WWW::Wordnik::API->new());
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
   my %newscores;

   my $precount = scalar keys %$wordsrc;
   say STDERR "tracing $precount words";
   #loop over every word in the lexicon
   while(my ($root, $score) = each(%$wordsrc)) {
      next if !$root || $self->is_stripword($root);
      say STDERR "recursive root word trace: $root";
      my %otherrelatedwords;
      $self->_trace_word_r($root, $self->depth, \%otherrelatedwords);
      #die Dumper(\%otherrelatedwords);

      #finished tracing wordnet at this point, safe to modify @relatedwords
      my $log = '';
      $newscores{$root}{score} = $lexref->{$root}->{score};
      $newscores{$root}{weight} = $lexref->{$root}->{weight};
      my $rdelta = $self->weigh($lexref->{$root});
      for my $w(keys %otherrelatedwords) {
         next if !$w || $self->is_stripword($w);
         $self->_normalize(\$w);
         $newscores{$w}{score} = $lexref->{$w}->{score};
         $newscores{$w}{weight} = $lexref->{$w}->{weight};
         $rdelta += $self->weigh($lexref->{$w});
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root}{score} += $delta;
      for my $w(keys %otherrelatedwords) {
         next if !$w || $self->is_stripword($w);
         $self->_normalize(\$w);
         $newscores{$w}{score} += $delta;
         my $temp = $self->weigh($lexref->{$w});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         if($temp != 0 || $w eq $trace) {
            $log .= "$w($temp|$newscores{$w}{score}|$upordown), ";
         }
      }

      if($trace eq "*" || $root eq $trace ||
         ($trace && grep {$_ eq $trace} keys %otherrelatedwords)) {
         my $temp = $self->weigh($lexref->{$root});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say STDERR "$root($temp|$newscores{$root}{score}|$upordown), $log";
      }
      undef %otherrelatedwords;
   }
   undef $self->{wordnik};

   my $postcount = scalar keys %newscores;
   while(my ($key, $score) = each(%newscores)) {
      $self->_normalize(\$key);
      #say STDERR "lexicon adjust $key to $score->{score}" if $key eq $trace;
      $lexref->{$key}->{score} = $score->{score};
      #print "    $key pre=", $lexref->{$key}->{weight} // 0;
      $lexref->{$key}->{weight} = $self->normalize_weight($score->{weight},
                                                          $precount,
                                                          $postcount);
      #print " post=", $lexref->{$key}->{weight}, "\n";
   }
   #print "\n";
   undef %newscores;
}

sub _trace_word_r {
   my ($self, $root, $depth, $wordsref) = @_;
   say STDERR "===========> tracing $root @ $depth";
   return if(0 >= $depth);
   if(1 >= $depth) {
      my @words;
      return $depth if !$root || $self->is_stripword($root);
      $self->_query_word($root, \@words);
      for my $nw(@words) {
         $self->_normalize(\$nw);
         $wordsref->{$nw} = 1;
         #my @wordparts = split /#/, $nw;
         #push @$wordsref, $wordparts[0] if !grep {$_ eq $nw} @$wordsref;
      }
      return $depth;
   }

   my @words;
   $self->_query_word($root, \@words);
   for my $w(@words) {
      next if !$w || $self->is_stripword($w);
      $self->_trace_word_r($w, $depth - 1, $wordsref);
   }
}

#FIXME query antonym for negations (may be positive)
sub _query_word {
   my ($self, $word, $results) = @_;
   my $senses = [qw/variant
                    synonym
                    form
                    hyponym
                    verb-form
                    verb-stem
                    cross-reference
                    same-context/];

   my $delay = int(rand(10)) + 2;
   REQUERY:
   say STDERR "delaying query by $delay seconds...";
   #sleep $delay;
   my @api;
   eval {
      @api = $self->wordnik->related($word,
                                     limit => 1000,
                                     type => $senses);
   };
   if($@) {
      goto REQUERY;
   }
   for my $sets(@api) {
      for my $synset(@$sets) {
         for my $w(@{$synset->{'wordstrings'}}) {
            if($w !~ /[^ A-Za-z0-9]/ && !grep {$_ eq $w} @$results) {
               push @$results, $w;
               say STDERR "** new word discovererd: $w";
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
