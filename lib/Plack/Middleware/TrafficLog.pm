package Plack::Middleware::TrafficLog;

=head1 NAME

Plack::Middleware::TrafficLog - Log request and response messages

=head1 SYNOPSIS

  # In app.psgi
  use Plack::Builder;

  builder {
      enable "TrafficLog";
  };

=head1 DESCRIPTION

This middleware logs the request and response messages with detailed
informations.

=for readme stop

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';


use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( with_request with_response with_date with_body eol body_eol logger );

use Plack::Request;
use Plack::Response;

use POSIX ();
use Scalar::Util ();


sub prepare_app {
    my ($self) = @_;

    # the default values
    $self->with_request(1)  unless defined $self->with_request;
    $self->with_response(1) unless defined $self->with_response;
    $self->with_date(1)     unless defined $self->with_date;
    $self->with_body(1)     unless defined $self->with_body;
    $self->body_eol(defined $self->eol ? $self->eol : ' ') unless defined $self->body_eol;
    $self->eol('|')         unless defined $self->eol;
};


sub _strftime {
    my ($self, @args) = @_;
    my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
    POSIX::setlocale(&POSIX::LC_ALL, 'C');
    my $out = POSIX::strftime(@args);
    POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    return $out;
};


sub _log_message {
    my ($self, $type, $env, $status, $headers, $body) = @_;

    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    my $server_addr = sprintf '%s:%s', $env->{SERVER_NAME}, $env->{SERVER_PORT};

    my $eol = $self->eol;
    my $body_eol = $self->body_eol;
    $body =~ s/\n/$body_eol/gs;

    my $date = $self->with_date
        ? ('['. $self->_strftime('%d/%b/%Y:%H:%M:%S %z', localtime) . '] ')
        : '';

    $logger->( sprintf
        "%s[%s] [%s -> %s] [%s] %s%s%s%s%s%s\n",

        $date,
        Scalar::Util::refaddr $env->{'psgi.input'} || '?',

        $env->{REMOTE_ADDR}, $server_addr,

        $type,

        $eol,
        $status,
        $eol,
        $headers->as_string($eol),
        $eol,
        $body,
    );
};


sub _log_request {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);

    my $status = sprintf '%s %s %s', $req->method, $req->request_uri, $req->protocol,
    my $headers = $req->headers;
    my $body = $self->with_body ? $req->content : '';

    $self->_log_message('Request', $env, $status, $headers, $body);
};


sub _log_response {
    my ($self, $env, $ret, $logger) = @_;

    my $res = Plack::Response->new(@$ret);

    my $status = sprintf 'HTTP/1.0 %s %s',
        $res->status,
        HTTP::Status::status_message($res->status);
    my $headers = $res->headers;
    my $body = $self->with_body ? (join '', @{$res->body}) : '';

    $self->_log_message('Response', $env, $status, $headers, $body);
};


sub call {
    my ($self, $env) = @_;

    # Preprocessing
    $self->_log_request($env) if $self->with_request;

    # $self->app is the original app
    my $ret = $self->app->($env);

    # Postprocessing
    $self->_log_response($env, $ret) if $self->with_response;

    return $ret;
}


1;


=head1 CONFIGURATION

=over 4

=item logger

  # traffic.l4p
  log4perl.logger.traffic = DEBUG, LogfileTraffic
  log4perl.appender.LogfileTraffic = Log::Log4perl::Appender::File
  log4perl.appender.LogfileTraffic.filename = traffic.log
  log4perl.appender.LogfileTraffic.layout = PatternLayout
  log4perl.appender.LogfileTraffic.layout.ConversionPattern = %m{chomp}%n

  # log4perl.psgi
  use Log::Log4perl qw(:levels get_logger);
  Log::Log4perl->init('traffic.l4p');
  my $logger = get_logger('traffic');

  enable "Plack::Middleware::TrafficLog",
      logger => sub { $logger->log($INFO, join '', @_) };

Sets a callback to print log message to. It prints to C<psgi.errors>
output stream by default.

=item with_request

The false value disables logging of request message.

=item with_response

The false value disables logging of response message.

=item with_date

The false value disables logging of current date.

=item with_body

The false value disables logging of message's body.

=item eol

Sets the line separator for message's headers and body. The default
value is the pipe character C<|>.

=item body_eol

Sets the line separator for message's body only. The default is the
space character C< >. The default value is used only if B<eol> is also
undefined.

=back

=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware::AccessLog>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-TrafficLog>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-Middleware-TrafficLog>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
