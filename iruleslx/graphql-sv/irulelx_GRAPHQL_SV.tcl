#!iRule LX
# F5 Networks - Node.js: GraphQL Schema Validation
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.1, 18/10/2017

when HTTP_REQUEST {
	if { [HTTP::method] eq "POST" } {
		set clength [HTTP::header "Content-Length"]
		# Trigger collection for up to 1MB of data
		if { $clength eq "" || $clength > 1048576 } {
			set clength 1048576
		}
		HTTP::collect $clength
	}
}


when HTTP_REQUEST_DATA {
	set pload [HTTP::payload]
	 #log local0.info "HTTP Payload: $pload"
	set rpc_handle [ILX::init ilxpi_GRAPHQL_SV ilxex_GRAPHQL_SV]
	 #log local0.info "RPC Handle: $rpc_handle"
	if { [catch {set rpc_resp [ILX::call $rpc_handle -timeout 3000 ilxmet_GRAPHQL_SV $pload]} cresult] } {
		reject
		 #log local0.err "ILX to Node.js RPC Issue: $cresult"
	}
	 #log local0.info "RPC Response: $rpc_resp"
	if { [lindex $rpc_resp 0] == 0 } {
		HTTP::respond 200 content [lindex $rpc_resp 1] noserver
	}
	else {
		reject
		 #log local0.err "Connection rejected!"
	}
}
