#!iRule
# F5 Networks - iRule: Decrypt TLS Traffic
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 20/07/2018

when CLIENTSSL_HANDSHAKE {
	log local0.info "Client Side: RSA Session-ID:[SSL::sessionid] Master-Key:[SSL::sessionsecret]"
}


when SERVERSSL_HANDSHAKE {
	log local0.info "Server Side: RSA Session-ID:[SSL::sessionid] Master-Key:[SSL::sessionsecret]"
}

# grep Session-ID /var/log/ltm | sed 's/.*\(RSA.*\)/\1/' > /var/tmp/pmsk.txt
# Wireshark > Preferences > Protocols > SSL > (Pre)-Master-Secret log filename = pmsk.txt
