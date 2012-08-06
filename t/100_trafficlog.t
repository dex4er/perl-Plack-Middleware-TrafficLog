#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my @log;

my $test = sub {
    my @args = @_;
    return sub {
        my ($req) = @_;
        my $app = builder {
            enable 'Plack::Middleware::TrafficLog',
                logger => sub { push @log, "@_" }, @args;
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "OK\nOK\n" ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $req = POST 'http://example.com/', Content => "TEST\nTEST\n";
    $req->header('Host' => 'example.com', 'Content-Type' => 'text/plain');

    @log = ();
    $test->()->($req);
    is @log, 2;
    like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $};
    like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $};

    @log = ();
    $test->(with_date => 0)->($req);
    is @log, 2;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $};
    like $log[1], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $};

    @log = ();
    $test->(with_date => 0, with_request => 1, with_response => 0)->($req);
    is @log, 1;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $};

    @log = ();
    $test->(with_date => 0, with_request => 0, with_response => 1)->($req);
    is @log, 1;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $};

    @log = ();
    $test->(with_date => 0, with_body => 0)->($req);
    is @log, 2;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|$};
    like $log[1], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|$};

    @log = ();
    $test->(with_date => 0, eol => '!')->($req);
    is @log, 2;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] !POST / HTTP/1.1!Host: example.com!Content-Length: 10!Content-Type: text/plain!!TEST!TEST!$};
    like $log[1], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] !HTTP/1.0 200 OK!Content-Type: text/plain!!OK!OK!$};

    @log = ();
    $test->(with_date => 0, eol => '!', body_eol => ',')->($req);
    is @log, 2;
    like $log[0], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Request\] !POST / HTTP/1.1!Host: example.com!Content-Length: 10!Content-Type: text/plain!!TEST,TEST,$};
    like $log[1], qr{^\[\d+\] \[127.0.0.1 -> example.com:80\] \[Response\] !HTTP/1.0 200 OK!Content-Type: text/plain!!OK,OK,$};
}

done_testing;
