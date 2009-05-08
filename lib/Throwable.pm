package Throwable;
use Moose::Role;

has 'previous_exception' => (
  is      => 'ro',
  default => sub {
    return unless defined $@ and ref $@ or length $@;
    return $@;
  },
);

sub throw {
  my ($self, @rest) = @_;
  my $throwable = $self->new(@rest);
  die $throwable;
}

no Moose::Role;
1;
