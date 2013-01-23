
local G_ = G_

local function readfile(path)
	local content = ""
	local line
	for line in io.lines(path) do
		content = content .. line .. "\n"
	end
	return content
end

Cache = {}
Cache.__index = Cache

function Cache.create(loadfunc)
	local cache = {}
	setmetatable(cache, Cache)
	cache.loadfunc = loadfunc
	cache.data = {}
	return cache
end

function Cache:reload(file, time, stat)
	if not stat then
		stat = lighty.stat(file)
	end
	if not stat then
		-- file not found
		return nil
	end
	local data = self.loadfunc(file)
	if not data then
		-- no data, remove entry
		self.data[file] = nil
		return nil
	end
-- 	print("Reload '" .. file .. "' into cache (" .. time .. " => " .. stat.st_mtime .. ")")
	local e = { time = stat.st_mtime, data = data, cachetime = time }
	self.data[file] = e
	return data
end

function Cache:get(file)
	local e = self.data[file]
	local time = os.time()
	if not e then
		return self:reload(file, time)
	end
	-- only look in 5 min intervals
	if e.cachetime + 300 > time then
		return e.data
	end
	local stat = lighty.stat(file)
	if not stat then
		-- remove entry
		self.data[file] = nil
	end
	if e.time < stat.st_mtime then
		-- update entry
		return self:reload(file, time, stat)
	else
		e.cachetime = time
	end
	return e.data
end

filecache = Cache.create(readfile)

return _G
