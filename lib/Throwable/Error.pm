package Throwable::Error;
use Moose;
with 'Throwable';

use Devel::StackTrace;
use overload
  q{""}    => 'as_string',
  fallback => 1;

sub as_string {
  my ($self) = @_;

  my $str = $self->message;
  $str .= "\n\n" . $self->stack_trace->as_string;

  return $str;
}

has message => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has stack_trace_args => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_stack_trace_args',
);

has stack_trace => (
  is      => 'ro',
  isa     => 'Defined',
  builder => '_build_stack_trace',
);

sub _build_stack_trace_args {
  my ($self) = @_;
  return [ignore_class => [ __PACKAGE__ ]];
}

sub _build_stack_trace {
  my ($self) = @_;
  return Devel::StackTrace->new(
    @{ $self->stack_trace_args },
  );
}

no Moose;
1;
