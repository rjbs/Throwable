package Throwable::Error;
use Moose 0.87;
with 'Throwable';
# ABSTRACT: an easy-to-use class for error objects

=head1 SYNOPSIS

  package MyApp::Error;
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
    message => "all communications offline",
    phase   => 'shutdown',
  });

=head1 DESCRIPTION

Throwable::Error is a base class for exceptions that will be thrown to signal
errors and abort normal program flow.  Throwable::Error is an alternative to
L<Exception::Class|Exception::Class>, the features of which are largely
provided by the Moose object system atop which Throwable::Error is built.

Throwable::Error performs the L<Throwable|Throwable> role.

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
  isa      => 'Str',
  required => 1,
);

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

=attr stack_trace

This attribute will contain an object representing the stack at the point when
the error was generated and thrown.  It must be an object performing the
C<as_string> method.

=attr stack_trace_class

This attribute may be provided to use an alternate class for stack traces.  The
default is L<Devel::StackTrace|Devel::StackTrace>.

In general, you will not need to think about this attribute.

=cut

{
  use Moose::Util::TypeConstraints;

  has stack_trace => (
    is      => 'ro',
    isa     => duck_type([ qw(as_string) ]),
    builder => '_build_stack_trace',
  );

  my $tc = subtype as 'ClassName';
  coerce $tc, from 'Str', via { Class::MOP::load_class($_); $_ };

  has stack_trace_class => (
    is      => 'ro',
    isa     => $tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_stack_trace_class',
  );

  no Moose::Util::TypeConstraints;
}

=attr stack_trace_args

This attribute is an arrayref of arguments to pass when building the stack
trace.  In general, you will not need to think about it.

=cut

has stack_trace_args => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_stack_trace_args',
);

sub _build_stack_trace_class {
  return 'Devel::StackTrace';
}

sub _build_stack_trace_args {
  my ($self) = @_;
  my $found_mark = 0;
  my $uplevel = 3; # number of *raw* frames to go up after we found the marker
  return [
    frame_filter => sub {
      my ($raw) = @_;
      if ($found_mark) {
          return 1 unless $uplevel;
          return !$uplevel--;
      }
      else {
        $found_mark = scalar $raw->{caller}->[3] =~ /__stack_marker$/;
        return 0;
    }
    },
  ];
}

sub _build_stack_trace {
  my ($self) = @_;
  return $self->stack_trace_class->new(
    @{ $self->stack_trace_args },
  );
}

sub BUILDARGS {
  my ($self, @args) = @_;

  return {} unless @args;
  return {} if @args == 1 and ! defined $args[0];

  if (@args == 1 and (!ref $args[0]) and defined $args[0] and length $args[0]) {
    return { message => $args[0] };
  }

  return $self->SUPER::BUILDARGS(@args);
}

around new => sub {
  my $next = shift;
  my $self = shift;
  return $self->__stack_marker($next, @_);
};

sub __stack_marker {
  my $self = shift;
  my $next = shift;
  return $self->$next(@_);
}

no Moose;
1;
