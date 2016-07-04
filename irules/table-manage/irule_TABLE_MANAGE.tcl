#!iRule
# F5 BIG-IP iRule: Show, Export and Delete Session Tables
# (CC0) No Rights Reserved
# Artiom Lichtenstein
# v1.5, 05/12/2014
#
# Usage:
# http|s://<VS_IP>/tables?
#
# Notes:
# To display the list of all active tables on the main page, any iRule using the (sub)table memory structure
# needs to update an additional subtable, which essentially is a list of all currently active tables
# Example: table set -subtable st_TABNAMES <ACTIVE_TABLE_NAME> <CURRENT_KEY_COUNT> <HIGHEST_TIMEOUT>
#
# The name of this inventory subtable is stored in the static::invtab variable
# It has the following structure:
# Key Name = Active Table Name, Key Value = That Active Table's Current Key Count, Timeout = That Table's Max Timeout
#
# The referenced style.css file can be downloaded here: https://gist.github.com/ArtiomL/e40f76235e024038b129
# You can host it on the pool member, or create an additional HTTP_REQUEST condition, and serve it using the ifile command
# .tabCounters is the only selector you'll need
#

when RULE_INIT {
	#Using static variables to set constants
	#The name of the inventory subtable:
    set static::invtab "st_TABNAMES"
	#Base URI to access the functions of this iRule
	set static::baseuri "/tables"
}


when HTTP_REQUEST {
  switch -glob -- [string tolower [HTTP::uri]] \
	"$static::baseuri?" {
# ----- MAIN PAGE -----
	  set curtabs "<table border='1' class='tabCounters'><tr><td>Table</td><td>Keys</td><td>Export</td><td>Delete</td></tr>"
	  #Parse the inventory subtable to display the list of all active tables and their key count
	  foreach key [table keys -notouch -subtable $static::invtab ] {
			set val [table lookup -notouch -subtable $static::invtab $key]
			append curtabs "<tr><td><a href='$static::baseuri?ct=html&$key'>$key</a></td><td>$val</td><td> \
			<a href='$static::baseuri?ct=csv&$key'>CSV</a></td><td><a href='$static::baseuri?a=tdel&$key' style='text-decoration:none;'> \
			<center>X</center></a></td></tr>"
		}
      HTTP::respond 200 content [subst {		
		<html>
			<head>
				<title>F5 Tables</title>
				<link rel="stylesheet" href="style.css" type="text/css"/>
				<script language="JavaScript" type="text/javascript">
				function getTable(cmd) {
					var strTNAME = document.getElementById('tboxTNAME');
					if (strTNAME.value) { window.open("$static::baseuri?ct=" + cmd + "&" + strTNAME.value,"_self"); }
				}
				</script>
			</head>
			<body><p style="margin-left:10;"><br>Please Enter the Table Name:<br><br>
				  <input type="text" name="tboxTNAME" id="tboxTNAME" onkeydown="if (event.keyCode == 13) getTable('html');" autofocus/>
				  <input type="button" value="Show" onclick="getTable('html');" style="background-color:#00A2E8; color:white;">  
				  <input type="button" value="Get CSV" onclick="getTable('csv');" style="background-color:#00A2E8; color:white;">
				  <input type="button" value="Refresh" onclick="location.reload(true);" style="background-color:#00A2E8; color:white;">
				  <br><br>$curtabs</table>
				  </p>
			</body>
		</html>
	  }] "Cache-Control" "no-cache, no-store, must-revalidate, max-age=0"
    } \
	"$static::baseuri?ct=html&*" {
# ----- SHOW TABLE -----
		set tname [getfield [HTTP::uri] "&" 2]
		set html "<table border='1' class='tabCounters'><tr><td>Num.</td><td>Key Name</td><td>Key Value</td><td>Timeout</td> \
		<td>Lifetime</td><td>Delete</td></tr>"
		set num 1
		foreach key [table keys -notouch -subtable $tname ] {
			set val [table lookup -notouch -subtable $tname $key]
			set ttl [table timeout -remaining -subtable $tname $key]
			set life [table lifetime -remaining -subtable $tname $key]
			append html "<tr><td>$num</td><td>$key</td><td>$val</td><td>$ttl</td><td>$life</td><td> \
			<a href='$static::baseuri?a=kdel&$tname&$key' style='text-decoration:none;'><center>X</center></a></td></tr>"
			incr num
		}
		HTTP::respond 200 content [subst {		
		<html>
			<head>
				<title>Show Table $tname</title>
				<link rel="stylesheet" href="style.css" type="text/css"/>
			</head>
			<body><p style="margin-left:10;"><br>
			<input type="button" value="< Back" onclick="window.open('$static::baseuri?','_self');" style="background-color:#00A2E8; \
			color:white;">
			<input type="button" value="Refresh" onclick="location.reload(true);" style="background-color:#00A2E8; color:white;">
			<br><br>Table: $tname<br><br>$html</table></p></body>
		</html>
	  }] "Cache-Control" "no-cache, no-store, must-revalidate, max-age=0"
	} \
    "$static::baseuri?ct=csv&*" {
# ----- EXPORT TABLE -----
		set tname [getfield [HTTP::uri] "&" 2]
		set csv "Num.,Table Name,Key Name,Key Value,Timeout,Lifetime\n"
		set num 1
		foreach key [table keys -notouch -subtable $tname ] {
			set val [table lookup -notouch -subtable $tname $key]
			set ttl [table timeout -remaining -subtable $tname $key]
			set life [table lifetime -remaining -subtable $tname $key]
			append csv "$num,$tname,$key,$val,$ttl,$life\n"
			incr num
		}
      set fname [clock format [clock seconds] -format "%Y.%m.%d_%H.%M.%S"]_$tname.csv
	  HTTP::respond 200 content $csv "Content-Type" "text/csv" "Content-Disposition" "attachment; filename=$fname"
	} \
	"$static::baseuri?a=tdel&*" {
# ----- DELETE TABLE -----
		set tname [getfield [HTTP::uri] "&" 2]
		table delete -subtable $tname -all
		table delete -subtable $static::invtab $tname
		HTTP::respond 302 Location "$static::baseuri?"
	} \
	"$static::baseuri?a=kdel&*" {
# ----- DELETE KEY -----
		set tname [getfield [HTTP::uri] "&" 2]
		set key [getfield [HTTP::uri] "&" 3]
		table delete -subtable $tname $key
		table incr -notouch -subtable $static::invtab -mustexist $tname -1
		HTTP::respond 302 Location "$static::baseuri?ct=html&$tname"
	} \
	"/style.css" {
# ----- CSS -----
		HTTP::respond 200 content [ifile get ifile_STYLE_CSS]
	}
}
