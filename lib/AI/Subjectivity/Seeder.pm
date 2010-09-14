package AI::Subjectivity::Seeder;
use Moose::Role;

after 'build' => sub { };

1;

=pod

=head1 NAME

AI::Subjectivity::Seeder - role that all seeding algorithms must abide.

=head1 SYNOPSIS

 #build a seeder called Foo
 package AI::Subjectivity::Seed::Foo;

 use Moose;

 extends 'AI::Subjectivity::Seed';
 with 'AI::Subjectivity::Seeder';

 #two parameters: self and a word to trace (if enabled)
 sub build {
    my ($self, $trace) = @_;
    #...
 }
 1;

=head1 DESCRIPTION

This provides a contract all seeding algorithms must abide. In order to
seed a subjectivity lexicon, the only method a package must implement is
the B<build> method. B<build> takes 2 parameters: I<self>, and a I<tracer>.

The I<tracer> parameter is a word to trace. Each seeding algorithm may determine
how and what is traced, but this is typically requested from the caller. For
example, if we wanted to trace what happens to the word 'used', pass that in
as the I<tracer> parameter.

=head1 AUTHOR

Jason Switzer <s1n@voidreturn.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jason Switzer. The entire module may be
redistributed and/or modified under the terms of the MIT license. See
L<http://www.opensource.org/licenses/mit-license.php>.

=cut

__END__
