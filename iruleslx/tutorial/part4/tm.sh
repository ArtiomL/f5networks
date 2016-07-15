tmsh show ilx plugin ilxpi_DEMO extensions | grep Restart
tmsh show ilx plugin ilxpi_DEMO extensions | grep PID
tmsh modify sys db log.sdmd.level value debug
#tmsh modify sys db log.sdmd.level value info
tmsh modify ilx plugin ilxpi_DEMO extensions { ilxex_DEMO { concurrency-mode single command-options add { --debug } } }
tmsh show ilx plugin ilxpi_DEMO extensions | grep Debug
/usr/lib/node_modules/.bin/node-inspector --web-host 10.100.113.50 --no-inject --debug-port 1038
