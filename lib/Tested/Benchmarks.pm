use v5.40;

use Object::Pad;

class Tested::Benchmarks {
    use Benchmark ();
    use List::Util 'uniq';
    use Package::Stash ();
    use Test2::V0 ();
    # Test->builder->output('/dev/null'); # XXX # only display fails!

    use Data::Dump; # FIXME

    field $jobs;
    field $package;
    field $stash;
    field $sut   :reader :param = [];
    field $tests         :param = [];

    method add_tests(@tests_) {
        push @$tests, @tests_;
    }

    method add_subs(@args) {
        $package = scalar caller;
        $stash   = Package::Stash->new($package);

        for my $arg (@args) {
            push @$sut, grep {
                matches($_, $arg)
            } $stash->list_all_symbols('CODE');
        }
        $sut = [ uniq sort @$sut ];
    }

    sub matches($hay, $needle) {
        # ref $needle eq 'Regexp'
        $needle isa 'Regexp'
            ? $hay =~ $needle
            : $hay eq $needle;
    }

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

    method cmpthese($count) {
        Benchmark::cmpthese $count, $jobs;
    }

    method benchmark_body($template, $arg) {
        for my $sub (@$sut) {
            my $body = $template =~ s/\%f/${package}::$sub/rg;
            $body                =~ s/\%a/\$arg/g;

            $jobs->{$sub} = eval "sub { $body }";
        }
    }
};
