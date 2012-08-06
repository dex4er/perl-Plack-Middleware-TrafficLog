#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my @log;

my $test = sub {
    my @args = @_;
    return sub {
        my $req = shift;
        my $app = builder {
            enable "Plack::Middleware::TrafficLog",
                logger => sub { push @log, "@_" }, @args;
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $req = GET "http://example.com/";
    $req->header("Host" => "example.com", "X-Forwarded-For" => "192.0.2.1");

    @log = ();
    $test->()->($req);
    like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[\S+ -> \S+\] \[Request\] GET / HTTP/1.1\|Host: example.com\|Content-Length: 0\|X-Forwarded-For: 192.0.2.1\|\|$};
    like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[\S+ -> \S+\] \[Response\] HTTP/1.0 200 OK\|Content-Type: text/plain\|\|$};
}

done_testing;
