# Show, Export and Delete Session Tables

## Usage
http|s://VS_IP/tables?

## Notes
To display the list of all active tables on the main page, any iRule using the (sub)table memory structure needs to update an additional subtable, which essentially is a list of all currently active tables.

Example: table set -subtable st\_TABNAMES \<ACTIVE\_TABLE\_NAME\> \<CURRENT\_KEY\_COUNT\> \<HIGHEST\_TIMEOUT\>

 The name of this inventory subtable is stored in the static::invtab variable
 It has the following structure:
 Key Name = Active Table Name, Key Value = That Active Table's Current Key Count, Timeout = That Table's Max Timeout

 The referenced style.css file can be downloaded here: https://gist.github.com/ArtiomL/e40f76235e024038b129
 You can host it on the pool member, or create an additional HTTP_REQUEST condition, and serve it using the ifile command
 .tabCounters is the only selector you'll need

