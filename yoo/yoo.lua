
local _G = _G

local cachemod = require "yoo.cache"
local Auth = require "yoo.auth"
local yooCache

local function handle_auth(yoo)
	local auth = yoo:getAuth()
	return auth:enforce()
end

local function handle_rewrite(dest)
	return function(yoo)
		rewrite(dest)
		return false
	end
end

local function handle_notexist(dest)
	return function(yoo)
		local st = lighty.stat(lighty.env["physical.path"])
		if st then return true end
		rewrite(dest)
		return false
	end
end

local function handle_notfile(dest)
	return function(yoo)
		local st = lighty.stat(lighty.env["physical.path"])
		if st and st.is_file then return true end
		rewrite(dest)
		return false
	end
end

local function handle_exit(yoo)
	return false
end

local function parseAction(method, params)
	if method == "auth" then
		return handle_auth
	elseif method == "rewrite" then
		return handle_rewrite(params)
	elseif method == "not-exist" then
		return handle_notexist(params)
	elseif method == "not-file" then
		return handle_notfile(params)
	elseif method == "exit" then
		return handle_exit
	end
	print("Unsupported action '"..method.."' ('"..params.."')")
	return nil
end

local function readYoo(filename)
	local actions = {}
	local line
	local prefix, method, params
	for line in io.lines(filename) do
		if line:byte(1) ~= "#" then
			prefix, method, params = string.match(line, "^([^:]*): ?([%w-]*)[^%w]*(.*)$")
			if prefix and method then
				local handler = parseAction(method, params)
				if handler then
					table.insert(actions, { prefix = prefix, handler = handler } )
				end
			end
		end
	end
	return actions
end

local Yoo = {}
Yoo.__index = Yoo

function Yoo.create()
	local docroot = lighty.env["physical.doc-root"]
	if not docroot then return nil end
	local actions = yooCache:get(docroot .. ".yoo")
	if not actions then return nil end
	
	local yoo = {}
	setmetatable(yoo, Yoo)
	yoo.docroot = docroot
	yoo.actions = actions
	return yoo
end

function Yoo:getAuth()
	local x = self.auth
	if x then return x end
	x = Auth(self.docroot .. ".yoo.auth", lighty.env["physical.doc-root"])
	self.auth = x
	return x
end

function Yoo:handle()
	local url = lighty.env["uri.path"]
	for _, action in pairs(self.actions) do
		if url:sub(1, action.prefix:len()) == action.prefix then
			if not action.handler(self) then
				break
			end
		end
	end
	
-- 	print("Deliver file '"..lighty.env["physical.path"].."'")
-- 	putStrLn("Done.")
-- 	sendContent()
end

yooCache = cachemod.Cache.create(readYoo)

return Yoo.create
