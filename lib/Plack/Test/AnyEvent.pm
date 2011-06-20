## no critic (RequireUseStrict)
package Plack::Test::AnyEvent;
BEGIN {
  $Plack::Test::AnyEvent::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;
use autodie qw(pipe);

use AnyEvent::Handle;
use Carp;
use HTTP::Request;
use HTTP::Message::PSGI;
use IO::Handle;
use Try::Tiny;

use Plack::Test::AnyEvent::Response;

# code adapted from Plack::Test::MockHTTP
sub test_psgi {
    my ( %args ) = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";

    my $cb     = sub {
        my ( $req ) = @_;
        $req->uri->scheme('http')    unless defined $req->uri->scheme;
        $req->uri->host('localhost') unless defined $req->uri->host;
        my $env = $req->to_psgi;
        $env->{'psgi.streaming'}   = 1;
        $env->{'psgi.nonblocking'} = 1;

        my $res = try {
            $app->($env);
        } catch {
            Plack::Test::AnyEvent::Response->from_psgi([ 500, [ 'Content-Type' => 'text/plain' ], [ $_ ] ]);
        };

        if(ref($res) eq 'CODE') {
            my ( $status, $headers, $body );
            my ( $read, $write );

            my $cond = AnyEvent->condvar;

            $res->(sub {
                my ( $ref ) = @_;
                ( $status, $headers, $body ) = @$ref;

                $cond->send;

                unless(defined $body) {
                    pipe $read, $write;
                    $write = IO::Handle->new_from_fd($write, 'w');
                    $write->autoflush(1);
                    return $write;
                }
            });

            unless(defined $status) {
                $cond->recv;
            }

            if(defined $body) {
                $res = Plack::Test::AnyEvent::Response->from_psgi([ $status, $headers, $body ]);
            } else {
                push @$headers, 'Transfer-Encoding', 'chunked';
                $res = Plack::Test::AnyEvent::Response->from_psgi([ $status, $headers, [] ]);
                $res->on_content_received(sub {});
                my $h;
                $res->{'_cond'} = AnyEvent->condvar(cb => sub {
                    undef $h;
                    close $read;
                    close $write;
                });

                $h = AnyEvent::Handle->new(
                    fh      => $read,
                    on_read => sub {
                        my $buf = $h->rbuf;
                        $h->rbuf = '';
                        $res->content($res->content . $buf);
                        $res->on_content_received->($buf);
                    },
                    on_eof => sub {
                        $res->send;
                    },
                    on_error => sub {
                        my ( undef, undef, $msg ) = @_;
                        warn $msg;
                        $res->send;
                    },
                );
            }
        } else {
            $res = Plack::Test::AnyEvent::Response->from_psgi($res);
            $res->request($req);
        }

        return $res;
    };

    $client->($cb);
}

1;



=pod

=head1 NAME

Plack::Test::AnyEvent - Run Plack::Test on AnyEvent-based PSGI applications

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use Plack::Test;

  $Plack::Test::Impl = 'AnyEvent'; # or 'AE' for short

  test_psgi $app, sub {
    my ( $cb ) = @_;

    my $res = $cb->(GET '/streaming-response');
    is $res->header('Transfer-Encoding'), 'chunked';
    $res->on_content_received(sub {
        my ( $content ) = @_;

        # test chunk of streaming response
    });
    $res->recv;
  }

=head1 DESCRIPTION

This L<Plack::Test> implementation allows you to easily test your
L<AnyEvent>-based PSGI applications.  Normally, L<Plack::Test::MockHTTP>
or L<Plack::Test::Server> work fine for this, but this implementation comes
in handy when you'd like to test your streaming results as they come in, or
if your application uses long-polling.  For non-streaming requests, you can
use this module exactly like Plack::Test::MockHTTP; otherwise, you can set
up a content handler and call C<$res-E<gt>recv>.  The event loop will then
run until the PSGI application closes its writer handle or until your test
client calls C<send> on the response.

=head1 FUNCTIONS

=head2 test_psgi

This function behaves almost identically to L<Plack::Test/test_psgi>; the
main difference is that the returned response object supports a few additional
methods on top of those normally found in an L<HTTP::Response> object:

=head3 $res->recv

Calls C<recv> on an internal AnyEvent condition variable.  Use this after you
get the response object to run the event loop.

=head3 $res->send

Calls C<send> on an internal AnyEvent condition variable.  Use this to stop
the event loop when you're done testing.

=head3 $res->on_content_received($cb)

Sets a callback to be called when a chunk is received from the application.
A single argument is passed to the callback; namely, the chunk itself.

=head1 SEE ALSO

L<AnyEvent>, L<Plack>, L<Plack::Test>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://github.com/hoelzro/plack-test-anyevent/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Run Plack::Test on AnyEvent-based PSGI applications

