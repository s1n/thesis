package AI::Subjectivity::Seed::WordNet;

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
   lazy => 1,
   default => sub { WordNet::QueryData->new('/usr/share/wordnet/dict/') },
);

sub read_data_files {
   my ($self, $filesref) = @_;
   return 1;
}

sub build {
   my ($self, $trace) = @_;
   my $lexref = $self->lexicon;
   my %senses = ('n' => 'syns',
                 'v' => 'syns',
                 'a' => 'also');
   my %newscores;

   #loop over every word in the lexicon
   while(my ($root, $score) = each(%$lexref)) {
      my @relatedwords;
      for my $pos(qw/n v a/) {
         $self->_trace_word_r("$root\#$pos",
                              $senses{$pos},
                              \@relatedwords,
                              $self->depth);
         #$self->_trace_word("$root\#$pos", $senses{$pos}, \@relatedwords);
      }

      my $rdelta = $self->signed($lexref->{$root});
      my $log = '';
      for my $w(@relatedwords) {
         next if !$w;
         $rdelta += $self->signed($lexref->{$w} // 0);
      }

      my $delta = $self->signed($rdelta);
      $newscores{$root} += $delta;
      for my $w(@relatedwords) {
         $newscores{$w} += $delta;
         my $temp = $lexref->{$w} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         if($temp != 0 || $w eq $trace) {
            $log .= "$w($temp|$newscores{$w}|$upordown), ";
         }
      }

      if($trace eq "*" || $root eq $trace ||
         ($trace && grep {$_ eq $trace} @relatedwords)) {
         my $temp = $lexref->{$root} // 0;
         my $upordown = '=';
         $upordown = '+' if $delta > 0;
         $upordown = '-' if $delta < 0;
         say "$root($temp|$newscores{$root}|$upordown), $log";
      }
      undef @relatedwords;
   }
   undef $self->{wordnet};

   while(my ($key, $score) = each(%newscores)) {
      say "lexicon adjust $key to $score" if $key eq $trace;
      $lexref->{$key} += $score
   }
   undef %newscores;
}

sub _trace_word_r {
   my ($self, $root, $sense, $wordsref, $depth) = @_;
   say "===========> tracing $root";
   return if(0 >= $depth);
   if(1 >= $depth) {
      my @words = $self->_query_sense($root, $sense);
      for my $nw(@words) {
         my @wordparts = split /#/, $nw;
         push @$wordsref, $wordparts[0] if !grep {$_ eq $nw} @$wordsref;
      }
      return $depth;
   }

   my @words = $self->_query_sense($root, $sense);
   for my $w(@words) {
      $self->_trace_word_r($w, $sense, $wordsref, $depth - 1);
      my @wordparts = split /#/, $w;
      push @$wordsref, $wordparts[0] if !grep {$_ eq $w} @$wordsref;
   }
}

sub _trace_word {
   my ($self, $root, $sense, $wordsref) = @_;
   #say "tracing $root as $sense";

   my @words = $self->_query_sense($root, $sense);
   for my $w(@words) {
      my @newwords = $self->_query_sense($w, $sense);
      for my $nw(@newwords) {
         my @newwords2 = $self->_query_sense($nw, $sense);
         for my $nw2(@newwords2) {
            my @wordparts = split /#/, $nw2;
            push @$wordsref, $wordparts[0] if !grep(/$nw2/, @$wordsref);
         }
         ##my @wordparts = split /#/, $nw;
         ##push @$wordsref, $wordparts[0] if !grep(/$nw/, @$wordsref);
         #push @$wordsref, $nw if !grep(/$nw/, @$wordsref);
      }
   }
}

sub _query_sense {
   my ($self, $phrase, $sense) = @_;
   #say "query phrase $phrase sense $sense";
   my @results = $self->wordnet->querySense($phrase, $sense);
   my $dump = join(", ", @results);
   #say "$sense => $dump" if $dump;
   @results;
}

sub _query_word {
   my ($self, $phrase, $word) = @_;
   my @results = $self->wordnet->queryWord($phrase, $word);
   my $dump = join(", ", @results);
   #say "$word => $dump" if $dump;
   @results;
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

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Jason Switzer <s1n@voidreturn.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

The WordNet lexicon may be licensed under different terms. See
L<http://wordnet.princeton.edu/> for more details.

=cut

__END__
