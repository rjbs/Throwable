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

has stack_trace => (
  is  => 'ro',
  isa => 'Defined',
  default => sub {
    Devel::StackTrace->new(
      ignore_class => [ __PACKAGE__ ]
    );
  },
);

no Moose;
1;
