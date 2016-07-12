# Show, Export and Delete Session Tables

## Usage
http|s://VS_IP/tables?

## Active Tables Subtable
To display the list of all active tables on the main page, any iRule using the (sub)table memory structure needs to update an additional subtable, which essentially is a list of all currently active tables.

Example:
```
table set -subtable st_TABNAMES <ACTIVE_TABLE_NAME> <CURRENT_KEY_COUNT> <HIGHEST_TIMEOUT>
```

The name of this inventory subtable is stored in the **_static::invtab_** variable.

It has the following structure:

```
Key Name = Active Table Name
Key Value = That Active Table's Current Key Count
Timeout = That Table's Max Timeout
```

## CSS
The referenced style.css file can be downloaded here:

https://github.com/ArtiomL/adct/blob/master/style.css

You can host it on the pool member, or create an additional HTTP_REQUEST condition, and serve it using the ifile command.

**_.tabCounters_** is the only selector you'll need.

