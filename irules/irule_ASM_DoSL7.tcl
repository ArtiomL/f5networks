#!iRule
# F5 Networks - iRule: ASM L7 DoS
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 02/06/2017

when HTTP_REQUEST {
	if { [HTTP::header exists "Content-Encoding"] } {
		DECOMPRESS::enable
	}
}


when ASM_REQUEST_DONE {
	HTTP::header insert "X-Device-ID" "[ASM::fingerprint]"
}


when IN_DOSL7_ATTACK {
	 #log local0.warning "Attacker IP: $DOSL7_ATTACKER_IP, Mitigation: $DOSL7_MITIGATION"
	if { $DOSL7_MITIGATION contains "Rate Limiting" } {
		HTTP::respond 403 content [ifile get ifile_HONEYPOT]
		 #log local0.warning "Honeypot!"
	}
}


when BOTDEFENSE_ACTION {
	 #log local0.info "PBD Action: [BOTDEFENSE::action], Reason: [BOTDEFENSE::reason]"
}
