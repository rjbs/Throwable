#!perl

package My::Trace;
sub new { bless {} }
sub as_string {''}

package My::X;
use Moose;
with (
    'Throwable',
    'StackTrace::Auto',
);

has message => ( is => 'ro' );
has '+stack_trace_class' => ( builder => 'tclass' );
sub tclass { 'My::Trace' }

use Test::More tests => 3;
eval {
    eval "use Foo::Bar::Baz" or My::X->throw(message => 'WTF!');
};
is $@->message, 'WTF!', 'Should have message';
isnt $@->previous_exception, undef, 'Should have previous exception';
isa_ok $@->stack_trace_class, 'My::Trace';
