#!iRule
# F5 Networks - iRule: hello, world
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 30/08/2018

when HTTP_REQUEST {
	HTTP::respond 200 content " \
		hello, world\n \
		ip.src: [IP::client_addr]\n \
		tcp.srcport: [TCP::client_port]\n \
		ip.dst: [IP::local_addr]\n \
		tcp.dstport: [TCP::local_port]\n \
		big.ip: $static::tcl_platform(machine)\n"
}
