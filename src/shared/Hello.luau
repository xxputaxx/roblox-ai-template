--!strict
-- Shared module
-- このモジュールは ReplicatedStorage 配下に配置され、Client/Server両方からrequire可能

local Hello = {}

function Hello.greet(name: string): string
	return "Hello, " .. name .. "!"
end

return Hello
