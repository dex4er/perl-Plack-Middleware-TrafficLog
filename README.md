# NAME

Plack::Middleware::TrafficLog - Log headers and body of HTTP traffic

# SYNOPSIS

    # In app.psgi
    use Plack::Builder;

    builder {
        enable "TrafficLog";
    };

# DESCRIPTION

This middleware logs the request and response messages with detailed
information about headers and body.

The example log:

    [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 -> 0:5000] [Request ]
    |GET / HTTP/1.1|Connection: TE, close|Host: localhost:5000|TE: deflate,gzi
    p;q=0.3|User-Agent: lwp-request/6.03 libwww-perl/6.03||
    [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 <- 0:5000] [Response]
    |HTTP/1.0 200 OK|Content-Type: text/plain||Hello World

This module works also with applications which have delayed response. In that
case each chunk is logged separately and shares the same unique ID number and
headers.

# CONFIGURATION

- logger

    # traffic.l4p
    log4perl.logger.traffic = DEBUG, LogfileTraffic
    log4perl.appender.LogfileTraffic = Log::Log4perl::Appender::File
    log4perl.appender.LogfileTraffic.filename = traffic.log
    log4perl.appender.LogfileTraffic.layout = PatternLayout
    log4perl.appender.LogfileTraffic.layout.ConversionPattern = %m{chomp}%n

    # app.psgi
    use Log::Log4perl qw(:levels get_logger);
    Log::Log4perl->init('traffic.l4p');
    my $logger = get_logger('traffic');

    enable "Plack::Middleware::TrafficLog",
        logger => sub { $logger->log($INFO, join '', @_) };

Sets a callback to print log message to. It prints to `psgi.errors` output
stream by default.

- with\_request

The false value disables logging of request message.

- with\_response

The false value disables logging of response message.

- with\_date

The false value disables logging of current date.

- with\_body

The false value disables logging of message's body.

- eol

Sets the line separator for message's headers and body. The default value is
the pipe character `|`.

- body\_eol

Sets the line separator for message's body only. The default is the space
character ` `. The default value is used only if __eol__ is also undefined.

# SEE ALSO

[Plack](http://search.cpan.org/perldoc?Plack), [Plack::Middleware::AccessLog](http://search.cpan.org/perldoc?Plack::Middleware::AccessLog).

# BUGS

This module has unstable API and it can be changed in future.

The log file can contain the binary data if the PSGI server provides binary
files.

If you find the bug or want to implement new features, please report it at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-TrafficLog](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-TrafficLog)

The code repository is available at
[http://github.com/dex4er/perl-Plack-Middleware-TrafficLog](http://github.com/dex4er/perl-Plack-Middleware-TrafficLog)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
