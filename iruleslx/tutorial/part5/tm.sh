# Show all running Node.js processes
ps -ef | grep [n]odejs

# Change the current directory to the extension folder
cd /var/ilx/workspaces/Common/ilxws_DEMO/extensions/ilxex_DEMO/

# Show the current Node.js request module version
npm list request

# Check the registry to see if any installed packages are currently outdated
npm outdated

# Update the Node.js request module
npm update request --save
