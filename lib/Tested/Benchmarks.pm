use v5.40;

use Object::Pad;

class Tested::Benchmarks;

=head1 NAME

Tested::Benchmarks - test your subroutines before benchmarking

=head1 VERSION

This is
version 0.001
released 2024-10-08

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

    use Tested::Benchmarks;

    my $tester = Tested::Benchmarks->new;

    # add some subroutines to test
    $tester->add_subs(qr/^counter\d*/);

    # add some tests
    $tester->add_tests(
        [ [1,0]       => [1,0], "does this even work?" ],
        [ [1,1]       => [0,0] ],
        [ [1,0,0]     => [2,0,0] ],
        [ [1,1,1]     => [0,0,0] ],
        [ [5,2,7,4,3] => [3,0,2,1,0] ],
    );

    # run the tests
    $tester->test;

    # create a body template for Benchmark::cmpthese
    $tester->benchmark_body('%f(%a)', [ [ map { int rand 100 } 1 .. 100 ] ] );

    # run the benchmark
    $tester->cmpthese(-10);

=head1 DESCRIPTION

=cut

use Benchmark ();
use List::Util 'uniq';
use Package::Stash ();
use Test2::V0 ();
# Test->builder->output('/dev/null'); # XXX # only display fails!

use Data::Dump;                 # FIXME

=head1 CONSTRUCTOR

=cut

field $jobs;
field $package;
field $stash;
field $sut   :reader :param = [];
field $tests         :param = [];

=head1 METHODS

=head2 add_subs

=cut

method add_subs(@args) {
    $package = scalar caller;
    $stash   = Package::Stash->new($package);

    for my $arg (@args) {
        push @$sut, grep {
            _matches($_, $arg)
        } $stash->list_all_symbols('CODE');
    }
    $sut = [ uniq sort @$sut ];
}

=head2 add_tests

=cut

method add_tests(@tests_) {
    push @$tests, @tests_;
}

=head2 benchmark_body

=cut

method benchmark_body($template, $arg) {
    for my $sub (@$sut) {
        my $body = $template =~ s/\%f/${package}::$sub/rg;
        $body                =~ s/\%a/\$arg/g;

        $jobs->{$sub} = eval "sub { $body }";
    }
}

=head2 cmpthese

=cut

method cmpthese($count) {
    Benchmark::cmpthese $count, $jobs;
}

sub _matches($hay, $needle) {
    # ref $needle eq 'Regexp'
    $needle isa 'Regexp'
        ? $hay =~ $needle
        : $hay eq $needle;
}

=head2 test

=cut

method test() {
    for my $sub (@$sut) {
        Test2::V0::note(qq(Testing "$sub"));
        for my $test (@$tests) {
            my ($given, $expected, $message) = @$test;
            $message //= sprintf "%s(%s) => %s",
                $sub, map { Data::Dump::dump($_) } $given, $expected;
            { no strict 'refs';
              Test2::V0::is("${package}::$sub"->($given), $expected, $message) }
        }
    }
    Test2::V0::done_testing();
}

=head1 AUTHOR, COPYRIGHT AND LICENSE

Copyright 2024 Brian Greenfield <briang at cpan dot org>

This is free software. You can use, redistribute, and/or modify it
under the terms laid out in the L<MIT licence|LICENCE>.

=head1 SEE ALSO

L<Benchmark>

L<Release::Checklist>

L<Github Actions for Perl running on Windows, Mac OSX, and Ubuntu
Linux|https://perlmaven.com/github-actions-running-on-3-operating-systems>
by Gabor Szabo

TODO: others?

=head1 CODE REPOSITORY AND ISSUE REPORTING

This project's source code is
L<hosted|https://github.com/briang/p5-tested-benchmarks> on
L<GitHub.com|http://github.com>.

Issues should be reported using the project's GitHub L<issue
tracker|https://github.com/briang/p5-tested-benchmarks/issues>.

Contributions are welcome. Please use L<GitHub Pull
Requests|https://github.com/briang/p5-tested-benchmarks/pulls>.

=head1 TODO: more pod???

=cut

1;
