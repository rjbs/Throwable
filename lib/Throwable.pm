package Throwable;
use Moose::Role;

sub throw {
  die "if you can read this, you're here too early";
}

1;
