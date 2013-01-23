# lighttpd mod_magnet framework for rewrites/redirects and authentication

## Dependencies:
 - lua-md5 (https://github.com/keplerproject/md5): 'md5' and 'des56'
 - lua-socket (http://www.tecgraf.puc-rio.br/luasocket/): 'mime'

## Install

* Configure path in handle.lua
* lighttpd.conf:
** load mod_magnet in server.modules
** magnet.attract-physical-path-to = ( "/<some-path>/handle.lua" )

## How it works

It searches in the document root for a file ".yoo" with one action per line;
each line has the following form: `<prefix>: <action> <optional parameters>`

Example:
/secure: auth
/old: rewrite /new
/temp: redirect /somewhere/else
/deprecated: redirect 301 /somewhere/else

Now all urls starting with "/secure" will require authentication

## Actions

* auth: require authentication. Users and passwords are expected in the file ".yoo.auth", htpasswd md5 encrypted.
* rewrite: rewrites to destination (see note blow)
* not-exist: conditional rewrite - if physical file does not exist
* not-file: conditional rewrite - if not a regular file
* redirect: redirects to an absolute url on the same vhost
* exit: stop handling in yoo, continue with standard handling

## Note

rewrite doesn't work with 1.4 right now, it would need this in mod_magnet.c:

	 	} else if (MAGNET_RESTART_REQUEST == lua_return_value) {
	 		assert(lua_gettop(L) == 1); /* only the function should be on the stack */
	+		buffer_reset(con->physical.path);
	
	 		return HANDLER_COMEBACK;
