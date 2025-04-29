--!optimize 2

local json = {}
json.http = game:GetService("HttpService")



function json.decode(Json:string)
	local InType:string? = type(Json)
	assert(json.http,`HttpService Error. Couldn't get HttpService.`)
	assert(Json and InType == "string", `Expected a string for decoding instead got {InType}`)
	InType = nil
	return json.http:JSONDecode(Json)
end

function json.encode(str:{})
	local InType:string? = type(str)
	assert(json.http,`HttpService Error. Couldn't get HttpService.`)
	assert(str and InType == "table",`Expected a table for encoding instead got {InType}`)
	InType = nil
	return json.http:JSONEncode(str)
end

function json.getID()
	return json.http:GenerateGUID(false)
end

return json	
