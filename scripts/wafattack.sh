#!/bin/bash
# F5 Networks - WAF Attacks
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.1, 11/06/2018

# HTTP protocol compliance failed - Host header contains IP address
curl -k "https://10.100.115.100/" -H "User-Agent: Browser"

# HTTP protocol compliance failed - POST request with Content-Length: 0
curl -k -X POST "https://asm.f5labs.one/api/" -H "User-Agent: Browser" -H "Content-Length: 0"

# Content Profiles: JSON - Illegal parameter numeric value
curl -k -X POST "https://asm.f5labs.one/api/" -H "User-Agent: Toaster" -H "Content-Type: application/json" -d '{ "id": 0, "firstName": "Tyler", "lastName": "Durden" }'

# Content Profiles: JSON - Illegal parameter value length
curl -k -X POST "https://asm.f5labs.one/api/" -H "User-Agent: Fridge" -H "Content-Type: application/json" -d '{ "id": 1, "firstName": "Narrator" }'

# Content Profiles: JSON - Attack signature
curl -k -X POST "https://asm.f5labs.one/api/" -H "User-Agent: Oven" -H "Content-Type: application/json" -d '{ "id": 1, "firstName": "Tyler", "lastName": "<script>runFunction();</script>" }'

# Proactive Bot Defense - browser_challenge
curl -k "https://asm.f5labs.one/index.php" -H "User-Agent: Teapot" -b scr_cURL_HGET.cookies -c scr_cURL_HGET.cookies -L -v

# irule_API_SPIKE_ARREST
for i in {0..7}; do curl -k "https://asm.f5labs.one/ws/rest.api?userID=1" -H "User-Agent: NotaBot" -H "Authorization: Bearer 0b79bab50daca910b000d4f1a2b675d604257e42"; echo; done
