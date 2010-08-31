package Stats::Measure;

use warnings;
use strict;
use Carp;
use Math::Trig ':pi';

sub new {
   my $class = shift;
   $class = ref $class if ref $class;
   my $init = shift;
   my $self = {plan => $init->{plan},
              };
   bless $self, $class;
   return $self;
}

sub plan {
   my ($self, $plan) = @_;
   $self->{plan} = $plan if $plan;
   return $self->{plan};
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
