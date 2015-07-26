package Throwable;
# ABSTRACT: a role for classes that can be thrown

use Moo::Role;
use Sub::Quote ();
use Scalar::Util ();
use Carp ();

=head1 SYNOPSIS

  package Redirect;
  # NOTE: Moo can also be used here instead of Moose
  use Moose;
  with 'Throwable';

  has url => (is => 'ro');

...then later...

  Redirect->throw({ url => $url });

=head1 DESCRIPTION

Throwable is a role for classes that are meant to be thrown as exceptions to
standard program flow.  It is very simple and does only two things: saves any
previous value for C<$@> and calls C<die $self>.

Throwable is implemented with L<Moo>, so you can stick to Moo or use L<Moose>,
as you prefer.

=attr previous_exception

This attribute is created automatically, and stores the value of C<$@> when the
Throwable object is created.  This is done on a I<best effort basis>.  C<$@> is
subject to lots of spooky action-at-a-distance.  For now, there are clearly
ways that the previous exception could be lost.

=cut

our %_HORRIBLE_HACK;

has 'previous_exception' => (
  is       => 'ro',
  default  => Sub::Quote::quote_sub(q<
    if (defined $Throwable::_HORRIBLE_HACK{ERROR}) {
      $Throwable::_HORRIBLE_HACK{ERROR}
    } elsif (defined $@ and (ref $@ or length $@)) {
      $@;
    } else {
      undef;
    }
  >),
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

  local $_HORRIBLE_HACK{ERROR} = $@;
  my $throwable = $inv->new(@_);
  die $throwable;
}

=method new_with_previous

  die Something::Throwable->new_with_previous({ attr => $value });

Constructs an exception object and return it, while trying to mae sure that any
values in $@ are safely stored in C<previous_exception> without being stomped
by evals in the construction process.

This is more reliable than calling C<new> directly, but doesn't include the
forced C<die> in C<throw>.

=cut

sub new_with_previous { local $_HORRIBLE_HACK{ERROR} = $@; shift->new(@_) }

no Moo::Role;
1;
