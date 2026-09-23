local fs = require '@std/fs'
local process = require '@std/process'

local dotenv = {}
local success, content = pcall(function() return fs.readFile('.env') end)
if success and type(content) == "string" then
	for line in string.gmatch(content, "[^\r\n]+") do
		local key, val = string.match(line, "^%s*([%w_]+)%s*=%s*\"?(.-)\"?%s*$")
		if key then
			dotenv[key] = val
		end
	end
end

-- functions
local function num(key: string): number?
	return tonumber(dotenv[key] or process.env[key])
end
local function str(key: string): string
	local val = dotenv[key] or process.env[key]
	return val and tostring(val)
end

-- module
return table.freeze { uint = num, int = num, num = num, str = str }
