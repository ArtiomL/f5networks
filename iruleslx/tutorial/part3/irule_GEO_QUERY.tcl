# F5 BIG-IP iRule: GeoLocation and IP Reputation Query
# (CC0) No Rights Reserved
# Artiom Lichtenstein
# v1.5m, 07/07/2016

# Usage:
# http://IP_VIRT/geo?{IPv4_TO_TEST | IPv6_TO_TEST}

# Examples:
# http://10.100.89.100/geo?8.8.8.8
# http://10.100.89.100/geo?199.19.105.220
# http://10.100.89.100/geo?2a02:DB8::45

when HTTP_REQUEST {
	if { [HTTP::uri] starts_with "/geo" }
        {
			set str_GEO_RESPONSE "Please Enter IPv4 / IPv6 Address:"
			set str_IP_ADDR [substr [HTTP::uri] 5]
			if { !([catch {IP::addr $str_IP_ADDR mask 255.255.255.255} ]) }
			{
			log local0.info "IP: $str_IP_ADDR"
			set str_GEO_RESPONSE "<b>IP: $str_IP_ADDR<BR><BR>GeoLocation Data</b><span class=\"b\">"
			array set arr_GEO_DATA {
				aContinent 0
				bCountry 0
				cState 0
				dCity 0
				eZIP 0
				fArea_Code 0
				gLatitude 0
				hLongitude 0
				iISP 0
				jOrg 0
				}
			set lst_SORTED_ARR [lsort [array names arr_GEO_DATA]]

			foreach i $lst_SORTED_ARR {
				set str_GEO_FIELD [substr $i 1]
				set arr_GEO_DATA($i) [whereis $str_IP_ADDR [string tolower $str_GEO_FIELD]]
				if { ([string length $arr_GEO_DATA($i)]) && ($arr_GEO_DATA($i) ne "0") }
					{
						set str_GEO_RESPONSE [concat $str_GEO_RESPONSE "<BR>$str_GEO_FIELD:" [string toupper $arr_GEO_DATA($i) 0 0]]
						log local0.info "$str_GEO_FIELD: $arr_GEO_DATA($i)"
					}
				}

			set lst_IP_REP [IP::reputation $str_IP_ADDR]
			if { $str_IP_ADDR eq "10.100.100.250" } { 
				set lst_IP_REP "<span class=\"iprep\">Botnets</span>"
			}
			elseif { [llength $lst_IP_REP] == 0 } { 
				set lst_IP_REP "<span class=\"iprep\">Good</span>" 
			}
			else { 
					log local0.info "IP Reputation: $lst_IP_REP"
					set lst_IP_REP [concat "<span class=\"iprep\">" $lst_IP_REP "</span>"]
				}
			set str_GEO_RESPONSE [concat $str_GEO_RESPONSE "</span><BR><BR><b>IP Reputation:</b>" $lst_IP_REP]
			}

			HTTP::respond 200 content [subst {
				<html>
					<head>
						<title>F5 GeoLocation</title>
						<script language="JavaScript" type="text/javascript">
							function geoQuery() {
								var addrIP = document.getElementById('tboxIP');
								window.open("/geo?" + addrIP.value,"_self")
								}
						</script>
					<style type="text/css">
						body { color: #000000; font: 80% courier new; }
						.r { color: #ff0000; }
						.g { color: #008000; }
						.b { color: #0000ff; }
					</style></head>
					<body><p style="margin-left:10;"><BR>$str_GEO_RESPONSE<BR><BR>
					<input type="text" name="tboxIP" id="tboxIP" onkeydown="if (event.keyCode == 13) geoQuery();" autofocus/>
					<input type="button" value="Where?" onclick="geoQuery();" style="background-color:#00A2E8; color:white;"></p>
					</body>
				</html> }]
		}
}
