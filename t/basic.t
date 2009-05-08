#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use Throwable::Error;

Throwable::Error->throw({ message => 'foo bar baz' });
