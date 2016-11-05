#!iRule
# F5 Networks - iRule: IP Intelligence Enforcement
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 06/11/2016

when CLIENT_ACCEPTED {
	set lst_IP_REP [IP::reputation [IP::client_addr]]
	if { [llength $lst_IP_REP] } {
		drop
		 #log local0.info "Dropped Connection from IP: [IP::client_addr] Reputation: $lst_IP_REP"
	}
}
