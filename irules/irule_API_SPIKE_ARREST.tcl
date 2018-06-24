#!iRule
# Limit each API Token to <static::maxreq> requests per <static::pertime> seconds (to a specific entry point)
when RULE_INIT {
	# Using static variables to set constants
	set static::maxreq 5
	set static::pertime 30
}


when HTTP_REQUEST {
	set token [getfield [HTTP::header "Authorization"] " " 2]
	if { [HTTP::uri] starts_with "/ws/rest.api" && $token ne "" } {
		# Count the current number of keys (=requests) stored in a subtable named after the API Token value
		set cureq [table keys -subtable $token -count]
		if { $cureq >= $static::maxreq } {
			set json "\{\"Request\":\"Rejected\",\"Token\":\"$token\",\"Cause\":\"Spike Arrest\"\}"
			HTTP::respond 429 content $json "Content-Type" "application/json"
		}
		# Use a subtable to store the current request count per API Token value
		# The subtable name is the API Token value, the key name is random (CPU cycle counter) to prevent overwriting existing keys
		# The key value is empty - it's not used, the keys' timeout is that period of time for which the limit is set
		table set -subtable $token [clock clicks] "" $static::pertime
		incr cureq
		# Update the inventory table (list of all active (sub)tables) - only needed if irule_TABLE_MANAGE is used
		table set -subtable st_TABNAMES $token $cureq $static::pertime
	}
}
