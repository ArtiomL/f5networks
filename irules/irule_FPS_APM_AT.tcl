#!iRule
# F5 Networks - iRule: FPS VIP-targeting-VIP for APM App Tunnels
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 03/08/2018

when HTTP_REQUEST {
	if { [HTTP::uri] starts_with "/isession" } {
		 #log local0.info "Disabling HTTP and ANTIFRAUD."
		HTTP::disable
		ANTIFRAUD::disable
	}
	virtual virt_ACCESS_PROFILE
}
