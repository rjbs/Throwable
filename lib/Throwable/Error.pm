package Throwable::Error;
# ABSTRACT: an easy-to-use class for error objects

use Moo 1.000001;
with 'Throwable', 'StackTrace::Auto';

=head1 SYNOPSIS

  package MyApp::Error;
  # NOTE: Moo/Mouse can also be used here instead of Moose
  use Moose;
  extends 'Throwable::Error';

  has execution_phase => (
    is  => 'ro',
    isa => 'MyApp::Phase',
    default => 'startup',
  );

...and in your app...

  MyApp::Error->throw("all communications offline");

  # or...

  MyApp::Error->throw({
    message         => "all communications offline",
    execution_phase => 'shutdown',
  });

=head1 DESCRIPTION

Throwable::Error is a base class for exceptions that will be thrown to signal
errors and abort normal program flow.  Throwable::Error is an alternative to
L<Exception::Class|Exception::Class>, the features of which are largely
provided by the Moo object system atop which Throwable::Error is built.

Throwable::Error performs the L<Throwable|Throwable> and L<StackTrace::Auto>
roles.  That means you can call C<throw> on it to create and throw an error
object in one call, and that every error object will have a stack trace for its
creation.

=cut

use overload
  q{""}    => 'as_string',
  fallback => 1;

=attr message

This attribute must be defined and must contain a string describing the error
condition.  This string will be printed at the top of the stack trace when the
error is stringified.

=cut

has message => (
  is       => 'ro',
  isa      => Sub::Quote::quote_sub(q{
      die "message must be a string"
          unless defined($_[0]) && !ref($_[0]);
  }),,
  required => 1,
);

=attr stack_trace

This attribute, provided by L<StackTrace::Auto>, will contain a stack trace
object guaranteed to respond to the C<as_string> method.  For more information
about the stack trace and associated behavior, consult the L<StackTrace::Auto>
docs.

=method as_string

This method will provide a string representing the error, containing the
error's message followed by the its stack trace.

=cut

sub as_string {
  my ($self) = @_;

  my $str = $self->message;
  $str .= "\n\n" . $self->stack_trace->as_string;

  return $str;
}

around BUILDARGS => sub {
  my $orig = shift;
  my $self = shift;

  return {} unless @_;
  return {} if @_ == 1 and ! defined $_[0];

  if (@_ == 1 and (!ref $_[0]) and defined $_[0] and length $_[0]) {
    return { message => $_[0] };
  }

  return $self->$orig(@_);
};

1;
