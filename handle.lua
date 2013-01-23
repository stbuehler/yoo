
-- configure package search path
-- if this file is <dir>/handle.lua append ";<dir>/?.lua" to the package path
package.path = package.path .. ";/srv/yoo/?.lua"

-- how long to cache files before checking stat() again (in seconds)
_G.cache_timeout = 10

-- no changes needed below this line

local content = ""
local status = nil

_G.lighty = lighty
_G.print = print

function _G.setStatus(val)
	status = val
end

function _G.putStrLn(s)
	if content then
		content = content .. s .. "\n"
	else
		print (s.."\n")
	end
end

function _G.sendContent(mime)
	if not mime then mime = "text/plain" end
	lighty.header["Content-Type"] = mime
	lighty.content = { content }
	if not status then status = 200 end
end

function _G.rewrite(url)
	local uriquery = lighty.env["uri.query"] or ""
	if uriquery ~= "" then uriquery = "?" .. uriquery end
	lighty.env["request.uri"] = url .. uriquery
	setStatus(lighty.RESTART_REQUEST)
-- 	lighty.env["request.orig-uri"]  = lighty.env["request.uri"]
-- 	lighty.env["uri.path"] = url
-- 	lighty.env["uri.query"] = ""
-- 	lighty.env["physical.rel-path"] = lighty.env["uri.path"]
-- 	lighty.env["physical.path"]     = lighty.env["physical.doc-root"] .. lighty.env["physical.rel-path"]
end

local Yoo = require("yoo.yoo")

yoo = Yoo()
if yoo then yoo:handle() end

return status
