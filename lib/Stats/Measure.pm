package Stats::Measure;

use warnings;
use strict;
use Math::Trig ':pi';

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $self = {truepositive => $init->{truepositive},
               truenegative => $init->{truenegative},
               falsepositive => $init->{falsepositive},
               falsenegative => $init->{falsenegative},
               unknown => $init->{unknown},
              };
   bless $self, $class;
   return $self;
}

sub unknown {
   my ($self, $unk) = @_;
   $self->{unknown} += $unk if $unk;
   return $self->_normalize($self->{unknown});
}

sub truepositive {
   my ($self, $truepos) = @_;
   $self->{truepositive} += $truepos if $truepos;
   return $self->_normalize($self->{truepositive});
}

sub tp {
   my ($self) = @_;
   return $self->truepositive;
}

sub truenegative {
   my ($self, $trueneg) = @_;
   $self->{truenegative} += $trueneg if $trueneg;
   return $self->_normalize($self->{truenegative});
}

sub tn {
   my ($self) = @_;
   return $self->truenegative;
}

sub falsepositive {
   my ($self, $falsepos) = @_;
   $self->{falsepositive} += $falsepos if $falsepos;
   return $self->{falsepositive} // 0;
}

sub fp {
   my ($self) = @_;
   return $self->falsepositive;
}

sub falsenegative {
   my ($self, $falseneg) = @_;
   $self->{falsenegative} += $falseneg if $falseneg;
   return $self->_normalize($self->{falsenegative});
}

sub fn {
   my ($self) = @_;
   return $self->falsenegative;
}

sub precision {
   my ($self) = @_;
   my $denom = $self->tp + $self->fp;
   return 0 if $denom == 0;
   return $self->tp / $denom;
}

sub recall {
   my ($self) = @_;
   my $denom = $self->tp + $self->fn;
   return 0 if $denom == 0;
   return $self->tp / $denom;
}

sub sensitivity {
   my ($self) = @_;
   my $denom = $self->tp + $self->fn;
   return 0 if $denom == 0;
   return $self->tp / $denom;
}

sub specificity {
   my ($self) = @_;
   my $denom = $self->fp + $self->tn;
   return 0 if $denom == 0;
   return $self->tn / $denom;
}

sub accuracy {
   my ($self) = @_;
   my $denom = $self->tp + $self->fp + $self->fn + $self->tn;
   return 0 if $denom == 0;
   return ($self->tp + $self->tn) / $denom;
}

sub youden {
   my ($self) = @_;
   return $self->_normalize($self->sensitivity - (1 - $self->specificity));
}

sub f_measure {
   my ($self, $beta) = @_;
   $beta = 1 if !$beta;
   my $betasq = $beta ** 2;
   my $precision = $self->precision;
   my $recall = $self->recall;
   my $denom = $betasq * $precision + $recall;
   return 0 if $denom == 0;
   return (1 + $betasq) * (($precision * $recall) / $denom);
}

sub f1 {
   my ($self) = @_;
   return $self->f_measure;
}

sub e_measure {
   my ($self, $beta) = @_;
   return $self->_normalize(1 - $self->f_measure($beta));
}

sub p_minus {
   my ($self) = @_;
   my $denom = 1 - $self->specificity;
   return 0 if $denom == 0;
   return $self->sensitivity / $denom;
}

sub p_plus {
   my ($self) = @_;
   my $denom = $self->specificity;
   return 0 if $denom == 0;
   return (1 - $self->sensitivity) / $denom;
}

sub discriminant_power {
   my ($self, $base) = @_;
   my $sqrt3 = sqrt(3) / pi;
   my $logx = $self->sensitivity / (1 - $self->sensitivity);
   $logx = log($logx);
   $logx /= log($base) if $base;
   my $logy = $self->specificity / (1 - $self->specificity);
   $logy = log($logy);
   $logy /= log($base) if $base;
   return $sqrt3 * ($logx + $logy);
}

sub dp {
   my ($self) = @_;
   return $self->discriminant_power;
}

sub incommon {
   my ($self) = @_;
   return $self->tp + $self->tn + $self->fp + $self->fn;
}

#FIXME add cosine, lesk, dice

sub _normalize {
   my ($self, $number) = @_;
   return $number // 0;
}

1;

=pod

=head1 NAME

Stats::Measure - basic accuracy measurements.

=head1 SYNOPSIS

 my $stat = Stats::Measure->new;
 $stat->falsepositive(10);
 $stat->falsenegative(102);
 $stat->truepositive(200);
 $stat->truenegative(22);
 say "f1-measure: ", $stat->f_measure;
 say "f2-measure: ", $stat->f_measure(2);
 say "youden: ", $stat->youden;

=head1 DESCRIPTION

This package is a basic means of reporting statistical accuracy. It acts
independent of the means that determines correctness, only tracks true/false
positives/negatives and reports a number of different metrics.

=head1 METHODS

=head2 new

=head2 truepositive(num) / tp(num)

Increments the current truepositive count by B<num>. B<tp> is a synonym for the
B<truepositive> method.

=head2 truenegative(num) / tn(num)

Increments the current truenegative count by B<num>. B<tn> is a synonym for the
B<truenegative> method.

=head2 falsepositive(num) / fp(num)

Increments the current falsepositive count by B<num>. B<fp> is a synonym for the
B<truepositive> method.

=head2 falsenegative(num) / fn(num)

Increments the current falsenegative count by B<num>. B<fn> is a synonym for the
B<truepositive> method.

=head2 unknown(num)

Increments the current unknown count by B<num>. If a result cannot be determined
but still should be tracked, add it here.

=head2 f_measure(beta)

Compute the F measure with any arbibrary B<beta> value. See
L<http://en.wikipedia.org/wiki/F1_score>.

=head2 f1

Computes the F-1 measure. See L<http://en.wikipedia.org/wiki/F1_score>.

=head2 e_measure

Computes the E measure.

=head2 sensitivity

Computes the sensitivity. See
L<http://en.wikipedia.org/wiki/Sensitivity_and_specificity>.

=head2 specificity

Computes the specificity. See
L<http://en.wikipedia.org/wiki/Sensitivity_and_specificity>.

=head2 accuracy

Computes the general accuracy measure.

=head2 precision

Computes the precision. See
L<http://en.wikipedia.org/wiki/Accuracy_and_precision>.

=head2 recall

Computes the precision. See
L<http://en.wikipedia.org/wiki/Accuracy_and_precision>.

=head2 youden

Computes Youden's J statistic. See
L<http://en.wikipedia.org/wiki/Youden's_J_statistic>.

=head2 p_minus

Computes the p+ score.

=head2 p_plus

Computes the p- score.

=head2 discriminant_power / dp

Computes the discriminant power. The B<dp> method is a synonym for the
B<discriminant_power> method.

=head1 AUTHOR

Jason Switzer <s1n@voidreturn.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
