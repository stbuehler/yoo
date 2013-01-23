
local _G = _G

local mime = require("mime")
local md5 = require("md5")
local des56 = require("des56")

local cachemod = require "yoo.cache"

function readAuthFile(filename)
	local users = {}
	local line
	local user, salt, pw
	for line in io.lines(filename) do
		if line:byte(1) ~= "#" then
			user, salt, pw = string.match(line, "^([^:]*):($[^$]*$)(.*)$")
			if user then
				users[user] = { salt = salt, pw = pw }
			end
		end
	end
	return users
end

local cache = cachemod.Cache.create(readAuthFile)

Auth = {}
Auth.__index = Auth

-- function putStrLn(s)
--	content = content .. s .. "\n"
-- end

function Auth.create(authfile, realm)
	if not realm then realm = "default" end
	users = cache:get(authfile)
	if not users then
		users = {}
		print("Yoo Authfile '"..authfile.."' not found")
	end
	local auth = {}
	setmetatable(auth, Auth)
	auth.realm = realm
	auth.users = users
	auth.method = "basic"
	return auth
end

function Auth:send_auth_headers()
	if self.sent_header then return end
	self.sent_header = true
	if self.method == "basic" then
		lighty.header["WWW-Authenticate"] = "Basic realm=\"" .. self.realm .. "\""
	elseif self.method == "digest" then
		lighty.header["WWW-Authenticate"] = "Digest realm=\"" .. self.realm .. "\", nonce=\"" .. self.nonce .. "\", qop=\"auth\""
	end
	setStatus(401)
end

function Auth:basic_check(s)
	local user, pass, e, pw
	if not (self.method == "basic") then
		return false
	end
	s = (mime.unb64(s))
	user, pass = string.match(s, "([^:]*):(.*)")
	if not user or not pass then return false end
	e = self.users[user]
	if not e then return false end
	pw = md5.sumhexa(pass .. e.salt)
	if pw == e.pw then
		self.user = user
		return true
	else
		return false
	end
end

function Auth:digest_check(s)
	if not (self.method == "digest") then
		return false
	end
	-- not supported for now
	return false
end

function Auth:check()
	local res = self.checked
	if res ~= nil then return res end
	res = false
	s = lighty.request["Authorization"]
	if s then
		-- putStrLn("Authorization: " .. s)
		if string.lower(string.sub(s, 1, 6)) == "basic " then
			res = self:basic_check(string.sub(s, 7))
		elseif string.lower(string.sub(s, 1, 7)) == "digest " then
			res = self:digest_check(string.sub(s, 8))
		end
	end
	self.checked = res
	return res
end

function Auth:enforce(users)
	if not self:check() then
		self:send_auth_headers()
		return false
	end
	if users and not users[self.user] then
		self:send_auth_headers()
		return false
	end
	return true
end

return Auth.create
