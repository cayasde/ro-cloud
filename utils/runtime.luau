-- TODO

local crypto = require '@lute/crypto'
local json = require '@std/json'
local net = require '@lute/net'

-- defs
type params = {
	url: string,
	method: string,
	query: { [string]: any }?,
	headers: { [string]: any }?,
	body: string?,
}
export type response = {
	ok: boolean,
	body: string,
	statusCode: number,
	statusMessage: string,
	headers: { [string]: any },
}

-- functions
local function encode_url(input: string): string
	input = string.gsub(input, "\n", "\r\n")
	input = string.gsub(input, "([^%w %-%_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	input = string.gsub(input, " ", "%%20")
	return input
end

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function encode_base64(input: buffer): string
	local s = buffer.tostring(input)
	local result = {}
	local len = #s
	for i = 1, len, 3 do
		local a, b_byte, c = string.byte(s, i, i + 2)
		b_byte = b_byte or 0
		c = c or 0
		
		local v = bit32.lshift(a, 16) + bit32.lshift(b_byte, 8) + c
		table.insert(result, string.sub(B64_CHARS, bit32.rshift(v, 18) + 1, bit32.rshift(v, 18) + 1))
		table.insert(result, string.sub(B64_CHARS, bit32.band(bit32.rshift(v, 12), 63) + 1, bit32.band(bit32.rshift(v, 12), 63) + 1))
		table.insert(result, i + 1 > len and "=" or string.sub(B64_CHARS, bit32.band(bit32.rshift(v, 6), 63) + 1, bit32.band(bit32.rshift(v, 6), 63) + 1))
		table.insert(result, i + 2 > len and "=" or string.sub(B64_CHARS, bit32.band(v, 63) + 1, bit32.band(v, 63) + 1))
	end
	return table.concat(result)
end

local function request(params: params): response
	local url = params.url
	
	-- Assemble query params if present
	if params.query then
		local query_parts = {}
		for k, v in params.query do
			table.insert(query_parts, encode_url(tostring(k)) .. "=" .. encode_url(tostring(v)))
		end
		if #query_parts > 0 then
			url = url .. (string.find(url, "?") and "&" or "?") .. table.concat(query_parts, "&")
		end
	end

	local res = net.client.request(url, params)
	return {
		ok = res.ok,
		body = res.body,
		headers = res.headers,
		statusCode = res.status,
		statusMessage = tostring(res.status),
	}
end

-- module
return table.freeze {
	sha256 = crypto.hash.sha256,
	base64 = table.freeze { encode = encode_base64 },
	net = table.freeze { request = request, encode = encode_url },
	json = table.freeze { encode = json.serialize, decode = json.deserialize },
}
