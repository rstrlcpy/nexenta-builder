#!/usr/bin/perl -w

# Copyright 2005-2011 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.

use strict;
use IO::Socket;

my $host;
if (defined $ARGV[0] && $ARGV[0] =~ m/--host=(\S+)/) {
	$host = $1;
} else {
	exit 1;
}
my $port;
if (defined $ARGV[1] && $ARGV[1] =~ m/--port=(\S+)/) {
	$port = $1;
} else {
	exit 1;
}

while (defined(my $line = <STDIN>)) {
	chomp $line;

	my $sock = IO::Socket::INET->new(PeerAddr	=> $host,
									 PeerPort	=> $port,
									 Proto		=> 'udp') || exit 1;
	$sock->send($line, 0);
}

exit;
