#!/usr/bin/env perl

use v5.18;

use strict;
use warnings;

use Test::More;

use Tested::Benchmarks;

my $C = Tested::Benchmarks->new();
ok $C,     'new returned something';
ok ref $C, 'new returned a reference';
is ref $C, 'Tested::Benchmarks', 'new returned an BDP object';

done_testing;
