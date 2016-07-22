#!iRule
when CLIENT_ACCEPTED {
	set rpc_handle [ILX::init ilxpi_DEMO ilxex_DEMO]
	 log local0.info "RPC Handle: $rpc_handle"
	if { [catch { set rpc_resp [ILX::call $rpc_handle -timeout 3000 ilxmet_IPREP [IP::client_addr]] } cresult ] } {
		 log local0.err "ILX to Node.js RPC Issue: $cresult"
		return
	}
	 log local0.info "RPC Message: [lindex $rpc_resp 1]"
	if { [lindex $rpc_resp 0] != 0 } {
		reject
	}
}
