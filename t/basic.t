#!perl
use strict;
use warnings;
use Test::More;

my $extra_frames;
BEGIN {
  my $class = 'Moo';
  $extra_frames = 0;
  if ($Throwable::_TEST_MOOSE) {
    $class = 'Moose';
    $extra_frames++ # the "do" in xt/moose.t adds a frame
  }
  eval qq{
    package MyError;
    use $class;
    extends 'Throwable::Error';

    1;
  } or die $@;
}

sub throw_x {
  MyError->throw({ message => 'foo bar baz' });
}

sub call_throw_x {
  throw_x;
}

eval { call_throw_x; };

my $error = $@;

isa_ok($error, 'MyError',          'the error');
isa_ok($error, 'Throwable::Error', 'the error');
is($error->message, q{foo bar baz}, "error message is correct");

my $trace = $error->stack_trace;

isa_ok($trace, 'Devel::StackTrace', 'the trace');

my @frames = $trace->frames;
is(@frames, 4 + $extra_frames, "we have four frames in our trace");
is($frames[0]->subroutine, q{Throwable::throw},   'correct frame 0');
is($frames[1]->subroutine, q{main::throw_x},      'correct frame 1');
is($frames[2]->subroutine, q{main::call_throw_x}, 'correct frame 2');
is($frames[3]->subroutine, q{(eval)},             'correct frame 3');

{
   eval { MyError->throw('shucks howdy'); };

   my $error = $@;
   isa_ok($error, 'MyError', 'the error');
   is($error->message, q{shucks howdy}, "error message is correct");
}

{
  package HasError;
  sub new { bless { error => MyError->new("flabba") } }
}

sub create_error { HasError->new->{error} }

{
  my $error = create_error();

  my @frames = $error->stack_trace->frames;
  is(@frames, 2 + $extra_frames, "two frames from constructor");
  is($frames[0]->subroutine, q{HasError::new}, 'correct constructor in frame 0');
  is($frames[1]->subroutine, q{main::create_error}, 'correct frame 1');
}

{
    package MyTrace;
    use base 'Devel::StackTrace';
}

# make sure to catch intermittent failures due to attribute initialisation order
for my $i (1..10) {
    eval { MyError->throw({ message => 'aieee!', stack_trace_class => 'MyTrace' }) };

    my $error = $@;
    isa_ok($error->stack_trace, 'MyTrace', "the trace (run $i)")
}

done_testing();
