package Throwable::Error;
use Moose;
with 'Throwable';
# ABSTRACT: an easy-to-use class for error objects

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
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

{
  use Moose::Util::TypeConstraints;

  my $tc = subtype as 'ClassName';
  coerce $tc, from 'Str', via { Class::MOP::load_class($_) };

  has stack_trace_class => (
    is      => 'ro',
    isa     => $tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_stack_trace_class',
  );

  no Moose::Util::TypeConstraints;
}

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

sub _build_stack_trace_class {
  return 'Devel::StackTrace';
}

sub _build_stack_trace_args {
  my ($self) = @_;
  my $found_mark = 0;
  my $uplevel = 4; # number of *raw* frames to go up after we found the marker
  return [
    ignore_class     => [ __PACKAGE__ ],
    find_start_frame => sub {
      my ($raw) = @_;
      $found_mark ||= scalar $raw->{caller}->[3] =~ /__stack_marker$/;
      return 0 unless $found_mark;
      return !$uplevel--;
    },
  ];
}

sub _build_stack_trace {
  my ($self) = @_;
  return $self->stack_trace_class->new(
    @{ $self->stack_trace_args },
  );
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
