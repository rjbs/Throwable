package Throwable;
use Moo::Role;
use Sub::Quote ();
use Scalar::Util ();
use Carp ();

# ABSTRACT: a role for classes that can be thrown

=head1 SYNOPSIS

  package Redirect;
  use Moose;
  with 'Throwable';

  has url => (is => 'ro');

...then later...

  Redirect->throw({ url => $url });

=head1 DESCRIPTION

Throwable is a role for classes that are meant to be thrown as exceptions to
standard program flow.  It is very simple and does only two things: saves any
previous value for C<$@> and calls C<die $self>.

=attr previous_exception

This attribute is created automatically, and stores the value of C<$@> when the
Throwable object is created.

=cut

has 'previous_exception' => (
  is       => 'ro',
  init_arg => undef,
  default  => Sub::Quote::quote_sub(q{
    if (defined $@ and (ref $@ or length $@)) {
      $@;
    } else {
      undef;
    }
  }),
);

=method throw

  Something::Throwable->throw({ attr => $value });

This method will call new, passing all arguments along to new, and will then
use the created object as the only argument to C<die>.

If called on an object that does Throwable, the object will be rethrown.

=cut

sub throw {
  my ($inv) = shift;

  if (Scalar::Util::blessed($inv)) {
    Carp::confess "throw called on Throwable object with arguments" if @_;
    die $inv;
  }

  my $throwable = $inv->new(@_);
  die $throwable;
}

no Moo::Role;
1;
