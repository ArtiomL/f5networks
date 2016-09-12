#!iRule LX
# F5 Networks - Node.js: Google Authenticator OTP over RADIUS
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.5, 12/09/2016

when CLIENT_DATA {
	binary scan [UDP::payload] H* hpload
	set rpc_handle [ILX::init ilxpi_GRADIUS ilxex_GRADIUS]
	 #log local0.info "RPC Handle: $rpc_handle"
	UDP::drop
	if { [catch {set rpc_resp [ILX::call $rpc_handle -timeout 3000 ilxmet_GRADIUS $hpload]} cresult] } {
		 #log local0.err "ILX to Node.js RPC Issue: $cresult"
		return
	}
	 #log local0.info "RPC Response: $rpc_resp"
	if { [lindex $rpc_resp 0] == 0 } {
		 #log local0.info "Sending RADIUS Response."
		UDP::respond [binary format H* [lindex $rpc_resp 1]]
	}
}
