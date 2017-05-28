#!iRule LX
# F5 Networks - Node.js: WebSocket JSON Schema Validation
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.0, 27/05/2017

when WS_CLIENT_FRAME {
	WS::collect frame
}


when WS_CLIENT_DATA {
	set wsdata [WS::payload]
	 #log local0.info "WS Frame Payload: $wsdata"
	set rpc_handle [ILX::init ilxpi_WS_JSON_SV ilxex_WS_JSON_SV]
	 #log local0.info "RPC Handle: $rpc_handle"
	if { [catch {set rpc_resp [ILX::call $rpc_handle -timeout 3000 ilxmet_WS_JSON_SV $wsdata]} cresult] } {
		 #log local0.err "ILX to Node.js RPC Issue: $cresult"
		reject
	}
	 #log local0.info "RPC Response: $rpc_resp"
	if { [lindex $rpc_resp 0] == 0 } {
		WS::release
	}
	else {
		reject
	}
}