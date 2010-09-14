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
   return $self->{unknown};
}

sub truepositive {
   my ($self, $truepos) = @_;
   $self->{truepositive} += $truepos if $truepos;
   return $self->{truepositive};
}

sub tp {
   my ($self) = @_;
   return $self->truepositive;
}

sub truenegative {
   my ($self, $trueneg) = @_;
   $self->{truenegative} += $trueneg if $trueneg;
   return $self->{truenegative};
}

sub tn {
   my ($self) = @_;
   return $self->truenegative;
}

sub falsepositive {
   my ($self, $falsepos) = @_;
   $self->{falsepositive} += $falsepos if $falsepos;
   return $self->{falsepositive};
}

sub fp {
   my ($self) = @_;
   return $self->falsepositive;
}

sub falsenegative {
   my ($self, $falseneg) = @_;
   $self->{falsenegative} += $falseneg if $falseneg;
   return $self->{falsenegative};
}

sub fn {
   my ($self) = @_;
   return $self->falsenegative;
}

sub precision {
   my ($self) = @_;
   return $self->tp / ($self->tp + $self->fp);
}

sub recall {
   my ($self) = @_;
   return $self->tp / ($self->tp + $self->fn);
}

sub sensitivity {
   my ($self) = @_;
   return $self->tp / ($self->tp + $self->fn);
}

sub specificity {
   my ($self) = @_;
   return $self->tn / ($self->fp + $self->tn);
}

sub accuracy {
   my ($self) = @_;
   return ($self->tp + $self->tn) / ($self->tp + $self->fp + $self->fn + $self->tn);
}

sub youden {
   my ($self) = @_;
   return $self->sensitivity - (1 - $self->specificity);
}

sub f_measure {
   my ($self, $beta) = @_;
   $beta = 1 if !$beta;
   my $betasq = $beta ** 2;
   my $precision = $self->precision;
   my $recall = $self->recall;
   return (1 + $betasq) * (($precision * $recall) / ($betasq * $precision + $recall));
}

sub f1 {
   my ($self) = @_;
   return $self->f_measure;
}

sub e_measure {
   my ($self, $beta) = @_;
   return 1 - $self->f_measure($beta);
}

sub p_minus {
   my ($self) = @_;
   return $self->sensitivity / (1 - $self->specificity);
}

sub p_plus {
   my ($self) = @_;
   return (1 - $self->sensitivity) / $self->specificity;
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

#FIXME add cosine, lesk, dice
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

=cut

__END__
