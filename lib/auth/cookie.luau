local runtime = require '@utils/runtime'

-- defs
export type session = { api_key: nil, cookie: string }

local process = require '@std/process'
local system = require '@std/system'

local function get_local_cookie()
	local env_cookie = process.env.ROBLOSECURITY or process.env.ROBLOX_COOKIE
	if env_cookie then
		return env_cookie
	end

	if system.os == "windows" then
		local res = process.run({
			"powershell",
			"-NoProfile",
			"-Command",
			"(Get-ItemProperty -Path 'HKCU:\\SOFTWARE\\Roblox\\RobloxStudioBrowser\\roblox.com' -ErrorAction SilentlyContinue).'.ROBLOSECURITY'"
		})
		if res.ok and res.stdout and #res.stdout > 0 then
			local cookie = res.stdout:gsub("%s+$", "")
			if #cookie > 0 then
				return cookie
			end
		end
	elseif system.os == "macos" then
		local res = process.run({
			"defaults",
			"read",
			"com.roblox.RobloxStudioBrowser.roblox.com",
			".ROBLOSECURITY"
		})
		if res.ok and res.stdout and #res.stdout > 0 then
			local cookie = res.stdout:gsub("%s+$", "")
			if #cookie > 0 then
				return cookie
			end
		end
	end

	error("Could not find a local roblox cookie. Please set the ROBLOSECURITY environment variable.")
end

-- functions
local function login(cookie: string?): session
	if not cookie then
		print 'no cookie provided, getting your local cookie'
		cookie = get_local_cookie()
	end
	assert(cookie, `couldnt possible login`)
	return table.freeze { cookie = cookie }
end

-- methods
local function request(
	session: session,
	method: string,
	url: string,
	query: {}?,
	body: string | buffer?,
	content_type: string? -- unknown
)
	local headers: any = { ['Content-Type'] = content_type, ['Cookie'] = session.cookie }
	local res = runtime.net.request { url = url, method = method, body = body, headers = headers }

	if res.statusCode == 403 then
		local token = res.headers['x-csrf-token'] or res.headers['X-CSRF-TOKEN']
		if type(token) == 'string' then
			headers['X-CSRF-TOKEN'] = token
			res = runtime.net.request { url = url, method = method, body = body, headers = headers }
		end
	end
	return res
end

-- module
return table.freeze { login = login, request = request }
