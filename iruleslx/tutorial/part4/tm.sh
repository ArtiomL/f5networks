# Display the number of restarts for the extension
tmsh show ilx plugin ilxpi_DEMO extensions | grep Restart

# Display the PID of the Node.js process running the extension
tmsh show ilx plugin ilxpi_DEMO extensions | grep PID

# Turn on verbose logging for SDMD and all the Node.js processes
tmsh modify sys db log.sdmd.level value debug

# Put the extension into debugging mode
tmsh modify ilx plugin ilxpi_DEMO extensions { ilxex_DEMO { concurrency-mode single command-options add { --debug } } }

# Find the debugging port assigned to the Node.js process
tmsh show ilx plugin ilxpi_DEMO extensions | grep Debug

# Start the Node Inpector for that port number
/usr/lib/node_modules/.bin/node-inspector --web-host 10.100.113.50 --no-inject --debug-port 1038
