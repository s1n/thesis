package AI::Subjectivity::Seed::WordNet;

use Hash::Util qw/lock_keys unlock_keys/;
use Data::Dumper;
use Modern::Perl;
use WordNet::QueryData;
use Moose;

extends 'AI::Subjectivity::Seed';
with 'AI::Subjectivity::Seeder';

has 'depth' => (
   is => 'rw',
   isa => 'Int',
   lazy => 1,
   default => sub { 2 },
);

has 'wordnet' => (
   is => 'rw',
   isa => 'WordNet::QueryData',
);

has 'aslalgo' => (
   is => 'rw',
   isa => 'AI::Subjectivity::Seed::ASL',
);

sub init {
   my ($self, $filesref) = @_;
   if($filesref->{depth}) {
      $self->depth($filesref->{depth});
   }
   my $home = $filesref->{wnhome} // '/usr/share/wordnet/dict/';
   $self->wordnet(WordNet::QueryData->new($home));
   #if(defined $filesref->{dict} && @{$filesref->{dict}}) {
   #   use AI::Subjectivity::Seed::ASL;
   #   $self->aslalgo(AI::Subjectivity::Seed::ASL->new);
   #   $self->aslalgo->init({dict => $filesref->{dict}});
   #}
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $wordsrc = $self->lexicon;
   #if(defined $self->aslalgo && $self->aslalgo->dictionary) {
   #   $wordsrc = $self->aslalgo->dictionary;
   #}
   my $lexref = $self->lexicon;
   my %senses = ('n' => 'syns',
                 'v' => 'syns',
                 'r' => 'syns',
                 'a' => 'also');
   my %newscores;
   my @words = keys %$wordsrc;
   my $precount = scalar keys %$wordsrc;

   #loop over every word in the lexicon
   while(my ($root, $score) = each(%$wordsrc)) {
      next if !$root || $self->is_stopword($root);
      #say "recursive root word trace: $root";
      my %relatedwords;
      while(my ($pos, $sens) = each(%senses)) {
         $self->_trace_word_r("$root\#$pos",
                              $sens,
                              $self->depth,
                              \%relatedwords);
      }

      #finished tracing wordnet at this point, safe to modify @relatedwords
      my $log = '';
      $newscores{$root}{score} = $lexref->{$root}->{score};
      $newscores{$root}{weight} = $lexref->{$root}->{weight};
      my $rdelta = $self->weigh($lexref->{$root});
      for my $w(keys %relatedwords) {
         next if !$w || $self->is_stopword($w);
         $self->_normalize(\$w);
         $newscores{$w}{score} = $lexref->{$w}->{score};
         $newscores{$w}{weight} = $lexref->{$w}->{weight};
         $rdelta += $self->weigh($lexref->{$w});
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root}{score} += $delta;
      for my $w(keys %relatedwords) {
         next if !$w || $self->is_stopword($w);
         $self->_normalize(\$w);
         $newscores{$w}{score} += $delta;
         my $temp = $self->weigh($lexref->{$w});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         if($temp != 0 || $w eq $trace || $trace eq "*") {
            $log .= "$w($temp|$newscores{$w}{score}|$upordown), ";
         }
      }

      if($trace eq "*" || $root eq $trace ||
         ($trace && grep {$_ eq $trace} keys %relatedwords)) {
         my $temp = $self->weigh($lexref->{$root});
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say STDERR "$root($temp|$newscores{$root}{score}|$upordown), $log";
      }
      undef %relatedwords;
   }
   undef $self->{wordnet};

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
   my ($self, $root, $sense, $depth, $wordsref) = @_;
   #say "===========> tracing $root @ $depth";
   return if(0 >= $depth);
   if(1 >= $depth) {
      my @words;
      $self->_query_sense($root, $sense, \@words);
      for my $nw(@words) {
         $self->_normalize(\$nw);
         next if !$nw || $self->is_stopword($nw);
         next if defined $wordsref->{$nw};
         $wordsref->{$nw} = 1;
      }
      return $depth;
   }

   my @words;
   $self->_query_sense($root, $sense, \@words);
   for my $w(@words) {
      my $newd = $depth;
      $newd-- if $w =~ /#\d+$/;
      $self->_trace_word_r($w, $sense, $newd, $wordsref);
      $self->_normalize(\$w);
      next if defined $wordsref->{$w};
      $wordsref->{$w} = 1;
   }
}

sub _query_sense {
   my ($self, $phrase, $sense, $results) = @_;
   #say "query phrase $phrase sense $sense";
   push @$results, $self->wordnet->querySense($phrase, $sense);
}

no Moose;
1;

=pod

=head1 NAME

AI::Subjectivity::Seed::WordNet - builds a subjectivity lexicon by tracing
WordNet.

=head1 SYNOPSIS

See L<AI::Subjectivity::Seed>.

=head1 DESCRIPTION

WordNet is a manually created lexicon of associations that is peer
reviewed by the academic community.

For every word in either the dictionary or the lexicon (depending on if the ASL
module is preloaded with dictionary data), it will trace words returned by
WordNet. The I<depth> parameter will control how deep it will DFS traverse.

=head1 ATTRIBUTES

=head2 wordnet

The L<WordNet::QueryData> object that assists with accessing the WordNet data.
The WordNet data must be installed locally.

=head2 depth

How deep to traverse the WordNet results. Traversing the results is done as a
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
optional parameters, such as I<wnhome>, I<depth>, and I<dict>.

=head1 AUTHOR

Jason Switzer <s1n at voidreturn dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The WordNet lexicon may be licensed under different terms. See
L<http://wordnet.princeton.edu/> for more details.

=cut

__END__
